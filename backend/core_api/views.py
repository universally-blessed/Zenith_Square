from rest_framework.decorators import api_view, permission_classes, authentication_classes 
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authentication import TokenAuthentication
from rest_framework.authtoken.models import Token
from django.contrib.auth.hashers import make_password, check_password

# Direct imports from your auto-generated SQL model mappings from database.sql
from .models import Users, Resident, Roles

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

        # 4. Concurrently create the tracking link inside the child 'resident' table 
        new_resident = Resident.objects.create(
            resident_id=f"RS{Resident.objects.count() + 1:03d}",
            user_id=new_user,
            flat_id_id=data['flat_id'], # Maps to selected flat choice asset identifier
            move_in_date=data.get('move_in_date', '2026-05-20')
        )

        return Response({
            'success': 'Account system profiles constructed successfully.',
            'user_id': new_user.user_id,
            'resident_id': new_resident.resident_id
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