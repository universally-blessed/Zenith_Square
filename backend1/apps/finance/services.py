from .models import MaintenanceBill, Payment, PaymentReceipt, SocietyExpenses

def get_resident_pending_bill(resident):
    return MaintenanceBill.objects.filter(
        flat_id=resident.flat_id_id, 
        status__iexact='pending'
    ).order_by('-due_date').first()

def settle_bill_payment(bill_id):
    bill = MaintenanceBill.objects.get(bill_id=bill_id)
    bill.status = 'paid'
    bill.save()
    return True

def get_formatted_payment_history(resident_id):
    history = Payment.objects.filter(resident_id=resident_id, status__iexact='success').order_by('-payment_date')
    payload = []
    for pay in history:
        receipt = PaymentReceipt.objects.filter(payment_id=pay.payment_id).first()
        payload.append({
            'receipt_id': receipt.receipt_number if receipt else f"REC-{pay.payment_id}",
            'type': f"{pay.payment_type} Clearance",
            'amount': f"₹{float(pay.amount):,.2f}",
            'date': pay.payment_date.strftime('%Y-%m-%d') if pay.payment_date else 'N/A',
            'method': pay.payment_method,
        })
    return payload

def get_society_expense_report(society_id):
    """Retrieves all expenses for a specific society, ordered by date."""
    return SocietyExpenses.objects.filter(
        society_id=society_id
    ).order_by('-payment_date')