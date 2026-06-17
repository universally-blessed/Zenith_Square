from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import Resident, SocietyExpenses
from .services import get_resident_pending_bill, settle_bill_payment, get_formatted_payment_history,get_society_expense_report
from .serializers import SocietyExpensesSerializer

@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_latest_maintenance_bill(request):
    resident = Resident.objects.filter(user_id=request.user.username).first()
    bill = get_resident_pending_bill(resident)
    if not bill:
        return Response({'no_bill': True, 'message': 'All maintenance settled!'})
    return Response({
        'bill_id': bill.bill_id,
        'amount': float(bill.payable_amount),
        'billing_period': bill.bill_month,
        'due_date': str(bill.due_date)
    })

@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def settle_maintenance_payment(request):
    if settle_bill_payment(request.data.get('bill_id')):
        return Response({'success': True})
    return Response({'error': 'Bill not found'}, status=404)

@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_payment_history(request):
    resident = Resident.objects.filter(user_id=request.user.username).first()
    return Response(get_formatted_payment_history(resident.resident_id))

@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def society_expense_report_api(request):
    # Get the user's society context
    resident = Resident.objects.filter(user_id=request.user.username).first()
    if not resident:
        return Response({'error': 'Profile not mapped.'}, status=404)
        
    expenses = get_society_expense_report(resident.flat.block.society_id)
    serializer = SocietyExpensesSerializer(expenses, many=True)
    return Response(serializer.data)