import re
import datetime
from decimal import Decimal
from rest_framework import serializers
from django.utils import timezone
from .models import Amenity, AmenityBooking, Asset, AssetMaintenance, Vehicle

class AmenitySerializer(serializers.ModelSerializer):
    amenity_name = serializers.CharField(
        max_length=100,
        min_length=2,
        trim_whitespace=True,
        error_messages={
            'required': 'Amenity name is required.',
            'blank': 'Amenity name cannot be blank.',
            'min_length': 'Amenity name must be at least 2 characters.'
        }
    )
    amenity_location = serializers.CharField(
        max_length=100,
        min_length=2,
        trim_whitespace=True,
        error_messages={
            'required': 'Location is required.',
            'blank': 'Location cannot be blank.'
        }
    )
    amenity_capacity = serializers.IntegerField(
        min_value=1,
        error_messages={
            'required': 'Capacity is required.',
            'min_value': 'Capacity must be at least 1 person.'
        }
    )
    amenity_status = serializers.ChoiceField(
        choices=['available', 'maintenance', 'unavailable'],
        default='available'
    )

    class Meta:
        model = Amenity
        fields = ['amenity_id', 'amenity_name', 'amenity_location', 'amenity_capacity', 'amenity_status']
        read_only_fields = ['amenity_id']


class AmenityBookingSerializer(serializers.ModelSerializer):
    amenity_name = serializers.CharField(source='amenity.amenity_name', read_only=True)
    resident_name = serializers.CharField(source='resident.user.user_name', read_only=True)
    flat_number = serializers.CharField(source='resident.flat.flat_number', read_only=True)
    start_time = serializers.SerializerMethodField()
    end_time = serializers.SerializerMethodField()
    is_payment_expired = serializers.SerializerMethodField()
    formatted_deadline = serializers.SerializerMethodField()

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
            'formatted_deadline',
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

    def get_formatted_deadline(self, obj):
        if obj.payment_deadline:
            deadline = obj.payment_deadline
            if timezone.is_naive(deadline):
                deadline = timezone.make_aware(deadline, timezone.get_current_timezone())
            # Converts the UTC database value into your local timezone (IST)
            local_dt = timezone.localtime(deadline)
            return local_dt.strftime('%I:%M %p, %d %b')
        return '--'
    def get_start_time(self, obj):
        return obj.start_time.strftime('%H:%M') if obj.start_time else ''

    def get_end_time(self, obj):
        return obj.end_time.strftime('%H:%M') if obj.end_time else ''


class CreateAmenityBookingSerializer(serializers.Serializer):
    amenity_id = serializers.CharField(
        max_length=6,
        error_messages={'required': 'Amenity selection is required.'}
    )
    booking_date = serializers.DateField(
        error_messages={'required': 'Booking date is required.', 'invalid': 'Enter valid date (YYYY-MM-DD).'}
    )
    start_time = serializers.TimeField(
        error_messages={'required': 'Start time is required.', 'invalid': 'Enter valid time (HH:MM).'}
    )
    end_time = serializers.TimeField(
        error_messages={'required': 'End time is required.', 'invalid': 'Enter valid time (HH:MM).'}
    )

    def validate_booking_date(self, value):
        if value < datetime.date.today():
            raise serializers.ValidationError('Booking date cannot be scheduled in the past.')
        return value

    def validate(self, data):
        if data['start_time'] >= data['end_time']:
            raise serializers.ValidationError({'end_time': 'End time must be after start time.'})
        return data


class ConfirmBookingPaymentSerializer(serializers.Serializer):
    payment_id = serializers.CharField(max_length=50, required=False, allow_blank=True)
    amount = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        min_value=Decimal('0.01'),
        error_messages={
            'required': 'Paid amount is required to confirm booking.',
            'min_value': 'Amount must be greater than zero.',
        }
    )


class AssetSerializer(serializers.ModelSerializer):
    asset_name = serializers.CharField(
        max_length=100,
        min_length=2,
        trim_whitespace=True,
        error_messages={
            'required': 'Asset name is required.',
            'blank': 'Asset name cannot be blank.'
        }
    )
    asset_type = serializers.CharField(
        max_length=50,
        min_length=2,
        trim_whitespace=True,
        error_messages={
            'required': 'Asset category/type is required.',
            'blank': 'Category cannot be blank.'
        }
    )
    asset_location = serializers.CharField(
        max_length=100,
        min_length=2,
        trim_whitespace=True,
        error_messages={
            'required': 'Asset location is required.',
            'blank': 'Location cannot be blank.'
        }
    )
    purchase_date = serializers.DateField(
        error_messages={'required': 'Purchase date is required.'}
    )

    class Meta:
        model = Asset
        fields = ['asset_id', 'asset_name', 'asset_type', 'asset_location', 'purchase_date']
        read_only_fields = ['asset_id']

    def validate_purchase_date(self, value):
        if value > datetime.date.today():
            raise serializers.ValidationError('Purchase date cannot be set in the future.')
        return value


class AssetMaintenanceSerializer(serializers.ModelSerializer):
    asset_name = serializers.CharField(source='asset.asset_name', read_only=True)
    description = serializers.CharField(
        min_length=5,
        trim_whitespace=True,
        error_messages={
            'required': 'Maintenance work description is required.',
            'blank': 'Description cannot be blank.',
            'min_length': 'Description must be at least 5 characters.'
        }
    )
    maintenance_cost = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        min_value=Decimal('0.01'),
        error_messages={
            'required': 'Maintenance cost is required.',
            'min_value': 'Maintenance cost must be greater than zero.'
        }
    )
    maintenance_date = serializers.DateField(
        error_messages={'required': 'Maintenance date is required.'}
    )

    class Meta:
        model = AssetMaintenance
        fields = ['maintenance_id', 'asset_id', 'asset_name', 'description', 'maintenance_date', 'maintenance_cost', 'recorded_by']
        read_only_fields = ['maintenance_id', 'recorded_by']


class VehicleSerializer(serializers.ModelSerializer):
    resident_name = serializers.CharField(source='resident.user.user_name', read_only=True)
    flat_number = serializers.CharField(source='resident.flat.flat_number', read_only=True)
    vehicle_number = serializers.CharField(
        max_length=20,
        min_length=6,
        trim_whitespace=True,
        error_messages={
            'required': 'Vehicle plate number is required.',
            'blank': 'Plate number cannot be blank.'
        }
    )
    vehicle_type = serializers.ChoiceField(
        choices=['2-Wheeler', '4-Wheeler', 'Other'],
        error_messages={'invalid_choice': 'Type must be 2-Wheeler, 4-Wheeler, or Other.'}
    )
    vehicle_allotment_number = serializers.CharField(
        max_length=50,
        min_length=2,
        trim_whitespace=True,
        error_messages={
            'required': 'Parking slot / tag number is required.',
            'blank': 'Allotment slot cannot be blank.'
        }
    )

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

    def validate_vehicle_number(self, value):
        cleaned = re.sub(r'[^A-Za-z0-9]', '', value).upper()
        if len(cleaned) < 6 or len(cleaned) > 12:
            raise serializers.ValidationError('Enter a valid vehicle registration number (e.g. GJ01AB1234).')
        return cleaned