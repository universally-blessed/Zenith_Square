# accounts/models.py

from django.db import models


class User(models.Model):

    ROLE_CHOICES = (
        ('resident', 'Resident'),
        ('chairman', 'Chairman'),
        ('secretary', 'Secretary'),
        ('block_secretary', 'Block Secretary'),
        ('treasurer', 'Treasurer'),
        ('security', 'Security'),
    )

    full_name = models.CharField(max_length=100)

    email = models.EmailField(unique=True)

    mobile = models.CharField(max_length=10)

    society_name = models.CharField(max_length=100)

    block = models.CharField(max_length=50)

    flat_number = models.CharField(max_length=20)

    password = models.CharField(max_length=100)

    role = models.CharField(
        max_length=30,
        choices=ROLE_CHOICES,
        default='resident'
    )

    is_verified = models.BooleanField(default=False)

    def __str__(self):
        return self.email


class OTP(models.Model):

    email = models.EmailField()

    otp = models.CharField(max_length=4)

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.email