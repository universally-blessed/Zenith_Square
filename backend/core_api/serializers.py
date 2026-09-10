import re
from rest_framework import serializers
from .models import Societies, Blocks, Users, Nominee, Resident, Occupancy, SocietyFeatures

class SocietySerializer(serializers.ModelSerializer):
    id = serializers.CharField(source='society_id')
    name = serializers.CharField(source='society_name')

    class Meta:
        model = Societies
        fields = ['id', 'name']


class BlockSerializer(serializers.ModelSerializer):
    id = serializers.CharField(source='block_id')
    name = serializers.CharField(source='block_name')

    class Meta:
        model = Blocks
        fields = ['id', 'name']


class RegisterResidentSerializer(serializers.Serializer):
    name = serializers.CharField(
        max_length=100,
        min_length=2,
        trim_whitespace=True,
        error_messages={
            'required': 'Full name is required.',
            'blank': 'Full name cannot be blank.',
            'min_length': 'Name must be at least 2 characters long.',
        }
    )
    phone = serializers.CharField(
        max_length=10,
        min_length=10,
        trim_whitespace=True,
        error_messages={
            'required': 'Mobile number is required.',
            'blank': 'Mobile number cannot be blank.',
            'max_length': 'Mobile number must be exactly 10 digits.',
            'min_length': 'Mobile number must be exactly 10 digits.',
        }
    )
    email = serializers.EmailField(
        error_messages={
            'required': 'Email address is required.',
            'blank': 'Email cannot be blank.',
            'invalid': 'Enter a valid email address.',
        }
    )
    password = serializers.CharField(
        write_only=True,
        min_length=6,
        error_messages={
            'required': 'Password is required.',
            'min_length': 'Password must be at least 6 characters long.',
        }
    )
    societyId = serializers.CharField(
        max_length=5,
        error_messages={'required': 'Society selection is required.'}
    )
    blockId = serializers.CharField(max_length=5, required=False, allow_blank=True, allow_null=True)
    flatNumber = serializers.CharField(max_length=20, required=False, allow_blank=True, allow_null=True)
    flatId = serializers.CharField(max_length=20, required=False, allow_blank=True, allow_null=True)
    occupancyType = serializers.ChoiceField(
        choices=['Owner', 'Tenant'],
        default='Owner'
    )

    def validate_phone(self, value):
        if not re.match(r'^[6-9]\d{9}$', value):
            raise serializers.ValidationError('Enter a valid 10-digit Indian mobile number.')
        return value


# 1. Profile Serializer (Read & Update)
class UserProfileSerializer(serializers.ModelSerializer):
    society_id = serializers.CharField(source='society.society_id', read_only=True)
    society_name = serializers.CharField(source='society.society_name', read_only=True)
    role_name = serializers.CharField(source='role.role_name', read_only=True)
    flat_number = serializers.SerializerMethodField()
    block_name = serializers.SerializerMethodField()
    occupancy_type = serializers.SerializerMethodField()
    is_primary = serializers.SerializerMethodField()
    move_in_date = serializers.SerializerMethodField()
    has_nominee = serializers.SerializerMethodField()
    has_security = serializers.SerializerMethodField()

    user_name = serializers.CharField(
        max_length=100,
        min_length=2,
        trim_whitespace=True,
        error_messages={
            'required': 'Full name is required.',
            'blank': 'Full name cannot be blank.',
            'min_length': 'Name must be at least 2 characters long.',
        }
    )
    user_email = serializers.EmailField(
        error_messages={
            'required': 'Email address is required.',
            'blank': 'Email cannot be blank.',
            'invalid': 'Enter a valid email address.',
        }
    )

    class Meta:
        model = Users
        fields = [
            'user_id',
            'user_name',
            'user_phone',
            'user_email',
            'society_id',
            'society_name',
            'role_name',
            'flat_number',
            'block_name',
            'occupancy_type',
            'is_primary',
            'move_in_date',
            'has_nominee',
            'has_security',
        ]
        read_only_fields = ['user_id', 'user_phone', 'society_id']

    def get_flat_number(self, obj):
        resident = Resident.objects.filter(user=obj).first()
        return resident.flat.flat_number if (resident and resident.flat) else None

    def get_block_name(self, obj):
        resident = Resident.objects.filter(user=obj).first()
        return resident.flat.block.block_name if (resident and resident.flat and resident.flat.block) else None

    def get_occupancy_type(self, obj):
        occ = Occupancy.objects.filter(resident__user=obj).first()
        return occ.occupancy_type if occ else None

    def get_is_primary(self, obj):
        occ = Occupancy.objects.filter(resident__user=obj).first()
        return occ.is_primary if occ else False

    def get_move_in_date(self, obj):
        resident = Resident.objects.filter(user=obj).first()
        return resident.move_in_date if resident else None

    def get_has_nominee(self, obj):
        if not obj.society:
            return True
        config = SocietyFeatures.objects.filter(society=obj.society).first()
        return config.has_nominee if (config and config.has_nominee is not None) else True

    def get_has_security(self, obj):
        if not obj.society:
            return True
        config = SocietyFeatures.objects.filter(society=obj.society).first()
        return config.has_security if (config and config.has_security is not None) else True


# 2. Change Password Serializer
class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(
        required=True,
        error_messages={'required': 'Current password is required.'}
    )
    new_password = serializers.CharField(
        required=True,
        min_length=6,
        error_messages={
            'required': 'New password is required.',
            'min_length': 'New password must be at least 6 characters long.',
        }
    )

    def validate(self, data):
        if data['old_password'] == data['new_password']:
            raise serializers.ValidationError({'new_password': 'New password cannot be identical to current password.'})
        return data


# 3. Nominee Serializer (CRUD)
class NomineeSerializer(serializers.ModelSerializer):
    nominee_name = serializers.CharField(
        max_length=100,
        min_length=2,
        trim_whitespace=True,
        error_messages={
            'required': 'Nominee name is required.',
            'blank': 'Nominee name cannot be blank.',
            'min_length': 'Nominee name must be at least 2 characters.',
        }
    )
    relationship = serializers.CharField(
        max_length=50,
        min_length=2,
        trim_whitespace=True,
        error_messages={
            'required': 'Relationship is required.',
            'blank': 'Please specify the relationship.',
        }
    )
    phone = serializers.CharField(
        max_length=10,
        min_length=10,
        trim_whitespace=True,
        error_messages={
            'required': 'Nominee phone number is required.',
            'blank': 'Phone number cannot be blank.',
            'max_length': 'Phone number must be exactly 10 digits.',
            'min_length': 'Phone number must be exactly 10 digits.',
        }
    )
    email = serializers.EmailField(
        required=False,
        allow_blank=True,
        allow_null=True,
        error_messages={'invalid': 'Enter a valid email address.'}
    )
    address = serializers.CharField(
        min_length=5,
        trim_whitespace=True,
        error_messages={
            'required': 'Nominee address is required.',
            'blank': 'Address cannot be blank.',
            'min_length': 'Address must be at least 5 characters.',
        }
    )

    class Meta:
        model = Nominee
        fields = [
            'nominee_id',
            'nominee_name',
            'relationship',
            'phone',
            'email',
            'address',
        ]
        read_only_fields = ['nominee_id']

    def validate_phone(self, value):
        if not re.match(r'^[6-9]\d{9}$', value):
            raise serializers.ValidationError('Enter a valid 10-digit mobile number.')
        return value