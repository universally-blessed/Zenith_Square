from rest_framework import serializers
from .models import Notice

from rest_framework import serializers
from .models import Notice

class NoticeSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source='created_by.user_name', read_only=True)
    block_name = serializers.CharField(source='block.block_name', read_only=True, default='All Blocks')
    society_name = serializers.CharField(source='society.society_name', read_only=True)

    class Meta:
        model = Notice
        fields = [
            'notice_id',
            'title',
            'description',
            'priority',
            'block_id',
            'block_name',
            'society_name',
            'author_name',
            'created_at',
            'is_active',
        ]
        read_only_fields = ['notice_id', 'created_at', 'author_name', 'society_name', 'block_name']


class CreateNoticeSerializer(serializers.Serializer):
    title = serializers.CharField(
        max_length=150,
        min_length=3,
        trim_whitespace=True,
        error_messages={
            'required': 'Notice title is required.',
            'blank': 'Notice title cannot be empty.',
            'min_length': 'Notice title must be at least 3 characters long.',
            'max_length': 'Notice title cannot exceed 150 characters.'
        }
    )
    description = serializers.CharField(
        min_length=10,
        trim_whitespace=True,
        error_messages={
            'required': 'Notice description is required.',
            'blank': 'Notice description cannot be empty.',
            'min_length': 'Notice description must be at least 10 characters long.'
        }
    )
    priority = serializers.ChoiceField(
        choices=['low', 'normal', 'high', 'urgent'],
        default='normal',
        error_messages={
            'invalid_choice': 'Priority must be one of: low, normal, high, urgent.'
        }
    )
    block_id = serializers.CharField(
        max_length=5,
        required=False,
        allow_null=True,
        allow_blank=True,
        trim_whitespace=True
    )