from rest_framework import serializers
from .models import Societies, Blocks, Users, Nominee, Resident, Occupancy,SocietyFeatures

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
    societyId = serializers.CharField(max_length=5)
    blockId = serializers.CharField(max_length=5, required=False)
    flatNumber = serializers.CharField(max_length=20, required=False)
    flatId = serializers.CharField(max_length=20, required=False)
    occupancyType = serializers.ChoiceField(
        choices=['Owner', 'Tenant'], 
        default='Owner'
    )


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

