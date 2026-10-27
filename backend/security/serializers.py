import re
from rest_framework import serializers
from .models import SecurityAlerts, Visitor, VisitorLogs

class SecurityAlertSerializer(serializers.ModelSerializer):
    triggered_by_name = serializers.CharField(source='triggered_by.user_name', read_only=True)
    triggered_by_phone = serializers.CharField(source='triggered_by.user_phone', read_only=True)

    class Meta:
        model = SecurityAlerts
        fields = [
            'alert_id',
            'alert_type',
            'description',
            'status',
            'triggered_by_name',
            'triggered_by_phone',
            'created_at',
        ]
        read_only_fields = ['alert_id', 'status', 'created_at']


class TriggerAlertSerializer(serializers.Serializer):
    alert_type = serializers.ChoiceField(
        choices=[
            'Medical Emergency',
            'Fire Emergency',
            'Lift Stuck',
            'Theft / Intruder',
            'Other Emergency',
        ],
        error_messages={'invalid_choice': 'Invalid emergency category.'}
    )
    description = serializers.CharField(
        min_length=5,
        max_length=500,
        trim_whitespace=True,
        error_messages={
            'required': 'Emergency details and location are required.',
            'blank': 'Please describe the emergency location or issue.',
            'min_length': 'Description must be at least 5 characters long.',
        }
    )


class VisitorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Visitor
        fields = ['visitor_id', 'visitor_name', 'visitor_phone']
        read_only_fields = ['visitor_id']


class VisitorLogSerializer(serializers.ModelSerializer):
    logs_id = serializers.IntegerField(source='log_id', read_only=True)
    visitor_name = serializers.CharField(source='visitor.visitor_name', read_only=True)
    visitor_phone = serializers.CharField(source='visitor.visitor_phone', read_only=True)
    flat_id = serializers.SerializerMethodField()
    flat_number = serializers.SerializerMethodField()
    block_name = serializers.SerializerMethodField()
    society_id = serializers.SerializerMethodField()
    society_name = serializers.SerializerMethodField()
    society_address = serializers.SerializerMethodField()
    recorded_by = serializers.CharField(source='recorded_by.user_id', read_only=True)
    recorded_by_name = serializers.CharField(source='recorded_by.user_name', read_only=True)
    resident_name = serializers.SerializerMethodField()
    resident_phone = serializers.SerializerMethodField()

    def get_resident_name(self, obj):
        if not obj.flat:
            return ''
        from core_api.models import Resident, Occupancy
        primary_occ = Occupancy.objects.filter(flat=obj.flat, is_primary=True).select_related('resident__user').first()
        if primary_occ and primary_occ.resident and primary_occ.resident.user:
            return primary_occ.resident.user.user_name
        res = Resident.objects.filter(flat=obj.flat, user__isnull=False).order_by('-move_in_date', '-resident_id').first()
        return res.user.user_name if (res and res.user) else ''

    def get_resident_phone(self, obj):
        if not obj.flat:
            return ''
        from core_api.models import Resident, Occupancy
        primary_occ = Occupancy.objects.filter(flat=obj.flat, is_primary=True).select_related('resident__user').first()
        if primary_occ and primary_occ.resident and primary_occ.resident.user:
            return primary_occ.resident.user.user_phone
        res = Resident.objects.filter(flat=obj.flat, user__isnull=False).order_by('-move_in_date', '-resident_id').first()
        return res.user.user_phone if (res and res.user) else ''

    def get_flat_id(self, obj):
        return obj.flat.flat_id if obj.flat else ''

    def get_flat_number(self, obj):
        return obj.flat.flat_number if obj.flat else ''

    def get_block_name(self, obj):
        return obj.flat.block.block_name if (obj.flat and obj.flat.block) else 'A'

    def get_society_id(self, obj):
        if obj.society:
            return obj.society.society_id
        if obj.flat and obj.flat.block and obj.flat.block.society:
            return obj.flat.block.society.society_id
        return 'SOC01'

    def get_society_name(self, obj):
        if obj.society:
            return obj.society.society_name
        if obj.flat and obj.flat.block and obj.flat.block.society:
            return obj.flat.block.society.society_name
        return 'Serene Heights'

    def get_society_address(self, obj):
        if obj.society:
            return obj.society.society_address
        if obj.flat and obj.flat.block and obj.flat.block.society:
            return obj.flat.block.society.society_address
        return 'Plot 45, Near Science City Road, Sola'

    class Meta:
        model = VisitorLogs
        fields = [
            'log_id',
            'logs_id',
            'visitor_id',
            'visitor_name',
            'visitor_phone',
            'flat_id',
            'flat_number',
            'block_name',
            'resident_name',
            'resident_phone',
            'society_id',
            'society_name',
            'society_address',
            'entry_time',
            'exit_time',
            'purpose',
            'recorded_by',
            'recorded_by_name',
        ]
        read_only_fields = ['log_id', 'logs_id', 'entry_time', 'recorded_by', 'recorded_by_name']


class LogVisitorEntrySerializer(serializers.Serializer):
    visitor_name = serializers.CharField(
        max_length=100,
        min_length=2,
        trim_whitespace=True,
        error_messages={
            'required': 'Visitor name is required.',
            'blank': 'Visitor name cannot be blank.',
            'min_length': 'Name must be at least 2 characters.',
        }
    )
    visitor_phone = serializers.CharField(
        max_length=10,
        min_length=10,
        trim_whitespace=True,
        error_messages={
            'required': 'Visitor phone number is required.',
            'blank': 'Phone number cannot be blank.',
            'max_length': 'Phone number must be exactly 10 digits.',
            'min_length': 'Phone number must be exactly 10 digits.',
        }
    )
    flat_id = serializers.CharField(
        max_length=5,
        error_messages={'required': 'Destination flat is required.'}
    )
    purpose = serializers.CharField(
        max_length=200,
        min_length=3,
        trim_whitespace=True,
        error_messages={
            'required': 'Visit purpose is required.',
            'blank': 'Purpose cannot be blank.',
        }
    )

    def validate_visitor_phone(self, value):
        if not re.match(r'^[6-9]\d{9}$', value):
            raise serializers.ValidationError('Enter a valid 10-digit mobile number.')
        return value