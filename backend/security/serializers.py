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
    alert_type = serializers.CharField(max_length=50)
    description = serializers.CharField()


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
    visitor_name = serializers.CharField(max_length=100)
    visitor_phone = serializers.CharField(max_length=10)
    flat_id = serializers.CharField(max_length=5)
    purpose = serializers.CharField(max_length=200)