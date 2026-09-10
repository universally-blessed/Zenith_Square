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
    visitor_name = serializers.CharField(source='visitor.visitor_name', read_only=True)
    visitor_phone = serializers.CharField(source='visitor.visitor_phone', read_only=True)
    flat_number = serializers.CharField(source='flat.flat_number', read_only=True)
    block_name = serializers.CharField(source='flat.block.block_name', read_only=True)
    recorded_by_name = serializers.CharField(source='recorded_by.user_name', read_only=True)

    class Meta:
        model = VisitorLogs
        fields = [
            'log_id',
            'visitor_id',
            'visitor_name',
            'visitor_phone',
            'flat_number',
            'block_name',
            'entry_time',
            'exit_time',
            'purpose',
            'recorded_by_name',
        ]
        read_only_fields = ['log_id', 'entry_time', 'recorded_by_name']


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