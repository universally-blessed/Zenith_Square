import uuid
from datetime import datetime, date,timedelta
from decimal import Decimal
import calendar
from django.db import transaction
from django.db.models import Sum, Count
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
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized. Chairman/Admin privilege required.'}, status=status.HTTP_403_FORBIDDEN)

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
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized. Chairman privilege required.'}, status=status.HTTP_403_FORBIDDEN)

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


# 6. Financial Overview (Chairman Dashboard)
class ChairmanFinancialSummaryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
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

        total_pending = MaintenanceBill.objects.filter(
            flat__block__society=society, 
            status='pending'
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

# 7. Executive Multi-Metric Reports
class SocietyExecutiveReportView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        society = request.user.society
        if not society:
            return Response({'success': False, 'error': 'Society context missing.'}, status=status.HTTP_404_NOT_FOUND)

        today = timezone.now().date()

        # 1. OCCUPANCY DISTRIBUTION
        total_flats = Flats.objects.filter(block__society=society).count()
        
        active_tenant_flat_ids = list(
            Tenant.objects.filter(
                flat__block__society=society, 
                status__iexact='active'
            ).values_list('flat_id', flat=True).distinct()
        )
        tenant_occupied_flats = len(active_tenant_flat_ids)

        owner_occupied_flats = Occupancy.objects.filter(
            flat__block__society=society,
            occupancy_type__iexact='Owner',
            is_primary=True
        ).exclude(
            flat_id__in=active_tenant_flat_ids
        ).values('flat_id').distinct().count()

        vacant_flats = max(0, total_flats - (tenant_occupied_flats + owner_occupied_flats))

        def calc_pct(count, total):
            return round((count / total * 100), 1) if total > 0 else 0.0

        occupancy_data = {
            'total_flats': total_flats,
            'owner_occupied': {
                'count': owner_occupied_flats,
                'percentage': calc_pct(owner_occupied_flats, total_flats)
            },
            'tenant_occupied': {
                'count': tenant_occupied_flats,
                'percentage': calc_pct(tenant_occupied_flats, total_flats)
            },
            'vacant': {
                'count': vacant_flats,
                'percentage': calc_pct(vacant_flats, total_flats)
            }
        }

        # 2. TIME-SERIES COMPARATIVE METRICS (LAST 3 MONTHS)
        months_list = []
        cur_year = today.year
        cur_month = today.month

        for i in range(2, -1, -1):
            m = cur_month - i
            y = cur_year
            while m <= 0:
                m += 12
                y -= 1
            months_list.append((y, m))

        monthly_summary = []
        total_society_residents = Resident.objects.filter(flat__block__society=society).count()

        for year, month in months_list:
            m_name = calendar.month_name[month]
            m_abbr = calendar.month_abbr[month]
            _, last_day = calendar.monthrange(year, month)
            start_date = date(year, month, 1)
            end_date = date(year, month, last_day)

            # Financial Metrics
            billed = MaintenanceBill.objects.filter(
                flat__block__society=society,
                bill_month__icontains=m_name
            ).aggregate(Sum('payable_amount'))['payable_amount__sum'] or Decimal('0.00')

            collected = Payment.objects.filter(
                bill__flat__block__society=society,
                bill__bill_month__icontains=m_name,
                status='completed'
            ).aggregate(Sum('amount'))['amount__sum'] or Decimal('0.00')

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

            amenity_rev = Payment.objects.filter(
                resident__flat__block__society=society,
                payment_type__iexact='AMENITY',
                status='completed',
                payment_date__date__range=(start_date, end_date)
            ).aggregate(Sum('amount'))['amount__sum'] or Decimal('0.00')

            defaulters_count = MaintenanceBill.objects.filter(
                flat__block__society=society,
                bill_month__icontains=m_name,
                status='pending'
            ).values('flat_id').distinct().count()

            # Security & Complaints
            alerts_count = SecurityAlerts.objects.filter(
                triggered_by__society=society,
                created_at__date__range=(start_date, end_date)
            ).count()

            complaints_filed = Complaint.objects.filter(
                block__society=society,
                created_at__date__range=(start_date, end_date)
            ).count()

            complaints_resolved = Complaint.objects.filter(
                block__society=society,
                status__iexact='resolved',
                created_at__date__range=(start_date, end_date)
            ).count()

            avg_res_days = 3 if complaints_resolved > 0 else 0

            # Operational Metrics
            visitors_count = VisitorLogs.objects.filter(
                flat__block__society=society,
                entry_time__date__range=(start_date, end_date)
            ).count()

            amenity_bookings_count = AmenityBooking.objects.filter(
                amenity__society=society,
                booking_date__range=(start_date, end_date)
            ).count()

            total_voters = PollsResponse.objects.filter(
                poll__created_by__society=society,
                voted_at__date__range=(start_date, end_date)
            ).values('user_id').distinct().count()

            participation_rate = round((total_voters / total_society_residents * 100), 1) if total_society_residents > 0 else 0.0

            asset_cost = AssetMaintenance.objects.filter(
                asset__society=society,
                maintenance_date__range=(start_date, end_date)
            ).aggregate(Sum('maintenance_cost'))['maintenance_cost__sum'] or Decimal('0.00')

            monthly_summary.append({
                'month_name': m_name,
                'month_abbr': m_abbr,
                'year': year,
                'collection_rate': collection_rate,
                'total_income': float(total_inflow),
                'other_income': float(soc_income),
                'total_expenses': float(soc_expenses),
                'net_surplus': float(net_surplus),
                'amenity_revenue': float(amenity_rev),
                'defaulters_count': defaulters_count,
                'security_alerts': alerts_count,
                'complaints_filed': complaints_filed,
                'complaints_resolved': complaints_resolved,
                'avg_resolution_days': avg_res_days,
                'total_visitors': visitors_count,
                'amenity_bookings': amenity_bookings_count,
                'participation_rate': participation_rate,
                'asset_maintenance_cost': float(asset_cost)
            })

        # 3. CURRENT MONTH CATEGORICAL BREAKDOWNS
        latest_month_expenses = SocietyExpenses.objects.filter(
            society=society,
            payment_date__month=today.month,
            payment_date__year=today.year
        ).values('expense_type').annotate(total=Sum('amount'))

        latest_month_incomes = SocietyIncome.objects.filter(
            society=society,
            received_date__month=today.month,
            received_date__year=today.year
        ).values('income_type').annotate(total=Sum('amount'))

        alert_categories = SecurityAlerts.objects.filter(
            triggered_by__society=society,
            created_at__month=today.month,
            created_at__year=today.year
        ).values('alert_type').annotate(count=Count('alert_id'))

        visitor_categories = VisitorLogs.objects.filter(
            flat__block__society=society,
            entry_time__month=today.month,
            entry_time__year=today.year
        ).values('purpose').annotate(count=Count('log_id'))

        return Response({
            'success': True,
            'occupancy_distribution': occupancy_data,
            'monthly_summary_table': monthly_summary,
            'current_month_breakdowns': {
                'expenses': [
                    {'category': e['expense_type'], 'amount': float(e['total'])}
                    for e in latest_month_expenses
                ],
                'incomes': [
                    {'category': inc['income_type'], 'amount': float(inc['total'])}
                    for inc in latest_month_incomes
                ],
                'security_alerts': list(alert_categories),
                'visitors': list(visitor_categories),
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
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized. Chairman privilege required.'}, status=status.HTTP_403_FORBIDDEN)

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