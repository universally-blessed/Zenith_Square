from django.db import models
from django.utils import timezone

class MaintenanceBill(models.Model):
    bill_id = models.CharField(primary_key=True, max_length=6)
    flat = models.ForeignKey('core_api.Flats', models.DO_NOTHING, db_column='flat_id', blank=True, null=True)
    payer = models.ForeignKey('core_api.Users', models.DO_NOTHING, db_column='payer_id', blank=True, null=True)
    bill_month = models.CharField(max_length=20)
    payable_amount = models.DecimalField(max_digits=10, decimal_places=2)
    due_date = models.DateField()
    status = models.CharField(max_length=20, default='pending')

    class Meta:
        managed = False
        db_table = 'maintenance_bill'
        verbose_name = 'Maintenance Bill'
        verbose_name_plural = 'Maintenance Bills'


class Payment(models.Model):
    payment_id = models.CharField(primary_key=True, max_length=5)
    resident = models.ForeignKey('core_api.Resident', models.DO_NOTHING, db_column='resident_id', blank=True, null=True)
    bill = models.ForeignKey(MaintenanceBill, models.DO_NOTHING, db_column='bill_id', blank=True, null=True)
    payment_type = models.CharField(max_length=20, default='MAINTENANCE')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    payment_method = models.CharField(max_length=20, default='ONLINE')
    status = models.CharField(max_length=20, default='completed')
    payment_date = models.DateTimeField(default=timezone.now)

    class Meta:
        managed = False
        db_table = 'payment'
        verbose_name = 'Payment'
        verbose_name_plural = 'Payments'


class PaymentReceipt(models.Model):
    receipt_id = models.CharField(primary_key=True, max_length=6)
    payment = models.ForeignKey(Payment, models.DO_NOTHING, db_column='payment_id', blank=True, null=True)
    receipt_number = models.CharField(unique=True, max_length=50)
    generated_at = models.DateTimeField(default=timezone.now)

    class Meta:
        managed = False
        db_table = 'payment_receipt'
        verbose_name = 'Payment Receipt'
        verbose_name_plural = 'Payment Receipts'


class SocietyExpenses(models.Model):
    expense_id = models.CharField(primary_key=True, max_length=6)
    society = models.ForeignKey('core_api.Societies', models.DO_NOTHING, db_column='society_id', blank=True, null=True)
    expense_type = models.CharField(max_length=50)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    payment_date = models.DateField(default=timezone.now)
    description = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'society_expenses'
        verbose_name = 'Society Expense'
        verbose_name_plural = 'Society Expenses'