# accounts/views.py

import random

from django.conf import settings
from django.core.mail import send_mail

from rest_framework.decorators import api_view
from rest_framework.response import Response

from .models import *
from .serializers import *


@api_view(['GET'])
def home(request):

    return Response({
        "message": "Zenith Square API Working"
    })


@api_view(['POST'])
def register(request):

    email = request.data.get('email')

    if User.objects.filter(email=email).exists():

        return Response({
            "error": "Email already exists"
        })

    serializer = UserSerializer(data=request.data)

    if serializer.is_valid():

        serializer.save()

        otp = str(random.randint(1000, 9999))

        OTP.objects.create(
            email=email,
            otp=otp
        )

        try:

            send_mail(
            'OTP Verification',
            f'Your OTP is {otp}',
            settings.EMAIL_HOST_USER,
            [email],
            fail_silently=False,
            )

        except Exception as e:

            return Response({
        "error": str(e)
        })

        return Response({

            "message": "Registration Successful",

            "otp_sent": True
        })

    return Response(serializer.errors)


@api_view(['POST'])
def verify_otp(request):

    email = request.data.get('email')

    otp = request.data.get('otp')

    try:

        OTP.objects.filter(
            email=email,
            otp=otp
        ).latest('created_at')

        user = User.objects.get(email=email)

        user.is_verified = True

        user.save()

        return Response({

            "message": "OTP Verified"
        })

    except:

        return Response({

            "error": "Invalid OTP"
        })


@api_view(['POST'])
def login(request):

    email = request.data.get('email')

    password = request.data.get('password')

    try:

        user = User.objects.get(email=email)

        if not user.is_verified:

            return Response({
                "error": "Email not verified"
            })

        if user.password != password:

            return Response({
                "error": "Invalid Password"
            })

        return Response({

            "message": "Login Success",

            "role": user.role,

            "full_name": user.full_name,

            "email": user.email
        })

    except User.DoesNotExist:

        return Response({
            "error": "Invalid Email"
        })
@api_view(['POST'])
def forgot_password(request):

    email = request.data.get('email')

    try:

        user = User.objects.get(email=email)

        otp = str(random.randint(1000, 9999))

        OTP.objects.create(
            email=email,
            otp=otp
        )

        try:

            send_mail(
                'Forgot Password OTP',
                f'Your OTP is {otp}',
                settings.EMAIL_HOST_USER,
                [email],
                fail_silently=False,
            )

        except Exception as e:

            return Response({
                "error": str(e)
            })

        return Response({
            "message": "OTP Sent"
        })

    except User.DoesNotExist:

        return Response({
            "error": "Email not found"
        })

@api_view(['POST'])
def verify_forgot_otp(request):

    email = request.data.get('email')

    otp = request.data.get('otp')

    try:

        OTP.objects.filter(
            email=email,
            otp=otp
        ).latest('created_at')

        return Response({
            "message": "OTP Verified"
        })

    except:

        return Response({
            "error": "Invalid OTP"
        })


@api_view(['POST'])
def reset_password(request):

    email = request.data.get('email')

    password = request.data.get('password')

    try:

        user = User.objects.get(email=email)

        user.password = password

        user.save()

        return Response({
            "message": "Password Updated"
        })

    except:

        return Response({
            "error": "User not found"
        })