import uuid
import datetime
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.permissions import IsAuthenticated

from .models import Societies, Blocks, Flats, Users, Resident, Roles, TemporaryOTP,Nominee
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

        # 2. Look up Flat
        flat_obj = Flats.objects.filter(flat_number=data['flatId']).first() or Flats.objects.filter(flat_id=data['flatId']).first()

        # 3. Create Resident with explicit move_in_date
        Resident.objects.create(
            resident_id=str(uuid.uuid4())[:6].upper(),
            user=user,
            flat=flat_obj,
            move_in_date=datetime.date.today()  # <--- Satisfies the NOT NULL constraint
        )

        # 4. Generate OTP
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

        record = TemporaryOTP.objects.filter(email=email, otp_code=otp).first()
        if not record:
            return Response({'success': False, 'error': 'Invalid or expired OTP code.'}, status=status.HTTP_400_BAD_REQUEST)

        user = Users.objects.filter(user_email=email).first()
        if user:
            user.is_active = True
            user.save()

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
            return Response({'success': True, 'message': 'Profile updated successfully!', 'profile': serializer.data})
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
        resident = Resident.objects.filter(user=request.user).first()
        if not resident:
            return Response({'success': False, 'error': 'Resident profile missing.'}, status=status.HTTP_404_NOT_FOUND)

        nominee = Nominee.objects.filter(resident=resident).first()
        if not nominee:
            return Response({'success': True, 'nominee': None}, status=status.HTTP_200_OK)

        serializer = NomineeSerializer(nominee)
        return Response({'success': True, 'nominee': serializer.data}, status=status.HTTP_200_OK)

    def post(self, request):
        resident = Resident.objects.filter(user=request.user).first()
        if not resident:
            return Response({'success': False, 'error': 'Resident profile missing.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = NomineeSerializer(data=request.data)
        if not serializer.is_valid():
            first_err = next(iter(serializer.errors.values()))[0]
            return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

        # Upsert Nominee (Update if already exists, else create new)
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