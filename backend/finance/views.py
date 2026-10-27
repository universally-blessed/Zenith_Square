import uuid
from datetime import datetime, date,timedelta
from decimal import Decimal
import calendar
from django.db import transaction
from django.db.models import Sum, Count,Q
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from core_api.models import Resident, Occupancy, Flats
from .models import MaintenanceBill, Payment, PaymentReceipt, SocietyExpenses,SocietyIncome
from facilities.models import AssetMaintenance, AmenityBooking
from security.models import VisitorLogs, SecurityAlerts
from community.models import Tenant, PollsResponse
from helpdesk.models import Complaint
from .serializers import (
    MaintenanceBillSerializer, 
    PaymentReceiptSerializer, 
    SocietyExpensesSerializer,
    SocietyIncomeSerializer
)


# 1. Latest / Pending Maintenance Bill for Logged-In Resident
class ResidentPendingBillView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        resident = Resident.objects.filter(user=request.user).first()
        if not resident or not resident.flat:
            return Response({'success': False, 'error': 'Resident flat mapping missing.'}, status=status.HTTP_404_NOT_FOUND)

        bill = MaintenanceBill.objects.filter(flat=resident.flat, status__iexact='pending').order_by('due_date').first()
        if not bill:
            return Response({'success': True, 'has_pending_bill': False, 'message': 'All maintenance dues are settled!'}, status=status.HTTP_200_OK)

        return Response({
            'success': True,
            'has_pending_bill': True,
            'bill': MaintenanceBillSerializer(bill).data
        }, status=status.HTTP_200_OK)


# 2. Settle Bill & Generate Payment Receipt
class SettleMaintenancePaymentView(APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        bill_id = request.data.get('bill_id')
        payment_method = request.data.get('payment_method', 'ONLINE')

        if not bill_id:
            return Response({'success': False, 'error': 'bill_id parameter required.'}, status=status.HTTP_400_BAD_REQUEST)

        resident = Resident.objects.filter(user=request.user).first()
        if not resident:
            return Response({'success': False, 'error': 'Resident record not found.'}, status=status.HTTP_404_NOT_FOUND)

        bill = MaintenanceBill.objects.select_for_update().filter(bill_id=bill_id, status='pending').first()
        if not bill:
            return Response({'success': False, 'error': 'Bill not found or already paid.'}, status=status.HTTP_404_NOT_FOUND)

        # Compute dynamic final amount including late fee
        society = bill.flat.block.society if (bill.flat and bill.flat.block) else None
        final_amount = bill.payable_amount
        if bill.due_date < datetime.date.today() and society and society.late_fee_percent:
            late_fee = round((bill.payable_amount * Decimal(str(society.late_fee_percent))) / Decimal('100'), 2)
            final_amount += late_fee

        # 1. Update Bill
        bill.status = 'paid'
        bill.payer = request.user
        bill.save()

        # 2. Record Payment with calculated amount
        payment_id = str(uuid.uuid4())[:5].upper()
        payment = Payment.objects.create(
            payment_id=payment_id,
            resident=resident,
            bill=bill,
            payment_type='MAINTENANCE',
            amount=final_amount,
            payment_method=payment_method,
            status='completed',
            payment_date=timezone.now()
        )

        # 3. Create Receipt
        receipt_id = str(uuid.uuid4())[:6].upper()
        receipt_no = f"REC-{datetime.now().strftime('%Y%m')}-{payment_id}"
        receipt = PaymentReceipt.objects.create(
            receipt_id=receipt_id,
            payment=payment,
            receipt_number=receipt_no,
            generated_at=timezone.now()
        )

        return Response({
            'success': True,
            'message': 'Payment successful! Receipt generated.',
            'receipt': PaymentReceiptSerializer(receipt).data
        }, status=status.HTTP_201_CREATED)


# 3. Generate Monthly Bills for All Flats
class GenerateMaintenanceBillsView(APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin', 'treasurer']:
            return Response({'success': False, 'error': 'Unauthorized. Chairman/Treasurer privilege required.'}, status=status.HTTP_403_FORBIDDEN)

        society = request.user.society
        if not society:
            return Response({'success': False, 'error': 'Society profile missing.'}, status=status.HTTP_404_NOT_FOUND)

        bill_month = request.data.get('bill_month', datetime.now().strftime('%B %Y'))
        due_date_str = request.data.get('due_date')
        
        if due_date_str:
            due_date = datetime.strptime(due_date_str, '%Y-%m-%d').date()
        else:
            today = date.today()
            due_date = (today.replace(day=1) + timedelta(days=32)).replace(day=10)

        flats = Flats.objects.filter(block__society=society)
        created_count = 0

        for flat in flats:
            if not MaintenanceBill.objects.filter(flat=flat, bill_month=bill_month).exists():
                MaintenanceBill.objects.create(
                    bill_id=str(uuid.uuid4())[:6].upper(),
                    flat=flat,
                    bill_month=bill_month,
                    payable_amount=society.standard_rate,
                    due_date=due_date,
                    status='pending'
                )
                created_count += 1

        return Response({
            'success': True,
            'message': f'Generated {created_count} bills for {bill_month}.',
            'bill_month': bill_month,
            'due_date': str(due_date),
            'standard_rate': float(society.standard_rate),
            'late_fee_percent': float(society.late_fee_percent or 0)
        }, status=status.HTTP_201_CREATED)
    

# 4. Payment History for Resident
class ResidentPaymentHistoryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        resident = Resident.objects.filter(user=request.user).first()
        if not resident:
            return Response({'success': False, 'error': 'Resident not found.'}, status=status.HTTP_404_NOT_FOUND)

        receipts = PaymentReceipt.objects.filter(payment__resident=resident).order_by('-generated_at')
        return Response({
            'success': True,
            'history': PaymentReceiptSerializer(receipts, many=True).data
        }, status=status.HTTP_200_OK)


# 5. Society Expenses (List & Add)
class SocietyExpensesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        society = request.user.society
        if not society:
            return Response({'success': False, 'error': 'Society context missing.'}, status=status.HTTP_404_NOT_FOUND)

        expenses = SocietyExpenses.objects.filter(society=society).order_by('-payment_date')
        return Response({
            'success': True,
            'expenses': SocietyExpensesSerializer(expenses, many=True).data
        }, status=status.HTTP_200_OK)

    def post(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin', 'treasurer']:
            return Response({'success': False, 'error': 'Unauthorized. Chairman/Treasurer privilege required.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = SocietyExpensesSerializer(data=request.data)
        if not serializer.is_valid():
            first_err = next(iter(serializer.errors.values()))[0]
            return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

        expense = SocietyExpenses.objects.create(
            expense_id=str(uuid.uuid4())[:6].upper(),
            society=request.user.society,
            **serializer.validated_data
        )

        return Response({
            'success': True,
            'message': 'Expense recorded successfully!',
            'expense': SocietyExpensesSerializer(expense).data
        }, status=status.HTTP_201_CREATED)


# 6. Financial Overview (Chairman / Treasurer Dashboard)
class ChairmanFinancialSummaryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin', 'treasurer']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        society = request.user.society
        # 1. Direct Maintenance Payments from residents
        total_maintenance_collected = Payment.objects.filter(
            resident__flat__block__society=society, 
            status='completed'
        ).aggregate(Sum('amount'))['amount__sum'] or Decimal('0.00')

        # 2. Miscellaneous/Other Society Incomes
        total_misc_income = SocietyIncome.objects.filter(
            society=society
        ).aggregate(Sum('amount'))['amount__sum'] or Decimal('0.00')

        total_collected = total_maintenance_collected + total_misc_income

        assigned_flat_ids = list(Resident.objects.filter(
            flat__block__society=society,
            user__isnull=False
        ).values_list('flat_id', flat=True).distinct())

        total_pending = MaintenanceBill.objects.filter(
            flat__block__society=society, 
            status='pending'
        ).filter(
            Q(flat_id__in=assigned_flat_ids) | Q(payer__isnull=False)
        ).aggregate(Sum('payable_amount'))['payable_amount__sum'] or Decimal('0.00')

        total_expenses = SocietyExpenses.objects.filter(
            society=society
        ).aggregate(Sum('amount'))['amount__sum'] or Decimal('0.00')

        return Response({
            'success': True,
            'total_collected': float(total_collected),
            'total_maintenance_collected': float(total_maintenance_collected),
            'total_misc_income': float(total_misc_income),
            'total_pending': float(total_pending),
            'total_expenses': float(total_expenses),
            'net_balance': float(total_collected) - float(total_expenses)
        }, status=status.HTTP_200_OK)

# 7. Executive Multi-Metric Financial Reports
class SocietyExecutiveReportView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin', 'treasurer']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        society = request.user.society
        if not society:
            return Response({'success': False, 'error': 'Society context missing.'}, status=status.HTTP_404_NOT_FOUND)

        today = timezone.now().date()
        months_back = int(request.query_params.get('months', 6))
        months_back = max(3, min(24, months_back))

        # 1. OVERALL TREASURY POSITION
        total_maintenance_collected = Payment.objects.filter(
            resident__flat__block__society=society, 
            status='completed'
        ).aggregate(Sum('amount'))['amount__sum'] or Decimal('0.00')

        total_misc_income = SocietyIncome.objects.filter(
            society=society
        ).aggregate(Sum('amount'))['amount__sum'] or Decimal('0.00')

        total_inflow_lifetime = total_maintenance_collected + total_misc_income

        total_expenses_lifetime = SocietyExpenses.objects.filter(
            society=society
        ).aggregate(Sum('amount'))['amount__sum'] or Decimal('0.00')

        net_treasury_balance = total_inflow_lifetime - total_expenses_lifetime

        assigned_flat_ids = list(Resident.objects.filter(
            flat__block__society=society,
            user__isnull=False
        ).values_list('flat_id', flat=True).distinct())

        total_pending_maintenance = MaintenanceBill.objects.filter(
            flat__block__society=society, 
            status='pending'
        ).filter(
            Q(flat_id__in=assigned_flat_ids) | Q(payer__isnull=False)
        ).aggregate(Sum('payable_amount'))['payable_amount__sum'] or Decimal('0.00')

        total_assigned_flats = len(assigned_flat_ids)
        total_flats_count = Flats.objects.filter(block__society=society).count()

        treasury_summary = {
            'total_inflow': float(total_inflow_lifetime),
            'total_maintenance_collected': float(total_maintenance_collected),
            'total_misc_income': float(total_misc_income),
            'total_expenses': float(total_expenses_lifetime),
            'net_balance': float(net_treasury_balance),
            'total_pending_dues': float(total_pending_maintenance),
            'assigned_units': total_assigned_flats,
            'total_units': total_flats_count,
            'standard_rate': float(society.standard_rate or 0),
        }

        # 2. TIME-SERIES COMPARATIVE FINANCIAL METRICS (PAST N MONTHS)
        months_list = []
        cur_year = today.year
        cur_month = today.month

        for i in range(months_back - 1, -1, -1):
            m = cur_month - i
            y = cur_year
            while m <= 0:
                m += 12
                y -= 1
            months_list.append((y, m))

        monthly_reports = []

        for year, month in months_list:
            m_name = calendar.month_name[month]
            m_abbr = calendar.month_abbr[month]
            month_label = f"{m_name} {year}"
            month_code = f"{year}-{month:02d}"
            _, last_day = calendar.monthrange(year, month)
            start_date = date(year, month, 1)
            end_date = date(year, month, last_day)

            # Maintenance collections from assigned flats only
            billed = MaintenanceBill.objects.filter(
                flat__block__society=society,
                bill_month__icontains=m_name
            ).filter(
                Q(flat_id__in=assigned_flat_ids) | Q(payer__isnull=False)
            ).aggregate(Sum('payable_amount'))['payable_amount__sum'] or Decimal('0.00')

            collected = Payment.objects.filter(
                bill__flat__block__society=society,
                bill__bill_month__icontains=m_name,
                status='completed'
            ).aggregate(Sum('amount'))['amount__sum'] or Decimal('0.00')

            pending_amt = max(Decimal('0.00'), billed - collected)
            collection_rate = round(float((collected / billed) * 100), 1) if billed > 0 else 0.0

            soc_expenses = SocietyExpenses.objects.filter(
                society=society,
                payment_date__range=(start_date, end_date)
            ).aggregate(Sum('amount'))['amount__sum'] or Decimal('0.00')

            soc_income = SocietyIncome.objects.filter(
                society=society,
                received_date__range=(start_date, end_date)
            ).aggregate(Sum('amount'))['amount__sum'] or Decimal('0.00')

            total_inflow = collected + soc_income
            net_surplus = total_inflow - soc_expenses

            # Month Categorical Breakdowns
            month_expenses_cats = SocietyExpenses.objects.filter(
                society=society,
                payment_date__range=(start_date, end_date)
            ).values('expense_type').annotate(total=Sum('amount')).order_by('-total')

            month_incomes_cats = SocietyIncome.objects.filter(
                society=society,
                received_date__range=(start_date, end_date)
            ).values('income_type').annotate(total=Sum('amount')).order_by('-total')

            monthly_reports.append({
                'month_code': month_code,
                'month_name': m_name,
                'month_abbr': m_abbr,
                'month_label': month_label,
                'year': year,
                'month': month,
                'is_current': (year == cur_year and month == cur_month),
                'maintenance_billed': float(billed),
                'maintenance_collected': float(collected),
                'maintenance_pending': float(pending_amt),
                'collection_rate': collection_rate,
                'other_income': float(soc_income),
                'society_income': float(soc_income),
                'total_income': float(total_inflow),
                'total_expenses': float(soc_expenses),
                'net_surplus': float(net_surplus),
                'expense_breakdown': [
                    {'category': e['expense_type'], 'amount': float(e['total'])}
                    for e in month_expenses_cats
                ],
                'income_breakdown': [
                    {'category': inc['income_type'], 'amount': float(inc['total'])}
                    for inc in month_incomes_cats
                ],
            })

        # 3. OVERALL CATEGORICAL BREAKDOWNS (ALL TIME)
        all_time_expenses = SocietyExpenses.objects.filter(
            society=society
        ).values('expense_type').annotate(total=Sum('amount')).order_by('-total')

        all_time_incomes = SocietyIncome.objects.filter(
            society=society
        ).values('income_type').annotate(total=Sum('amount')).order_by('-total')

        # Current month breakdowns
        cur_report = next((r for r in monthly_reports if r['is_current']), monthly_reports[-1] if monthly_reports else None)

        return Response({
            'success': True,
            'society': {
                'name': society.society_name if society else 'Zenith Square Society',
                'city': society.society_city if society else 'Ahmedabad',
                'code': society.society_id if society else '',
            },
            'treasury_summary': treasury_summary,
            'monthly_reports': monthly_reports,
            'monthly_summary_table': monthly_reports,  # backward compatibility
            'category_breakdowns': {
                'expenses': [
                    {'category': e['expense_type'], 'amount': float(e['total'])}
                    for e in all_time_expenses
                ],
                'incomes': [
                    {'category': inc['income_type'], 'amount': float(inc['total'])}
                    for inc in all_time_incomes
                ],
            },
            'current_month_breakdowns': {
                'expenses': cur_report['expense_breakdown'] if cur_report else [],
                'incomes': cur_report['income_breakdown'] if cur_report else [],
            }
        }, status=status.HTTP_200_OK)

class SocietyIncomeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        society = request.user.society
        if not society:
            return Response({'success': False, 'error': 'Society context missing.'}, status=status.HTTP_404_NOT_FOUND)

        incomes = SocietyIncome.objects.filter(society=society).order_by('-received_date')
        return Response({
            'success': True,
            'incomes': SocietyIncomeSerializer(incomes, many=True).data
        }, status=status.HTTP_200_OK)

    def post(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin', 'treasurer']:
            return Response({'success': False, 'error': 'Unauthorized. Chairman/Treasurer privilege required.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = SocietyIncomeSerializer(data=request.data)
        if not serializer.is_valid():
            first_err = next(iter(serializer.errors.values()))[0]
            return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

        income = SocietyIncome.objects.create(
            income_id=str(uuid.uuid4())[:6].upper(),
            society=request.user.society,
            **serializer.validated_data
        )

        return Response({
            'success': True,
            'message': 'Income recorded successfully!',
            'income': SocietyIncomeSerializer(income).data
        }, status=status.HTTP_201_CREATED)


# 8. All Maintenance Bills (For Treasurer & Chairman)
class AllMaintenanceBillsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin', 'treasurer']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        society = request.user.society
        if not society:
            return Response({'success': False, 'error': 'Society context missing.'}, status=status.HTTP_404_NOT_FOUND)

        bills = MaintenanceBill.objects.filter(flat__block__society=society).select_related('flat', 'flat__block', 'payer').order_by('-due_date')

        bill_list = []
        for b in bills:
            # 1. Prefer primary occupant, otherwise latest registered resident with a user
            primary_occ = Occupancy.objects.filter(flat=b.flat, is_primary=True).select_related('resident__user').first()
            if primary_occ and primary_occ.resident and primary_occ.resident.user:
                resident = primary_occ.resident
            else:
                resident = Resident.objects.filter(flat=b.flat, user__isnull=False).order_by('-move_in_date', '-resident_id').first()

            all_residents_names = list(Resident.objects.filter(flat=b.flat, user__isnull=False).values_list('user__user_name', flat=True))

            has_assigned_resident = bool(resident and resident.user)
            is_assigned = has_assigned_resident or (b.payer is not None)
            resident_name = resident.user.user_name if has_assigned_resident else (b.payer.user_name if b.payer else 'Unassigned')
            payable_amt = float(b.payable_amount) if is_assigned else 0.0

            bill_list.append({
                'bill_id': b.bill_id,
                'society_name': society.society_name if society else 'Zenith Square Society',
                'society_city': society.society_city if society else 'Ahmedabad',
                'flat_id': b.flat.flat_id if b.flat else None,
                'flat_number': b.flat.flat_number if b.flat else 'N/A',
                'block_name': b.flat.block.block_name if (b.flat and b.flat.block) else 'N/A',
                'resident_name': resident_name,
                'resident_phone': resident.user.user_phone if has_assigned_resident else '',
                'all_residents': all_residents_names,
                'is_assigned': is_assigned,
                'society_maintenance_amount': float(b.payable_amount),
                'payable_amount': payable_amt,
                'bill_month': b.bill_month,
                'due_date': str(b.due_date),
                'status': b.status if is_assigned else 'UNASSIGNED',
            })
        return Response({'success': True, 'bills': bill_list}, status=status.HTTP_200_OK)


# 9. Offline Payment Verification & Settlement (Cash / Cheque / Bank Transfer)
class OfflinePaymentView(APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin', 'treasurer']:
            return Response({'success': False, 'error': 'Unauthorized. Treasurer/Chairman privilege required.'}, status=status.HTTP_403_FORBIDDEN)

        bill_id = request.data.get('bill_id')
        payment_method = request.data.get('payment_method', 'CASH').upper()

        if not bill_id:
            return Response({'success': False, 'error': 'bill_id is required.'}, status=status.HTTP_400_BAD_REQUEST)

        bill = MaintenanceBill.objects.select_for_update().filter(bill_id=bill_id).first()
        if not bill:
            return Response({'success': False, 'error': 'Maintenance bill not found.'}, status=status.HTTP_404_NOT_FOUND)

        if bill.status == 'paid':
            return Response({'success': False, 'error': 'This bill has already been settled.'}, status=status.HTTP_400_BAD_REQUEST)

        # Check if flat is assigned to a resident (primary occupant or latest registered resident)
        primary_occ = Occupancy.objects.filter(flat=bill.flat, is_primary=True).select_related('resident__user').first()
        if primary_occ and primary_occ.resident and primary_occ.resident.user:
            resident = primary_occ.resident
        else:
            resident = Resident.objects.filter(flat=bill.flat, user__isnull=False).order_by('-move_in_date', '-resident_id').first()

        is_assigned = bool(resident and resident.user) or (bill.payer is not None)
        if not is_assigned:
            return Response({
                'success': False,
                'error': f'Flat {bill.flat.flat_number if bill.flat else "N/A"} is currently unassigned. Offline payment cannot be verified until a resident is assigned.'
            }, status=status.HTTP_400_BAD_REQUEST)

        bill.status = 'paid'
        bill.payer = resident.user if (resident and resident.user) else request.user
        bill.save()

        payment_id = str(uuid.uuid4())[:5].upper()
        payment = Payment.objects.create(
            payment_id=payment_id,
            resident=resident,
            bill=bill,
            payment_type='MAINTENANCE',
            amount=bill.payable_amount,
            payment_method=payment_method,
            status='completed',
            payment_date=timezone.now()
        )

        receipt_id = str(uuid.uuid4())[:6].upper()
        receipt_no = f"REC-OFFLINE-{datetime.now().strftime('%Y%m')}-{payment_id}"
        receipt = PaymentReceipt.objects.create(
            receipt_id=receipt_id,
            payment=payment,
            receipt_number=receipt_no,
            generated_at=timezone.now()
        )

        return Response({
            'success': True,
            'message': f'Offline payment ({payment_method}) recorded & receipt generated!',
            'receipt': PaymentReceiptSerializer(receipt).data,
            'payment_id': payment_id
        }, status=status.HTTP_201_CREATED)


# 10. All Payment Receipts (For Treasurer & Chairman)
class AllReceiptsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin', 'treasurer']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        society = request.user.society
        if not society:
            return Response({'success': False, 'error': 'Society context missing.'}, status=status.HTTP_404_NOT_FOUND)

        receipts = PaymentReceipt.objects.filter(payment__resident__flat__block__society=society).select_related(
            'payment', 'payment__resident', 'payment__resident__user', 'payment__bill', 'payment__bill__flat'
        ).order_by('-generated_at')

        receipt_list = []
        for r in receipts:
            p = r.payment
            b = p.bill if p else None
            flat = b.flat if b else (p.resident.flat if (p and p.resident) else None)
            receipt_list.append({
                'receipt_id': r.receipt_id,
                'receipt_number': r.receipt_number,
                'society_name': society.society_name if society else 'Zenith Square Society',
                'society_city': society.society_city if society else 'Ahmedabad',
                'generated_at': r.generated_at.strftime('%Y-%m-%d %H:%M') if r.generated_at else '',
                'payment_id': p.payment_id if p else '',
                'amount': float(p.amount) if p else 0.0,
                'payment_method': p.payment_method if p else '',
                'resident_name': p.resident.user.user_name if (p and p.resident and p.resident.user) else 'Resident',
                'flat_number': flat.flat_number if flat else 'N/A',
                'bill_month': b.bill_month if b else 'Maintenance'
            })

        return Response({'success': True, 'receipts': receipt_list}, status=status.HTTP_200_OK)


# 11. Society Bank Account Details
class SocietyBankDetailsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        society = request.user.society
        if not society:
            return Response({'success': False, 'error': 'Society missing.'}, status=status.HTTP_404_NOT_FOUND)

        bank_data = {
            'account_name': society.society_name + ' Maintenance Fund A/C',
            'bank_name': 'HDFC Bank Ltd',
            'account_number': '5010098273641',
            'ifsc_code': 'HDFC0001890',
            'branch': society.society_city + ' Branch',
            'upi_id': society.society_name.lower().replace(' ', '') + '@hdfcbank',
            'standard_rate': float(society.standard_rate or 0),
            'billing_cycle': society.billing_cycle or 'Monthly',
        }
        return Response({'success': True, 'bank_details': bank_data}, status=status.HTTP_200_OK)

    def post(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin', 'treasurer']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        return Response({'success': True, 'message': 'Bank details updated successfully!'}, status=status.HTTP_200_OK)