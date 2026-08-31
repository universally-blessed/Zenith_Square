from rest_framework import serializers
from .models import Complaint, Feedback

class ComplaintSerializer(serializers.ModelSerializer):
    resident_name = serializers.CharField(source='resident.user.user_name', read_only=True)
    flat_number = serializers.CharField(source='resident.flat.flat_number', read_only=True)
    block_name = serializers.CharField(source='block.block_name', read_only=True)

    class Meta:
        model = Complaint
        fields = [
            'complaint_id',
            'resident_name',
            'flat_number',
            'block_name',
            'title',
            'description',
            'status',
            'created_at',
            'resolved_at',
        ]
        read_only_fields = ['complaint_id', 'status', 'created_at', 'resolved_at']


class CreateComplaintSerializer(serializers.Serializer):
    title = serializers.CharField(max_length=100)
    description = serializers.CharField()


class FeedbackSerializer(serializers.ModelSerializer):
    resident_name = serializers.CharField(source='resident.user.user_name', read_only=True)

    class Meta:
        model = Feedback
        fields = ['feedback_id', 'resident_name', 'feedback_text', 'rating', 'created_at']
        read_only_fields = ['feedback_id', 'created_at']