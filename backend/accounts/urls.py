# accounts/urls.py

from django.urls import path
from .views import *

urlpatterns = [

    path('', home),

    path('register/', register),

    path('verify-otp/', verify_otp),

    path('login/', login),

    path('forgot-password/', forgot_password),

    path('verify-forgot-otp/', verify_forgot_otp),

    path('reset-password/', reset_password),
]