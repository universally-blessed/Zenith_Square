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
    title = serializers.CharField(max_length=150)
    description = serializers.CharField()
    priority = serializers.CharField(max_length=10, default='normal')
    block_id = serializers.CharField(max_length=5, required=False, allow_null=True, allow_blank=True)