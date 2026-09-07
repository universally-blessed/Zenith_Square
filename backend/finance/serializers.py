import datetime
from decimal import Decimal
from rest_framework import serializers
from .models import MaintenanceBill, Payment, PaymentReceipt, SocietyExpenses

import datetime
from decimal import Decimal
from rest_framework import serializers
from .models import MaintenanceBill, Payment, PaymentReceipt, SocietyExpenses

class MaintenanceBillSerializer(serializers.ModelSerializer):
    flat_number = serializers.CharField(source='flat.flat_number', read_only=True)
    block_name = serializers.CharField(source='flat.block.block_name', read_only=True)
    society_name = serializers.CharField(source='flat.block.society.society_name', read_only=True)
    
    # Financial Breakdown Fields
    base_amount = serializers.SerializerMethodField()
    late_fee_percent = serializers.SerializerMethodField()
    late_fee_amount = serializers.SerializerMethodField()
    total_payable = serializers.SerializerMethodField()
    is_overdue = serializers.SerializerMethodField()

    class Meta:
        model = MaintenanceBill
        fields = [
            'bill_id',
            'flat_number',
            'block_name',
            'society_name',
            'bill_month',
            'payable_amount',      # Original base amount stored in DB
            'base_amount',
            'late_fee_percent',
            'late_fee_amount',
            'total_payable',
            'due_date',
            'status',
            'is_overdue',
        ]

    def _get_society(self, obj):
        return obj.flat.block.society if (obj.flat and obj.flat.block) else None

    def get_base_amount(self, obj):
        return float(obj.payable_amount)

    def get_late_fee_percent(self, obj):
        society = self._get_society(obj)
        return float(society.late_fee_percent) if (society and society.late_fee_percent) else 0.0

    def get_is_overdue(self, obj):
        return obj.status.lower() == 'pending' and obj.due_date < datetime.date.today()

    def get_late_fee_amount(self, obj):
        if self.get_is_overdue(obj):
            society = self._get_society(obj)
            percent = Decimal(str(society.late_fee_percent or 0))
            return float(round((obj.payable_amount * percent) / Decimal('100'), 2))
        return 0.0

    def get_total_payable(self, obj):
        base = Decimal(str(obj.payable_amount))
        if self.get_is_overdue(obj):
            society = self._get_society(obj)
            percent = Decimal(str(society.late_fee_percent or 0))
            late_fee = round((base * percent) / Decimal('100'), 2)
            return float(base + late_fee)
        return float(base)


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