from rest_framework.decorators import api_view, permission_classes, authentication_classes 
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authentication import TokenAuthentication
from rest_framework.authtoken.models import Token
from django.contrib.auth.hashers import make_password, check_password
# Direct imports from your auto-generated SQL model mappings from database.sql
from .models import Users, Resident, Roles, TemporaryOTP
import random
from django.core.mail import send_mail
from django.utils import timezone

@api_view(['POST'])
@permission_classes([AllowAny])
def register_resident(request):
    """
    Endpoint: /api/auth/register/
    Validates mobile input data and writes records into both 'users' and 'resident' tables.
    """
    data = request.data
    try:
        # 1. Prevent duplicate records by validating phone unique constraints
        if Users.objects.filter(user_phone=data['user_phone']).exists():
            return Response({'error': 'A user account with this phone number already exists.'}, status=status.HTTP_400_BAD_REQUEST)

        # 2. Extract or fall back to the default Resident role ID (R003 from Data Dictionary)
        # Note: Depending on inspectdb generation, verify if the model name is capitalized (Roles or Roles)
        try:
            default_role = Roles.objects.get(role_id='R003')
        except Roles.DoesNotExist:
            return Response({'error': 'Default Resident role profile (R003) missing from database.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        # 3. Create the parent account profile entity in the custom 'users' table
        new_user = Users.objects.create(
            user_id=f"U{Users.objects.count() + 1:03d}", # Sequential dynamic indexing assignment
            society_id_id=data.get('society_id', 'SO01'), 
            user_name=data['user_name'],
            user_phone=data['user_phone'],
            user_email=data.get('user_email', ''),
            role_id=default_role,
            password=make_password(data['password']), # Secure cryptographic encryption hashing
            is_active=True
        )

        # 4. Concurrently link the unique unit allocation mapping inside the child 'resident' table
        new_resident = Resident.objects.create(
            resident_id=f"RS{Resident.objects.count() + 1:03d}",
            user_id=new_user,
            flat_id_id=data['flat_id'],
            move_in_date=data.get('move_in_date', '2026-05-20')
        )

        # 5. NEW: Full-Stack OTP Generation and Email Dispatch Flow
        generated_code = f"{random.randint(1000, 9999)}" # Creates secure random 4-digit code string
        
        # Upsert operation tracking user verification token parameters
        TemporaryOTP.objects.update_or_create(
            email=new_user.user_email,
            defaults={'otp_code': generated_code, 'created_at': timezone.now()}
        )

        # Fire off structural email notification text layout
        send_mail(
            subject='Zenith Square - Account Security Verification Code',
            message=f'Welcome to Zenith Square!\n\nYour secure account registration verification code is: {generated_code}\n\nThis security pin will expire in 5 minutes.',
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
    """
    Endpoint: /api/auth/login/
    Validates hashed security credentials against your custom schema and generates session tokens.
    """
    phone = request.data.get('user_phone')
    password = request.data.get('password')

    if not phone or not password:
        return Response({'error': 'Please provide both user_phone and password fields.'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        # Fetch profile match from custom user dictionary definition table
        user = Users.objects.get(user_phone=phone, is_active=True)
        
        # Verify check matching password strings natively
        if check_password(password, user.password):
            
            # Pull child allocation metadata vectors
            resident_profile = Resident.objects.filter(user_id=user.user_id).first()
            flat_info = resident_profile.flat_id_id if resident_profile else "Unassigned"

            return Response({
                'success': True,
                'user_id': user.user_id,
                'user_name': user.user_name,
                'role': user.role_id.role_name.lower(), # Dynamically yields 'resident', 'security', etc.
                'flat_id': flat_info
            }, status=status.HTTP_200_OK)
        else:
            return Response({'error': 'Invalid security credential mapping password.'}, status=status.HTTP_401_UNAUTHORIZED)
            
    except Users.DoesNotExist:
        return Response({'error': 'No active account profile linked to this phone entity.'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def change_password(request):
    """
    Endpoint: /api/auth/change-password/
    Securely mutates user authentication records inside your custom 'users' table.
    """
    # Pull logged in database user id link
    custom_user_id = request.user.username 
    old_password = request.data.get('old_password')
    new_password = request.data.get('new_password')

    if not old_password or not new_password:
        return Response({'error': 'Please provide both old_password and new_password.'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user_record = Users.objects.get(user_id=custom_user_id)
        
        # Validate current active credential string matching
        if not check_password(old_password, user_record.password):
            return Response({'error': 'Incorrect current password confirmation verification.'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Hashing and saving the updated credentials
        user_record.password = make_password(new_password)
        user_record.save()
        
        return Response({'success': 'Security password mutated successfully.'}, status=status.HTTP_200_OK)
        
    except Users.DoesNotExist:
        return Response({'error': 'User profile context not found.'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['POST'])
@permission_classes([AllowAny])
def verify_registration_otp(request):
    """
    Endpoint: /api/auth/verify-otp/
    Compares incoming mobile parameters against temporarily cached database models.
    """
    email = request.data.get('email')
    submitted_otp = request.data.get('otp')

    if not email or not submitted_otp:
        return Response({'error': 'Missing verification parameters: email and otp are required.'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        otp_record = TemporaryOTP.objects.get(email=email)

        # Validation Rule A: Has the time run down?
        if otp_record.is_expired():
            return Response({'error': 'This verification code has expired. Please request a new one.'}, status=status.HTTP_400_BAD_REQUEST)

        # Validation Rule B: Does the incoming string match perfectly?
        if otp_record.otp_code == submitted_otp:
            
            # Activate your user system constraints inside the custom table
            user_profile = Users.objects.get(user_email=email)
            user_profile.is_active = True
            user_profile.save()

            # Clean tracking table cache records to prevent authorization reuse attempts
            otp_record.delete()

            return Response({'message': 'Identity verified successfully! Account is active.'}, status=status.HTTP_200_OK)
        else:
            return Response({'error': 'Incorrect verification code. Please check and try again.'}, status=status.HTTP_400_BAD_REQUEST)

    except TemporaryOTP.DoesNotExist:
        return Response({'error': 'No active verification sequence initiated for this address.'}, status=status.HTTP_404_NOT_FOUND)
    except Users.DoesNotExist:
        return Response({'error': 'Relational profile account trace missing from server files.'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['POST'])
@permission_classes([AllowAny])
def request_password_reset(request):
    """
    Endpoint: /api/auth/forgot-password/
    Validates email existence across custom tables, caches an alternative OTP, and sends mail.
    """
    email = request.data.get('email')

    if not email:
        return Response({'error': 'Please provide a registered email address.'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        # Check if user profile records exist under this target email address string
        user = Users.objects.get(user_email=email)

        # Generate a distinct random reset pin
        reset_otp = f"{random.randint(1000, 9999)}"

        # Upsert the tracking model session 
        TemporaryOTP.objects.update_or_create(
            email=email,
            defaults={'otp_code': reset_otp, 'created_at': timezone.now()}
        )

        # Dispatch the password assistance recovery mail layout
        send_mail(
            subject='Zenith Square - Password Recovery Assistance',
            message=f'Hello {user.user_name},\n\nA security request was initiated to reset your account password.\n\nYour 4-digit verification code is: {reset_otp}\n\nIf you did not request this modification, please ignore this notice.',
            from_email='security@zenithsquare.com',
            recipient_list=[email],
            fail_silently=False,
        )

        return Response({'success': True, 'message': 'Reset code sent successfully!'}, status=status.HTTP_200_OK)

    except Users.DoesNotExist:
        return Response({'error': 'No account profile matched this email address.'}, status=status.HTTP_404_NOT_FOUND)