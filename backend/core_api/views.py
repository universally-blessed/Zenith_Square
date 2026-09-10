import uuid
import datetime
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
from django.contrib.auth import authenticate
from django.contrib.auth.models import update_last_login
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.permissions import IsAuthenticated

from .models import Societies, Blocks, Flats, Users, Resident, Roles, TemporaryOTP,Nominee,Occupancy,SocietyFeatures
from .serializers import SocietySerializer, BlockSerializer, RegisterResidentSerializer, UserProfileSerializer,ChangePasswordSerializer,NomineeSerializer

# 1. Operational Endpoints (Dropdowns)
class PublicSocietiesView(APIView):
    def get(self, request):
        societies = Societies.objects.filter(society_status='active')
        return Response(SocietySerializer(societies, many=True).data, status=status.HTTP_200_OK)

class PublicBlocksView(APIView):
    def get(self, request, society_id):
        blocks = Blocks.objects.filter(society_id=society_id)
        return Response(BlockSerializer(blocks, many=True).data, status=status.HTTP_200_OK)


# 2. Authentication Endpoints
class RegisterResidentView(APIView):
    def post(self, request):
        serializer = RegisterResidentSerializer(data=request.data)
        if not serializer.is_valid():
            first_err = next(iter(serializer.errors.values()))[0]
            return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data

        if Users.objects.filter(user_phone=data['phone']).exists():
            return Response({'success': False, 'error': 'Phone number already registered.'}, status=status.HTTP_400_BAD_REQUEST)

        if Users.objects.filter(user_email=data['email']).exists():
            return Response({'success': False, 'error': 'Email address already registered.'}, status=status.HTTP_400_BAD_REQUEST)

        # 1. Create User
        generated_user_id = str(uuid.uuid4())[:5].upper()
        default_role, _ = Roles.objects.get_or_create(role_id='R01', defaults={'role_name': 'resident'})

        user = Users.objects.create_user(
            user_id=generated_user_id,
            user_name=data['name'],
            user_phone=data['phone'],
            user_email=data['email'],
            society_id=data['societyId'],
            role=default_role,
            is_active=False
        )
        user.set_password(data['password'])
        user.save()

        # 2. Look up Flat (supports both block-based query and legacy formats)
        flat_number_val = data.get('flatNumber') or data.get('flatId', '')
        # Remove any stray 'A-' or 'B-' prefix if passed
        clean_flat_num = flat_number_val.split('-')[-1].strip()
        block_id_val = data.get('blockId')

        flat_obj = None
        if block_id_val:
            flat_obj = Flats.objects.filter(
                block_id=block_id_val,
                flat_number__in=[clean_flat_num, flat_number_val]
            ).first()

        # Fallback to direct flat_id or society-wide search if block wasn't matched
        if not flat_obj:
            flat_obj = Flats.objects.filter(
                flat_number__in=[clean_flat_num, flat_number_val],
                block__society_id=data['societyId']
            ).first() or Flats.objects.filter(flat_id=flat_number_val).first()

        if not flat_obj:
            return Response({
                'success': False, 
                'error': f'Flat {flat_number_val} could not be found in the selected block/society.'
            }, status=status.HTTP_404_NOT_FOUND)

        # 3. Create Resident
        resident = Resident.objects.create(
            resident_id=str(uuid.uuid4())[:6].upper(),
            user=user,
            flat=flat_obj,
            move_in_date=datetime.date.today()
        )

        # 4. Create Occupancy
        occupancy_type = data.get('occupancyType', 'Owner')
        # Check if a primary occupant already exists for this flat
        has_primary = Occupancy.objects.filter(flat=flat_obj, is_primary=True).exists()

        Occupancy.objects.create(
            occupancy_id=str(uuid.uuid4())[:5].upper(),
            flat=flat_obj,
            resident=resident,
            occupancy_type=occupancy_type,
            is_primary=not has_primary
        )

        # 5. Generate OTP
        otp_code = TemporaryOTP.generate_otp(data['email'])
        print(f"\n==========================================")
        print(f" [REGISTRATION OTP] {data['email']} -> {otp_code}")
        print(f"==========================================\n")

        return Response({
            'success': True,
            'message': 'Profile registered successfully! OTP code generated.'
        }, status=status.HTTP_201_CREATED)


class VerifyOTPView(APIView):
    def post(self, request):
        email = request.data.get('email')
        otp = request.data.get('otp')

        if not email or not otp:
            return Response({'success': False, 'error': 'Email and OTP are required.'}, status=status.HTTP_400_BAD_REQUEST)

        # 1. Combined lookup: validates both matching code and 10-minute validity in one query
        cutoff = timezone.now() - datetime.timedelta(minutes=10)
        record = TemporaryOTP.objects.filter(email=email, otp_code=otp, created_at__gte=cutoff).first()
        
        if not record:
            return Response({'success': False, 'error': 'Invalid or expired OTP code.'}, status=status.HTTP_400_BAD_REQUEST)

        # 2. Activate user
        user = Users.objects.filter(user_email=email).first()
        if user:
            user.is_active = True
            user.save()

        # 3. Clean up OTP to prevent replay
        record.delete()
        return Response({'success': True, 'message': 'Account verified successfully!'}, status=status.HTTP_200_OK)


class LoginView(APIView):
    def post(self, request):
        phone = request.data.get('phone')
        password = request.data.get('password')

        user = authenticate(request, user_phone=phone, password=password)
        if not user:
            return Response({'success': False, 'error': 'Invalid contact number or password.'}, status=status.HTTP_401_UNAUTHORIZED)

        if not user.is_active:
            return Response({'success': False, 'error': 'Account not verified. Please verify your OTP.'}, status=status.HTTP_403_FORBIDDEN)

        # Update last_login timestamp in users table
        update_last_login(None, user)

        refresh = RefreshToken.for_user(user)
        role_name = user.role.role_name.lower() if user.role else 'resident'

        return Response({
            'success': True,
            'role': role_name,
            'user_name': user.user_name,
            'access': str(refresh.access_token),
            'refresh': str(refresh)
        }, status=status.HTTP_200_OK)


class RequestPasswordResetView(APIView):
    def post(self, request):
        email = request.data.get('email')
        user = Users.objects.filter(user_email=email).first()
        if not user:
            return Response({'success': False, 'error': 'Email identity trace missing.'}, status=status.HTTP_404_NOT_FOUND)

        otp_code = TemporaryOTP.generate_otp(email)
        print(f"\n==========================================")
        print(f" [RESET OTP] {email} -> {otp_code}")
        print(f"==========================================\n")

        return Response({'success': True, 'message': 'Reset verification code sent to your inbox!'}, status=status.HTTP_200_OK)

class ConfirmPasswordResetView(APIView):
    def post(self, request):
        email = request.data.get('email')
        otp = request.data.get('otp')
        new_password = request.data.get('new_password')

        print(email,otp,new_password)
        if not email or not otp or not new_password:
            return Response({'success': False, 'error': 'Missing required fields.'}, status=status.HTTP_400_BAD_REQUEST)

        record = TemporaryOTP.objects.filter(email=email, otp_code=otp).first()
        if not record:
            return Response({'success': False, 'error': 'Invalid or expired OTP token.'}, status=status.HTTP_400_BAD_REQUEST)

        user = Users.objects.filter(user_email=email).first()
        if not user:
            return Response({'success': False, 'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

        user.set_password(new_password)
        user.save()
        record.delete()

        return Response({'success': True, 'message': 'Password reset successfully!'}, status=status.HTTP_200_OK)

# 1. Manage Profile (View & Update)
class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserProfileSerializer(request.user)
        return Response({'success': True, 'profile': serializer.data}, status=status.HTTP_200_OK)

    def put(self, request):
        user = request.user
        serializer = UserProfileSerializer(user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()

            # Update move_in_date if passed
            move_in_date = request.data.get('move_in_date')
            if move_in_date:
                resident = Resident.objects.filter(user=user).first()
                if resident:
                    resident.move_in_date = move_in_date
                    resident.save()

            return Response({
                'success': True,
                'message': 'Profile updated successfully!',
                'profile': UserProfileSerializer(user).data
            })
        first_err = next(iter(serializer.errors.values()))[0]
        return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)


# 2. Change Password
class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({'success': False, 'error': 'Invalid payload.'}, status=status.HTTP_400_BAD_REQUEST)

        user = request.user
        if not user.check_password(serializer.validated_data['old_password']):
            return Response({'success': False, 'error': 'Current password does not match.'}, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(serializer.validated_data['new_password'])
        user.save()
        return Response({'success': True, 'message': 'Password changed successfully!'}, status=status.HTTP_200_OK)


# 3. Nominee Management (View, Add & Update)
class NomineeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        features = SocietyFeatures.objects.filter(society=request.user.society).first()
        if features and features.has_nominee is False:
            return Response(
                {'success': False, 'error': 'Nominee management is disabled for your society.'}, 
                status=status.HTTP_403_FORBIDDEN
            )

        resident = Resident.objects.filter(user=request.user).first()
        if not resident:
            return Response({'success': True, 'nominee': None}, status=status.HTTP_200_OK)

        nominee = Nominee.objects.filter(resident=resident).first()
        if not nominee:
            return Response({'success': True, 'nominee': None}, status=status.HTTP_200_OK)

        serializer = NomineeSerializer(nominee)
        return Response({'success': True, 'nominee': serializer.data}, status=status.HTTP_200_OK)

    def post(self, request):
        features = SocietyFeatures.objects.filter(society=request.user.society).first()
        if features and features.has_nominee is False:
            return Response(
                {'success': False, 'error': 'Nominee management is disabled for your society.'}, 
                status=status.HTTP_403_FORBIDDEN
            )

        resident = Resident.objects.filter(user=request.user).first()
        if not resident:
            return Response(
                {'success': False, 'error': 'Cannot add nominee: No resident flat is assigned to this account.'}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        serializer = NomineeSerializer(data=request.data)
        if not serializer.is_valid():
            first_err = next(iter(serializer.errors.values()))[0]
            return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

        nominee = Nominee.objects.filter(resident=resident).first()
        if nominee:
            for key, val in serializer.validated_data.items():
                setattr(nominee, key, val)
            nominee.save()
        else:
            generated_nominee_id = str(uuid.uuid4())[:5].upper()
            nominee = Nominee.objects.create(
                nominee_id=generated_nominee_id,
                resident=resident,
                **serializer.validated_data
            )

        return Response({
            'success': True,
            'message': 'Nominee details saved successfully!',
            'nominee': NomineeSerializer(nominee).data
        }, status=status.HTTP_200_OK)