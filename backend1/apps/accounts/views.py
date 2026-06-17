
# @api_view(['GET'])
# @authentication_classes([TokenAuthentication])
# @permission_classes([IsAuthenticated])
# def get_resident_dashboard_meta(request):
#     try:
#         data = get_resident_dashboard_data(request.user.username)
#         return Response(data, status=status.HTTP_200_OK)
#     except Exception as e:
#         return Response({'error': 'Profile context trace missing.'}, status=status.HTTP_404_NOT_FOUND)
    
# @api_view(['POST'])
# @authentication_classes([TokenAuthentication])
# @permission_classes([IsAuthenticated])
# def update_profile_details(request):
#     success, error = update_user_profile(
#         request.user.username, 
#         request.data.get('user_phone'), 
#         request.data.get('user_email')
#     )
#     if not success:
#         return Response({'error': error}, status=400)
#     return Response({'success': True, 'message': 'Profile updated.'})

# @api_view(['GET', 'POST'])
# @authentication_classes([TokenAuthentication])
# @permission_classes([IsAuthenticated])
# def manage_resident_nominee(request):
#     resident = Resident.objects.filter(user_id=request.user.username).first()
#     if not resident:
#         return Response({'error': 'Resident not found'}, status=404)

#     if request.method == 'GET':
#         nominee = Nominee.objects.filter(resident_id=resident.resident_id).first()
#         if not nominee: return Response({'no_nominee': True})
#         return Response({'nominee_name': nominee.nominee_name, 'relation': nominee.relation})

#     if request.method == 'POST':
#         upsert_resident_nominee(resident, request.data)
#         return Response({'success': True})
from rest_framework.decorators import api_view, permission_classes#type: ignore
from rest_framework.permissions import AllowAny, IsAuthenticated#type: ignore
from rest_framework.response import Response#type: ignore
from rest_framework import status#type: ignore
from rest_framework.authtoken.models import Token#type: ignore
from .services import (
    create_user_account, authenticate_user_service, verify_registration_service,
    change_password_service, send_otp_email
)

@api_view(['POST'])
@permission_classes([AllowAny])
def register_resident(request):
    user, error = create_user_account(request.data)
    if error:
        return Response({'success': False, 'error': error}, status=400)
    return Response({'success': True, 'data': {'user_id': user.user_id}}) #

@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    phone = request.data.get('user_phone')
    password = request.data.get('password')
    user, error = authenticate_user_service(phone, password)
    
    if error:
        return Response({'success': False, 'error': error}, status=status.HTTP_401_UNAUTHORIZED)
    
    token, _ = Token.objects.get_or_create(user=user)
    return Response({
        'success': True, 
        'role': getattr(user, 'role', 'resident'), #[cite: 15]
        'user_name': user.user_name, 
        'token': token.key 
    }, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([AllowAny])
def verify_registration_otp(request):
    success, error = verify_registration_service(request.data.get('email'), request.data.get('otp'))
    if not success:
        return Response({'success': False, 'error': error}, status=status.HTTP_400_BAD_REQUEST)
    return Response({'success': True, 'message': 'OTP verification accepted.'}) #

@api_view(['POST'])
@permission_classes([AllowAny])
def request_password_reset(request):
    email = request.data.get('email')
    # Trigger email flow
    send_otp_email(email)
    return Response({'success': True, 'message': 'Reset sequence initiated.'})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    success, error = change_password_service(request.user, request.data.get('old_password'), request.data.get('new_password'))
    if not success:
        return Response({'success': False, 'error': error}, status=400)
    return Response({'success': True})