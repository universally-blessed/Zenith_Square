from rest_framework import serializers
from .models import SocietyExpenses

class SocietyExpensesSerializer(serializers.ModelSerializer):
    class Meta:
        model = SocietyExpenses
        fields = ['expense_id', 'society', 'expense_type', 'amount', 'payment_date', 'description']
        read_only_fields = ['expense_id', 'society']