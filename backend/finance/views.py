import uuid
import datetime
from django.db import transaction
from django.db.models import Sum
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from core_api.models import Resident
from .models import MaintenanceBill, Payment, PaymentReceipt, SocietyExpenses
from .serializers import MaintenanceBillSerializer, PaymentReceiptSerializer, SocietyExpensesSerializer


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

        # 1. Update Bill status
        bill.status = 'paid'
        bill.payer = request.user
        bill.save()

        # 2. Record Payment
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

        # 3. Create Receipt
        receipt_id = str(uuid.uuid4())[:6].upper()
        receipt_no = f"REC-{datetime.datetime.now().strftime('%Y%m')}-{payment_id}"
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


# 3. Payment History for Resident
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


# 4. Society Expense Reports
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
        # Chairman only
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


# 5. Financial Overview (Chairman Dashboard)
class ChairmanFinancialSummaryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        society = request.user.society
        total_collected = Payment.objects.filter(resident__flat__block__society=society, status='completed').aggregate(Sum('amount'))['amount__sum'] or 0.00
        total_pending = MaintenanceBill.objects.filter(flat__block__society=society, status='pending').aggregate(Sum('payable_amount'))['payable_amount__sum'] or 0.00
        total_expenses = SocietyExpenses.objects.filter(society=society).aggregate(Sum('amount'))['amount__sum'] or 0.00

        return Response({
            'success': True,
            'total_collected': float(total_collected),
            'total_pending': float(total_pending),
            'total_expenses': float(total_expenses),
            'net_balance': float(total_collected) - float(total_expenses)
        }, status=status.HTTP_200_OK)