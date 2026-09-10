import re
from decimal import Decimal
from rest_framework import serializers
from .models import (
    Admin, 
    Societies, 
    SocietyFeatures, 
    Users, 
    Roles, 
    CommitteeChange, 
    Occupancy, 
    Tenant
)


class AdminLoginSerializer(serializers.Serializer):
    email = serializers.EmailField(
        error_messages={
            'required': 'Admin email address is required.',
            'blank': 'Email cannot be blank.',
            'invalid': 'Enter a valid email address.'
        }
    )
    password = serializers.CharField(
        write_only=True,
        error_messages={'required': 'Password is required.', 'blank': 'Password cannot be blank.'}
    )


class SocietySerializer(serializers.ModelSerializer):
    society_name = serializers.CharField(
        max_length=100,
        min_length=2,
        trim_whitespace=True,
        error_messages={
            'required': 'Society name is required.',
            'blank': 'Society name cannot be blank.',
            'min_length': 'Society name must be at least 2 characters.'
        }
    )
    society_address = serializers.CharField(
        min_length=5,
        trim_whitespace=True,
        error_messages={
            'required': 'Society address is required.',
            'blank': 'Address cannot be blank.',
            'min_length': 'Address must be at least 5 characters.'
        }
    )
    society_city = serializers.CharField(
        max_length=50,
        min_length=2,
        trim_whitespace=True,
        error_messages={'required': 'City is required.', 'blank': 'City cannot be blank.'}
    )
    society_pincode = serializers.CharField(
        max_length=10,
        min_length=6,
        trim_whitespace=True,
        error_messages={'required': 'Pincode is required.', 'blank': 'Pincode cannot be blank.'}
    )
    society_email = serializers.EmailField(
        required=False,
        allow_blank=True,
        allow_null=True,
        error_messages={'invalid': 'Enter a valid society email address.'}
    )
    society_phone = serializers.CharField(
        max_length=15,
        min_length=10,
        trim_whitespace=True,
        error_messages={'required': 'Contact phone is required.', 'blank': 'Phone number cannot be blank.'}
    )
    standard_rate = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        min_value=Decimal('0.00'),
        error_messages={
            'required': 'Standard maintenance rate is required.',
            'min_value': 'Maintenance rate cannot be negative.'
        }
    )
    late_fee_percent = serializers.DecimalField(
        max_digits=5,
        decimal_places=2,
        required=False,
        allow_null=True,
        min_value=Decimal('0.00'),
        max_value=Decimal('100.00'),
        error_messages={
            'min_value': 'Late fee percentage cannot be negative.',
            'max_value': 'Late fee percentage cannot exceed 100%.'
        }
    )
    billing_cycle = serializers.ChoiceField(
        choices=['Monthly', 'Quarterly', 'Yearly'],
        default='Monthly',
        error_messages={'invalid_choice': 'Billing cycle must be Monthly, Quarterly, or Yearly.'}
    )
    society_status = serializers.ChoiceField(
        choices=['active', 'inactive'],
        default='active'
    )

    class Meta:
        model = Societies
        fields = '__all__'

    def validate_society_phone(self, value):
        cleaned = re.sub(r'[^0-9]', '', value)
        if not re.match(r'^[6-9]\d{9}$', cleaned):
            raise serializers.ValidationError('Enter a valid 10-digit mobile number (starts with 6-9).')
        return cleaned

    def validate_society_pincode(self, value):
        cleaned = value.strip()
        if not re.match(r'^[1-9][0-9]{5}$', cleaned):
            raise serializers.ValidationError('Enter a valid 6-digit Indian PIN code.')
        return cleaned

    def validate_society_city(self, value):
        cleaned = value.strip()
        if not re.match(r'^[a-zA-Z\s]+$', cleaned):
            raise serializers.ValidationError('City name must only contain alphabetic letters and spaces.')
        return cleaned


class SocietyFeaturesSerializer(serializers.ModelSerializer):
    class Meta:
        model = SocietyFeatures
        fields = '__all__'


class UserManagementSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(
        max_length=100,
        min_length=2,
        trim_whitespace=True,
        error_messages={
            'required': 'User name is required.',
            'blank': 'User name cannot be blank.',
            'min_length': 'Name must be at least 2 characters.'
        }
    )
    user_phone = serializers.CharField(
        max_length=10,
        min_length=10,
        trim_whitespace=True,
        error_messages={
            'required': 'Mobile number is required.',
            'blank': 'Mobile number cannot be blank.',
            'max_length': 'Mobile number must be exactly 10 digits.',
            'min_length': 'Mobile number must be exactly 10 digits.'
        }
    )
    user_email = serializers.EmailField(
        required=False,
        allow_blank=True,
        allow_null=True,
        error_messages={'invalid': 'Enter a valid email address.'}
    )

    class Meta:
        model = Users
        fields = ['user_id', 'society', 'user_name', 'user_phone', 'user_email', 'role', 'is_active']
        extra_kwargs = {'password': {'write_only': True, 'required': False}}

    def validate_user_phone(self, value):
        if not re.match(r'^[6-9]\d{9}$', value):
            raise serializers.ValidationError('Enter a valid 10-digit mobile number (starts with 6-9).')
        return value


class CommitteeChangeSerializer(serializers.ModelSerializer):
    requested_by_name = serializers.CharField(source='requested_by.user_name', read_only=True, default='Super Admin')
    target_user_name = serializers.CharField(source='target_user.user_name', read_only=True, default='-')
    society_name = serializers.CharField(source='target_user.society.society_name', read_only=True, default='-')
    new_role_name = serializers.CharField(source='new_role.role_name', read_only=True, default='-')

    class Meta:
        model = CommitteeChange
        fields = '__all__'
        read_only_fields = ['request_id', 'status']


class RoleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Roles
        fields = '__all__'


class OccupancySerializer(serializers.ModelSerializer):
    resident_name = serializers.CharField(source='resident.user.user_name', read_only=True, default='-')
    flat_number = serializers.CharField(source='flat.flat_number', read_only=True, default='-')
    block_name = serializers.CharField(source='flat.block.block_name', read_only=True, default='-')

    class Meta:
        model = Occupancy
        fields = ['occupancy_id', 'flat', 'resident', 'resident_name', 'flat_number', 'block_name', 'occupancy_type', 'is_primary']


class TenantSerializer(serializers.ModelSerializer):
    tenant_name = serializers.CharField(source='user.user_name', read_only=True, default='-')
    owner_name = serializers.CharField(source='owner.user_name', read_only=True, default='-')
    flat_number = serializers.CharField(source='flat.flat_number', read_only=True, default='-')
    status = serializers.ChoiceField(
        choices=['active', 'inactive', 'terminated', 'evicted'],
        default='active'
    )

    class Meta:
        model = Tenant
        fields = '__all__'