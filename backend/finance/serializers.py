from rest_framework import serializers
from .models import MaintenanceBill, Payment, PaymentReceipt, SocietyExpenses

class MaintenanceBillSerializer(serializers.ModelSerializer):
    flat_number = serializers.CharField(source='flat.flat_number', read_only=True)
    block_name = serializers.CharField(source='flat.block.block_name', read_only=True)

    class Meta:
        model = MaintenanceBill
        fields = ['bill_id', 'flat_number', 'block_name', 'bill_month', 'payable_amount', 'due_date', 'status']


class PaymentReceiptSerializer(serializers.ModelSerializer):
    bill_month = serializers.CharField(source='payment.bill.bill_month', read_only=True)
    amount = serializers.DecimalField(source='payment.amount', max_digits=10, decimal_places=2, read_only=True)
    payment_method = serializers.CharField(source='payment.payment_method', read_only=True)
    payment_date = serializers.DateTimeField(source='payment.payment_date', read_only=True)

    class Meta:
        model = PaymentReceipt
        fields = ['receipt_id', 'receipt_number', 'bill_month', 'amount', 'payment_method', 'payment_date', 'generated_at']


class SocietyExpensesSerializer(serializers.ModelSerializer):
    class Meta:
        model = SocietyExpenses
        fields = ['expense_id', 'expense_type', 'amount', 'payment_date', 'description']
        read_only_fields = ['expense_id']