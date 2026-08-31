from rest_framework import serializers
from django.utils import timezone
from .models import Amenity, AmenityBooking, Asset, AssetMaintenance,Vehicle

class AmenitySerializer(serializers.ModelSerializer):
    class Meta:
        model = Amenity
        fields = ['amenity_id', 'amenity_name', 'amenity_location', 'amenity_capacity', 'amenity_status']
        read_only_fields = ['amenity_id']

class AmenityBookingSerializer(serializers.ModelSerializer):
    amenity_name = serializers.CharField(source='amenity.amenity_name', read_only=True)
    resident_name = serializers.CharField(source='resident.user.user_name', read_only=True)
    flat_number = serializers.CharField(source='resident.flat.flat_number', read_only=True)
    is_payment_expired = serializers.SerializerMethodField()

    class Meta:
        model = AmenityBooking
        fields = [
            'booking_id',
            'amenity_id',
            'amenity_name',
            'resident_name',
            'flat_number',
            'booking_date',
            'start_time',
            'end_time',
            'status',
            'payment_deadline',
            'payment_id',
            'is_payment_expired',
        ]
        read_only_fields = ['booking_id', 'status', 'payment_deadline', 'payment_id']

    def get_is_payment_expired(self, obj):
            if obj.status == 'pending_payment' and obj.payment_deadline:
                deadline = obj.payment_deadline
                if timezone.is_naive(deadline):
                    deadline = timezone.make_aware(deadline, timezone.get_current_timezone())
                return timezone.now() > deadline
            return False

class CreateAmenityBookingSerializer(serializers.Serializer):
    amenity_id = serializers.CharField(max_length=6)
    booking_date = serializers.DateField()
    start_time = serializers.TimeField()
    end_time = serializers.TimeField()


class ConfirmBookingPaymentSerializer(serializers.Serializer):
    payment_id = serializers.CharField(max_length=5, required=False, allow_blank=True)


class AssetSerializer(serializers.ModelSerializer):
    class Meta:
        model = Asset
        fields = ['asset_id', 'asset_name', 'asset_type', 'asset_location', 'purchase_date']
        read_only_fields = ['asset_id']


class AssetMaintenanceSerializer(serializers.ModelSerializer):
    asset_name = serializers.CharField(source='asset.asset_name', read_only=True)

    class Meta:
        model = AssetMaintenance
        fields = ['maintenance_id', 'asset_id', 'asset_name', 'description', 'maintenance_date', 'maintenance_cost', 'recorded_by']
        read_only_fields = ['maintenance_id', 'recorded_by']


class AssetSerializer(serializers.ModelSerializer):
    class Meta:
        model = Asset
        fields = ['asset_id', 'asset_name', 'asset_type', 'asset_location', 'purchase_date']
        read_only_fields = ['asset_id']


class AssetMaintenanceSerializer(serializers.ModelSerializer):
    asset_name = serializers.CharField(source='asset.asset_name', read_only=True)

    class Meta:
        model = AssetMaintenance
        fields = ['maintenance_id', 'asset_id', 'asset_name', 'description', 'maintenance_date', 'maintenance_cost', 'recorded_by']
        read_only_fields = ['maintenance_id', 'recorded_by']

class VehicleSerializer(serializers.ModelSerializer):
    resident_name = serializers.CharField(source='resident.user.user_name', read_only=True)
    flat_number = serializers.CharField(source='resident.flat.flat_number', read_only=True)

    class Meta:
        model = Vehicle
        fields = [
            'vehicle_id',
            'resident_name',
            'flat_number',
            'vehicle_number',
            'vehicle_type',
            'vehicle_allotment_number',
        ]
        read_only_fields = ['vehicle_id']