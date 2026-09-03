from rest_framework import serializers
from .models import Admin, Societies, SocietyFeatures, Users, Roles, CommitteeChange,Occupancy,Tenant

class AdminLoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

class SocietySerializer(serializers.ModelSerializer):
    class Meta:
        model = Societies
        fields = '__all__'

class SocietyFeaturesSerializer(serializers.ModelSerializer):
    class Meta:
        model = SocietyFeatures
        fields = '__all__'

class UserManagementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Users
        fields = ['user_id', 'society_id', 'user_name', 'user_phone', 'user_email', 'role_id', 'is_active']
        extra_kwargs = {'password': {'write_only': True}}

class CommitteeChangeSerializer(serializers.ModelSerializer):
    requested_by_name = serializers.CharField(source='requested_by.user_name', read_only=True, default='-')
    target_user_name = serializers.CharField(source='target_user.user_name', read_only=True, default='-')
    society_name = serializers.CharField(source='target_user.society.society_name', read_only=True, default='-')
    new_role_name = serializers.CharField(source='new_role.role_name', read_only=True, default='-')

    class Meta:
        model = CommitteeChange
        fields = '__all__'

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
        fields = ['occupancy_id', 'flat_id', 'resident_id', 'resident_name', 'flat_number', 'block_name', 'occupancy_type', 'is_primary']

class TenantSerializer(serializers.ModelSerializer):
    tenant_name = serializers.CharField(source='user.user_name', read_only=True, default='-')
    owner_name = serializers.CharField(source='owner.user_name', read_only=True, default='-')
    flat_number = serializers.CharField(source='flat.flat_number', read_only=True, default='-')

    class Meta:
        model = Tenant
        fields = '__all__'