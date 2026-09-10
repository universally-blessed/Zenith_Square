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
    title = serializers.CharField(
        max_length=100,
        min_length=3,
        trim_whitespace=True,
        error_messages={
            'required': 'Complaint title/subject is required.',
            'blank': 'Title cannot be blank.',
            'min_length': 'Title must be at least 3 characters.',
            'max_length': 'Title cannot exceed 100 characters.'
        }
    )
    description = serializers.CharField(
        min_length=10,
        trim_whitespace=True,
        error_messages={
            'required': 'Detailed description is required.',
            'blank': 'Description cannot be blank.',
            'min_length': 'Please describe the issue in detail (at least 10 characters).'
        }
    )


class FeedbackSerializer(serializers.ModelSerializer):
    resident_name = serializers.CharField(source='resident.user.user_name', read_only=True)
    feedback_text = serializers.CharField(
        min_length=5,
        trim_whitespace=True,
        error_messages={
            'required': 'Feedback text is required.',
            'blank': 'Feedback cannot be blank.',
            'min_length': 'Feedback must be at least 5 characters.'
        }
    )
    rating = serializers.IntegerField(
        min_value=1,
        max_value=5,
        required=False,
        allow_null=True,
        error_messages={
            'min_value': 'Rating must be between 1 and 5.',
            'max_value': 'Rating must be between 1 and 5.'
        }
    )

    class Meta:
        model = Feedback
        fields = ['feedback_id', 'resident_name', 'feedback_text', 'rating', 'created_at']
        read_only_fields = ['feedback_id', 'created_at']