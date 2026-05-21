import random
from datetime import datetime, timedelta
from django.utils import timezone
from django.db.models import Q
from django.core.mail import send_mail
from django.contrib.auth.hashers import make_password, check_password

from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authentication import TokenAuthentication

# Exact 32-Table Model Blueprint Imports
from .models import (
    Users, Resident, Roles, TemporaryOTP, Vehicle, LostFoundItem,
    Complaint, AmenityBooking, SocietyExpenses, MaintenanceBill,
    Polls, PollsOption, PollsResponse, Societies, Blocks, Notice, Meeting, Payment, PaymentReceipt, Amenity, SecurityAlerts
)

# Unified Master Serializer Imports
from .serializers import (
    VehicleSerializer, ComplaintSerializer, 
    AmenityBookingSerializer, SocietyExpensesSerializer
)

# ==========================================
# 🏢 PUBLIC UTILITY DATA LOOKUPS
# ==========================================

@api_view(['GET'])
@permission_classes([AllowAny])
def list_societies_public(request):
    """ Yields registered society identities for user signup lookups """
    societies = Societies.objects.filter(society_status='active').order_by('society_name')
    data = [{'id': s.society_id, 'name': s.society_name} for s in societies]
    return Response(data, status=status.HTTP_200_OK)

@api_view(['GET'])
@permission_classes([AllowAny])
def list_blocks_by_society(request, society_id):
    """ Pulls relational blocks linked to the chosen parent society """
    blocks = Blocks.objects.filter(society_id=society_id).order_by('block_name')
    data = [{'id': b.block_id, 'name': b.block_name} for b in blocks]
    return Response(data, status=status.HTTP_200_OK)


# ==========================================
# 🔐 SYSTEM UNAUTHENTICATED REGISTRATION GATEWAYS
# ==========================================

@api_view(['POST'])
@permission_classes([AllowAny])
def register_resident(request):
    data = request.data
    try:
        if Users.objects.filter(user_phone=data['user_phone']).exists():
            return Response({'error': 'A user account with this phone number already exists.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            default_role = Roles.objects.get(role_id='R003')
        except Roles.DoesNotExist:
            return Response({'error': 'Default Resident role profile (R003) missing from database.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        new_user = Users.objects.create(
            user_id=f"U{Users.objects.count() + 1:03d}", 
            society_id_id=data.get('society_id', 'SO01'), 
            user_name=data['user_name'],
            user_phone=data['user_phone'],
            user_email=data.get('user_email', ''),
            role_id=default_role,
            password=make_password(data['password']), 
            is_active=True
        )

        Resident.objects.create(
            resident_id=f"RS{Resident.objects.count() + 1:03d}",
            user_id=new_user,
            flat_id_id=data['flat_id'],
            move_in_date=data.get('move_in_date', '2026-05-20')
        )

        generated_code = f"{random.randint(1000, 9999)}"
        TemporaryOTP.objects.update_or_create(
            email=new_user.user_email,
            defaults={'otp_code': generated_code, 'created_at': timezone.now()}
        )

        send_mail(
            subject='Zenith Square - Account Security Verification Code',
            message=f'Welcome to Zenith Square!\n\nYour secure verification code is: {generated_code}',
            from_email='noreply@zenithsquare.com',
            recipient_list=[new_user.user_email],
            fail_silently=False,
        )

        return Response({
            'success': 'Account profile saved. Verification email dispatched.',
            'email': new_user.user_email
        }, status=status.HTTP_201_CREATED)

    except Exception as e:
        return Response({'error': f'Transaction rolled back: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    phone = request.data.get('user_phone')
    password = request.data.get('password')

    if not phone or not password:
        return Response({'error': 'Please provide both user_phone and password fields.'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = Users.objects.get(user_phone=phone, is_active=True)
        if check_password(password, user.password):
            resident_profile = Resident.objects.filter(user_id=user.user_id).first()
            flat_info = resident_profile.flat_id_id if resident_profile else "Unassigned"

            return Response({
                'success': True,
                'user_id': user.user_id,
                'user_name': user.user_name,
                'role': user.role_id.role_name.lower(), 
                'flat_id': flat_info
            }, status=status.HTTP_200_OK)
        else:
            return Response({'error': 'Invalid security credential mapping password.'}, status=status.HTTP_401_UNAUTHORIZED)
    except Users.DoesNotExist:
        return Response({'error': 'No active account profile linked to this phone entity.'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST'])
@permission_classes([AllowAny])
def verify_registration_otp(request):
    email = request.data.get('email')
    submitted_otp = request.data.get('otp')

    if not email or not submitted_otp:
        return Response({'error': 'Missing parameters: email and otp are required.'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        otp_record = TemporaryOTP.objects.get(email=email)
        if otp_record.is_expired():
            return Response({'error': 'This verification code has expired.'}, status=status.HTTP_400_BAD_REQUEST)

        if otp_record.otp_code == submitted_otp:
            user_profile = Users.objects.get(user_email=email)
            user_profile.is_active = True
            user_profile.save()
            otp_record.delete()
            return Response({'message': 'Identity verified successfully! Account is active.'}, status=status.HTTP_200_OK)
        else:
            return Response({'error': 'Incorrect verification code.'}, status=status.HTTP_400_BAD_REQUEST)
    except TemporaryOTP.DoesNotExist:
        return Response({'error': 'No active verification sequence initiated.'}, status=status.HTTP_404_NOT_FOUND)
    except Users.DoesNotExist:
        return Response({'error': 'Relational profile account trace missing.'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST'])
@permission_classes([AllowAny])
def request_password_reset(request):
    email = request.data.get('email')
    if not email:
        return Response({'error': 'Please provide a registered email address.'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = Users.objects.get(user_email=email)
        reset_otp = f"{random.randint(1000, 9999)}"

        TemporaryOTP.objects.update_or_create(
            email=email,
            defaults={'otp_code': reset_otp, 'created_at': timezone.now()}
        )

        send_mail(
            subject='Zenith Square - Password Recovery Assistance',
            message=f'Hello {user.user_name},\n\nYour recovery code is: {reset_otp}',
            from_email='security@zenithsquare.com',
            recipient_list=[email],
            fail_silently=False,
        )
        return Response({'success': True, 'message': 'Reset code sent successfully!'}, status=status.HTTP_200_OK)
    except Users.DoesNotExist:
        return Response({'error': 'No account profile matched this email.'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def change_password(request):
    custom_user_id = request.user.username 
    old_password = request.data.get('old_password')
    new_password = request.data.get('new_password')

    if not old_password or not new_password:
        return Response({'error': 'Please provide both fields.'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user_record = Users.objects.get(user_id=custom_user_id)
        if not check_password(old_password, user_record.password):
            return Response({'error': 'Incorrect current password confirmation.'}, status=status.HTTP_400_BAD_REQUEST)
        
        user_record.password = make_password(new_password)
        user_record.save()
        return Response({'success': 'Password mutated successfully.'}, status=status.HTTP_200_OK)
    except Users.DoesNotExist:
        return Response({'error': 'User profile context not found.'}, status=status.HTTP_404_NOT_FOUND)


# ==========================================
# 🚗 VEHICLE SYSTEM FLOWS (CRUD)
# ==========================================

@api_view(['GET', 'POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def manage_vehicles_api(request):
    custom_user_id = request.user.username 
    resident = Resident.objects.filter(user_id=custom_user_id).first()
    
    if not resident:
        return Response({'error': 'No resident sub-profile mapped.'}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        vehicles = Vehicle.objects.filter(resident_id=resident.resident_id)
        serializer = VehicleSerializer(vehicles, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    elif request.method == 'POST':
        serializer = VehicleSerializer(data=request.data)
        if serializer.is_valid():
            next_vh_id = f"V{Vehicle.objects.count() + 1:05d}"
            serializer.save(vehicle_id=next_vh_id, resident_id=resident)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['PUT', 'DELETE'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def mutate_individual_vehicle_api(request, pk):
    custom_user_id = request.user.username
    resident = Resident.objects.filter(user_id=custom_user_id).first()
    
    try:
        vehicle = Vehicle.objects.get(vehicle_id=pk, resident_id=resident.resident_id)
    except Vehicle.DoesNotExist:
        return Response({'error': 'Vehicle record not found.'}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'PUT':
        serializer = VehicleSerializer(vehicle, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'DELETE':
        vehicle.delete()
        return Response({'success': 'Vehicle unlinked successfully.'}, status=status.HTTP_200_OK)


# ==========================================
# 🛠️ COMPLAINTS DISPATCH MECHANICS
# ==========================================

@api_view(['GET', 'POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def manage_complaints_api(request):
    custom_user_id = request.user.username
    resident = Resident.objects.filter(user_id=custom_user_id).first()

    if request.method == 'GET':
        complaints = Complaint.objects.filter(resident_id=resident.resident_id).order_by('-created_at')
        serializer = ComplaintSerializer(complaints, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    elif request.method == 'POST':
        serializer = ComplaintSerializer(data=request.data)
        if serializer.is_valid():
            c_count = Complaint.objects.count() + 1
            serializer.save(
                complaint_id=f"CM{c_count:03d}",
                resident_id=resident,
                status='pending'
            )
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ==========================================
# 📅 AMENITY RESERVATIONS TIMED CONTROLLER
# ==========================================

@api_view(['GET', 'POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def manage_amenity_bookings_api(request):
    custom_user_id = request.user.username
    resident = Resident.objects.filter(user_id=custom_user_id).first()
    if not resident:
        return Response({'error': 'No resident sub-profile verified.'}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        bookings = AmenityBooking.objects.filter(resident_id=resident.resident_id).order_by('-booking_date')
        payload = []
        for b in bookings:
            deadline_str = b.payment_deadline.isoformat() if b.payment_deadline else (timezone.now() + timedelta(minutes=60)).isoformat()
            cost_mapping = "₹ 1,500.00" if "hall" in b.amenity_id.amenity_name.lower() else "₹ 500.00"
            payload.append({
                'booking_id': b.booking_id,
                'amenity_name': b.amenity_id.amenity_name,
                'booking_date': str(b.booking_date),
                'slots': f"{b.start_time.strftime('%I:%M %p')} - {b.end_time.strftime('%I:%M %p')}",
                'status': b.status.lower(),
                'payment_deadline': deadline_str,
                'cost': cost_mapping
            })
        return Response(payload, status=status.HTTP_200_OK)

    elif request.method == 'POST':
        data = request.data
        try:
            generated_booking_id = f"BK{AmenityBooking.objects.count() + 1:04d}"
            target_amenity = Amenity.objects.filter(amenity_name=data['amenity_name']).first()
            if not target_amenity:
                return Response({'error': 'Target facility asset not found.'}, status=status.HTTP_404_NOT_FOUND)

            start_str, end_str = data['slots'].split(' - ')
            start_time = datetime.strptime(start_str.strip(), '%I:%M %p').time()
            end_time = datetime.strptime(end_str.strip(), '%I:%M %p').time()

            conflict_exists = AmenityBooking.objects.filter(
                amenity_id=target_amenity.amenity_id,
                booking_date=data['booking_date'],
                status__in=['pending', 'approved', 'approved_awaiting_payment']
            ).filter(start_time__lt=end_time, end_time__gt=start_time).exists()

            if conflict_exists:
                return Response({'error': 'This time slice is already reserved.'}, status=status.HTTP_400_BAD_REQUEST)

            new_booking = AmenityBooking.objects.create(
                booking_id=generated_booking_id,
                amenity_id=target_amenity,
                resident_id=resident,
                booking_date=data['booking_date'],
                start_time=start_time,
                end_time=end_time,
                status='pending',
                payment_deadline=timezone.now() + timedelta(minutes=60)
            )
            return Response({'success': True, 'booking_id': new_booking.booking_id}, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({'error': f'Database rejection: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)


# ==========================================
# 💳 FINANCIAL TRANSPARENCY & BILLING
# ==========================================

@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_latest_maintenance_bill(request):
    custom_user_id = request.user.username
    try:
        resident_profile = Resident.objects.filter(user_id=custom_user_id).first()
        bill = MaintenanceBill.objects.filter(flat_id=resident_profile.flat_id_id, status__iexact='pending').order_by('-due_date').first()
        if not bill:
            return Response({'no_bill': True, 'message': 'All maintenance settled!'}, status=status.HTTP_200_OK)

        return Response({
            'no_bill': False,
            'bill_id': bill.bill_id,
            'amount': float(bill.payable_amount), 
            'billing_period': bill.bill_month,     
            'due_date': str(bill.due_date)
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def settle_maintenance_payment(request):
    bill_id = request.data.get('bill_id')
    try:
        bill = MaintenanceBill.objects.get(bill_id=bill_id)
        bill.status = 'paid'
        bill.save()
        return Response({'success': True, 'message': 'Transaction logged successfully.'}, status=status.HTTP_200_OK)
    except MaintenanceBill.DoesNotExist:
        return Response({'error': 'Target bill not found.'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def society_expense_report_api(request):
    current_expenses = SocietyExpenses.objects.all().order_by('-payment_date')
    serializer = SocietyExpensesSerializer(current_expenses, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_payment_history(request):
    custom_user_id = request.user.username
    try:
        resident_profile = Resident.objects.filter(user_id=custom_user_id).first()
        history = Payment.objects.filter(resident_id=resident_profile.resident_id, status__iexact='success').order_by('-payment_date')
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
        return Response(payload, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


# ==========================================
# 📊 PROFILE PROFILE, ANNOUNCEMENTS, & POLLS
# ==========================================

@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_resident_dashboard_meta(request):
    custom_user_id = request.user.username
    try:
        user = Users.objects.get(user_id=custom_user_id)
        resident_profile = Resident.objects.filter(user_id=user.user_id).first()
        flat_number = resident_profile.flat_id.flat_number if resident_profile and resident_profile.flat_id else "N/A"
        block_name = resident_profile.flat_id.block_id.block_name if resident_profile and resident_profile.flat_id and resident_profile.flat_id.block_id else "N/A"
        return Response({
            'user_name': user.user_name,
            'society_name': user.society_id.society_name if user.society_id else "Zenith Square",
            'unit_info': f"{block_name} - {flat_number}",
            'email': user.user_email,
            'phone': user.user_phone
        }, status=status.HTTP_200_OK)
    except Users.DoesNotExist:
        return Response({'error': 'Profile context trace missing.'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_active_polls(request):
    custom_user_id = request.user.username
    polls = Polls.objects.filter(end_date__gte=timezone.now().date())
    response_data = []
    for poll in polls:
        has_voted = PollsResponse.objects.filter(poll_id=poll.poll_id, user_id=custom_user_id).exists()
        options = PollsOption.objects.filter(poll_id=poll.poll_id)
        total_votes = PollsResponse.objects.filter(poll_id=poll.poll_id).count()
        options_data = []
        for opt in options:
            opt_votes = PollsResponse.objects.filter(option_id=opt.option_id).count()
            options_data.append({
                'option_id': opt.option_id,
                'option_text': opt.option_text,
                'percentage': round((opt_votes / total_votes * 100), 1) if total_votes > 0 else 0.0
            })
        response_data.append({
            'poll_id': poll.poll_id,
            'title': poll.poll_title,
            'description': poll.poll_description,
            'end_date': str(poll.end_date),
            'has_voted': has_voted,
            'options': options_data
        })
    return Response(response_data, status=status.HTTP_200_OK)


@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def cast_poll_vote(request):
    custom_user_id = request.user.username
    poll_id = request.data.get('poll_id')
    option_id = request.data.get('option_id')
    if PollsResponse.objects.filter(poll_id=poll_id, user_id=custom_user_id).exists():
        return Response({'error': 'You have already voted.'}, status=status.HTTP_400_BAD_REQUEST)
    try:
        PollsResponse.objects.create(
            response_id=f"R{PollsResponse.objects.count() + 1:05d}",
            poll_id_id=poll_id, option_id_id=option_id, user_id_id=custom_user_id, voted_at=timezone.now()
        )
        return Response({'success': True}, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def manage_lost_found_board(request):
    custom_user_id = request.user.username
    if request.method == 'GET':
        items = LostFoundItem.objects.all().order_by('-reported_date')
        payload = [{
            'item_id': i.item_id, 'item_name': i.item_name, 'item_description': i.item_description,
            'item_status': i.item_status, 'item_location': i.item_location, 'reported_date': str(i.reported_date)
        } for i in items]
        return Response(payload, status=status.HTTP_200_OK)
    elif request.method == 'POST':
        try:
            new_item = LostFoundItem.objects.create(
                item_id=f"LF{LostFoundItem.objects.count() + 1:03d}",
                item_name=request.data['item_name'], item_description=request.data['item_description'],
                item_status=request.data['item_status'].lower(), item_location=request.data['item_location'],
                reported_by_id=custom_user_id, reported_date=timezone.now().date()
            )
            return Response({'success': True, 'item_id': new_item.item_id}, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_society_notices(request):
    try:
        notices = Notice.objects.all().order_by('-created_at')
        payload = [{
            'notice_id': n.notice_id, 'title': n.title, 'description': n.description,
            'created_at': n.created_at.strftime('%Y-%m-%d') if n.created_at else str(timezone.now().date())
        } for n in notices]
        return Response(payload, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_society_meetings(request):
    try:
        meetings = Meeting.objects.all().order_by('-meeting_date')
        payload = [{
            'meeting_id': m.meeting_id, 'title': m.title, 'agenda': m.agenda,
            'meeting_date': str(m.meeting_date), 'start_time': str(m.start_time), 'location': m.location, 'minutes_doc': m.minutes_doc or ''
        } for m in meetings]
        return Response(payload, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def trigger_emergency_sos(request):
    """
    Endpoint: /api/security/sos/
    Writes active panic alerts natively into the 'security_alerts' schema layout.
    """
    custom_user_id = request.user.username  # Active user session id token key match
    try:
        # Resolve the parent account instance profile block
        user_instance = Users.objects.filter(user_id=custom_user_id).first()
        resident_profile = Resident.objects.filter(user_id=custom_user_id).first()
        
        flat_info = f"Flat {resident_profile.flat_id_id}" if resident_profile else "Unknown Unit"
        next_id = f"AL{SecurityAlerts.objects.count() + 1:04d}"

        # Initialize the emergency row entity using exact columns
        SecurityAlerts.objects.create(
            alert_id=next_id,
            alert_type='SOS',
            description=f"Panic distress signal transmitted by {user_instance.user_name} from {flat_info}.",
            triggered_by=user_instance,
            status='active'
        )

        return Response({'success': True, 'message': 'Broadcast payload fired downstream.'}, status=status.HTTP_201_CREATED)

    except Exception as e:
        return Response({'error': f'Transmission failure: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)

from .models import Users

@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def update_profile_details(request):
    """
    Endpoint: /api/resident/update-profile/
    Mutates user contact criteria parameters matching strict column constraints.
    """
    custom_user_id = request.user.username  # Active authenticated user_id
    new_phone = request.data.get('user_phone')
    new_email = request.data.get('user_email', '').strip()

    if not new_phone or len(new_phone) != 10:
        return Response({'error': 'A valid 10-digit mobile layout pattern is required.'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user_record = Users.objects.get(user_id=custom_user_id)

        # Enforce uniqueness safeguards to prevent integrity violations in PostgreSQL
        if Users.objects.filter(user_phone=new_phone).exclude(user_id=custom_user_id).exists():
            return Response({'error': 'This phone number is already registered to another account profile.'}, status=status.HTTP_400_BAD_REQUEST)

        # Mutate schema object fields safely
        user_record.user_phone = new_phone
        user_record.user_email = new_email
        user_record.save()

        return Response({
            'success': True,
            'message': 'Profile updates committed to society master directory framework.'
        }, status=status.HTTP_200_OK)

    except Users.DoesNotExist:
        return Response({'error': 'Active session validation context tracking broken.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': f'Database operational failure: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)
    
from .models import Resident # Ensure your nominee model class is imported too
# Depending on your inspectdb name mapping, ensure it matches your Nominee model reference
from .models import Nominee 

@api_view(['GET', 'POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def manage_resident_nominee(request):
    """
    Endpoint: /api/resident/nominee/
    Handles reading and upsert transformations on the 'nominee' database table schema.
    """
    custom_user_id = request.user.username
    
    # Resolve the active resident profile
    resident = Resident.objects.filter(user_id=custom_user_id).first()
    if not resident:
        return Response({'error': 'No resident sub-profile verified.'}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        nominee_record = Nominee.objects.filter(resident_id=resident.resident_id).first()
        if not nominee_record:
            return Response({'no_nominee': True}, status=status.HTTP_200_OK)
            
        return Response({
            'no_nominee': false,
            'nominee_name': nominee_record.nominee_name,
            'relation': nominee_record.relation,
            'phone': nominee_record.phone,
            'address': nominee_record.address or ''
        }, status=status.HTTP_200_OK)

    elif request.method == 'POST':
        data = request.data
        try:
            # Generate primary key sequence string to align with your schema rule sets (e.g., NM001)
            generated_nominee_id = f"NM{Nominee.objects.count() + 1:03d}"

            # Atomically perform an upsert linked straight to the active resident_id row scope
            nominee_obj, created = Nominee.objects.update_or_create(
                resident_id=resident.resident_id,
                defaults={
                    'nominee_name': data['nominee_name'],
                    'relation': data['relation'],
                    'phone': data['phone'],
                    'address': data['address']
                }
            )

            # If it's a completely new row generation, set its sequential primary key ID
            if created:
                nominee_obj.nominee_id = generated_nominee_id
                nominee_obj.save()

            return Response({
                'success': True,
                'message': 'Nominee parameters securely synchronized with PostgreSQL infrastructure.'
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({'error': f'Database operational error: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)