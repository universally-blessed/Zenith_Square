from rest_framework import serializers
from .models import Societies, Blocks, Users, Nominee, Resident, Flats

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
    name = serializers.CharField(max_length=100)
    phone = serializers.CharField(max_length=10)
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)
    flatId = serializers.CharField(max_length=20)
    societyId = serializers.CharField(max_length=5)


# 1. Profile Serializer (Read & Update)
class UserProfileSerializer(serializers.ModelSerializer):
    society_id = serializers.CharField(source='society.society_id', read_only=True)
    society_name = serializers.CharField(source='society.society_name', read_only=True)
    role_name = serializers.CharField(source='role.role_name', read_only=True)
    flat_number = serializers.SerializerMethodField()
    block_name = serializers.SerializerMethodField()

    class Meta:
        model = Users
        fields = [
            'user_id',
            'user_name',
            'user_phone',
            'user_email',
            'society_id',      # <--- Added here
            'society_name',
            'role_name',
            'flat_number',
            'block_name',
        ]
        read_only_fields = ['user_id', 'user_phone', 'society_id']

    def get_flat_number(self, obj):
        resident = Resident.objects.filter(user=obj).first()
        return resident.flat.flat_number if (resident and resident.flat) else None

    def get_block_name(self, obj):
        resident = Resident.objects.filter(user=obj).first()
        return resident.flat.block.block_name if (resident and resident.flat and resident.flat.block) else None


# 2. Change Password Serializer
class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True)


# 3. Nominee Serializer (CRUD)
class NomineeSerializer(serializers.ModelSerializer):
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