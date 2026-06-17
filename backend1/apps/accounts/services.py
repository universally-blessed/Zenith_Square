from .models import Users,Resident,CoreApiTemporaryotp,Nominee
from django.contrib.auth.hashers import make_password,check_password #type: ignore
from django.conf import settings#type: ignore
from django.core.mail import send_mail#type: ignore
from django.utils import timezone#type: ignore
import random,string

def generate_user_id():
    """Generates a custom U001, U002 ID based on total count."""
    count = Users.objects.count() + 1
    return f"U{count:03d}"

def create_user_account(data):
    if Users.objects.filter(user_phone=data.get('user_phone')).exists():
        return None, "Phone number already registered."

    user = Users.objects.create(
        user_id=generate_user_id(),
        user_name=data['user_name'],
        user_phone=data['user_phone'],
        password=make_password(data['password']),
        is_active=False  # Must be false until OTP verified
    )
    # Trigger the OTP email immediately
    send_otp_email(data['user_email']) 
    return user, None

def verify_registration_service(email, otp_code):
    """Verifies OTP and activates the user account."""
    is_valid, error = verify_otp_service(email, otp_code)
    if is_valid:
        user = Users.objects.get(user_email=email)
        user.is_active = True
        user.save()
        return True, None
    return False, error

def authenticate_user_service(phone, password):
    try:
        user = Users.objects.get(user_phone=phone)
        if not user.is_active:
            return None, "Account not verified. Please verify your email OTP."
        if check_password(password, user.password):
            return user, None
        return None, "Invalid credentials."
    except Users.DoesNotExist:
        return None, "User not found."
    
def verify_otp_service(email, otp_code):
    """Checks if the OTP exists and is not expired (5 min validity)."""
    try:
        otp_record = CoreApiTemporaryotp.objects.get(email=email, otp_code=otp_code)
        if otp_record.is_expired():
            otp_record.delete()
            return False, "OTP expired."
        return True, None
    except CoreApiTemporaryotp.DoesNotExist:
        return False, "Invalid OTP."

def change_password_service(user, old_password, new_password):
    """Verifies old password before hashing and saving the new one."""
    if not user.check_password(old_password):
        return False, "Old password incorrect."
    
    user.set_password(new_password)
    user.save()
    return True, None

def forgot_password_service(phone):
    """Generates a temporary OTP and saves it to the DB."""
    try:
        user = Users.objects.get(user_phone=phone)
        # Generate a 4-digit numeric OTP
        otp = ''.join(random.choices(string.digits, k=4))
        
        # Save or update the OTP record linked to user's email
        # Assuming Users model has an email field
        CoreApiTemporaryotp.objects.update_or_create(
            email=user.user_email,
            defaults={'otp_code': otp, 'created_at': timezone.now()}
        )
        return otp, user.user_email, None
    except Users.DoesNotExist:
        return None, None, "User not found."
    
def send_otp_email(email):
    """Generates and sends a 4-digit OTP to the provided email."""
    otp = ''.join(random.choices(string.digits, k=4))
    
    # Save to database
    CoreApiTemporaryotp.objects.update_or_create(
        email=email,
        defaults={'otp_code': otp}
    )
    
    # Dispatch Email
    send_mail(
        subject='Zenith Square Security Verification',
        message=f'Your verification code is: {otp}. This code expires in 5 minutes.',
        from_email=settings.EMAIL_HOST_USER,
        recipient_list=[email],
        fail_silently=False,
    )
    return otp # Return for internal tracking if needed

def get_resident_dashboard_data(user_id):
    """Aggregates profile and unit information for the dashboard."""
    user = Users.objects.get(user_id=user_id)
    resident_profile = Resident.objects.filter(user_id=user.user_id).first()
    
    # Safely navigate the relationships
    flat = resident_profile.flat if resident_profile else None
    block = flat.block if flat else None
    
    return {
        'user_name': user.user_name,
        'society_name': user.society.society_name if user.society else "Zenith Square",
        'unit_info': f"{block.block_name if block else 'N/A'} - {flat.flat_number if flat else 'N/A'}",
        'email': user.user_email,
        'phone': user.user_phone
    }
def update_user_profile(user_id, phone, email):
    user = Users.objects.get(user_id=user_id)
    # Check for phone uniqueness
    if Users.objects.filter(user_phone=phone).exclude(user_id=user_id).exists():
        return False, "Phone already registered."
    
    user.user_phone = phone
    user.user_email = email
    user.save()
    return True, None

def upsert_resident_nominee(resident, data):
    nominee, created = Nominee.objects.update_or_create(
        resident_id=resident.resident_id,
        defaults={
            'nominee_name': data['nominee_name'],
            'relation': data['relation'],
            'phone': data['phone'],
            'address': data['address']
        }
    )
    if created:
        nominee.nominee_id = f"NM{Nominee.objects.count():03d}"
        nominee.save()
    return nominee