from rest_framework import serializers
from .models import Meeting, SocietyCommittee, CommitteeChange, Polls,PollsOption,PollsResponse,LostFoundItem

class MeetingSerializer(serializers.ModelSerializer):
    organizer_name = serializers.CharField(source='organized_by.user_name', read_only=True)

    class Meta:
        model = Meeting
        fields = [
            'meeting_id',
            'title',
            'agenda',
            'meeting_date',
            'start_time',
            'location',
            'organized_by',
            'organizer_name',
            'minutes_doc',
        ]
        read_only_fields = ['meeting_id', 'organized_by', 'organizer_name']


class CreateMeetingSerializer(serializers.Serializer):
    title = serializers.CharField(max_length=150)
    agenda = serializers.CharField()
    meeting_date = serializers.DateField()
    start_time = serializers.TimeField()
    location = serializers.CharField(max_length=100)
    minutes_doc = serializers.CharField(required=False, allow_blank=True, allow_null=True)


class SocietyCommitteeSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.user_name', read_only=True)
    user_phone = serializers.CharField(source='user.user_phone', read_only=True)
    role_name = serializers.CharField(source='role.role_name', read_only=True)

    class Meta:
        model = SocietyCommittee
        fields = [
            'committee_id',
            'user_id',
            'user_name',
            'user_phone',
            'society_id',
            'role_id',
            'role_name',
            'election_date',
            'term_end',
            'status',
        ]
        read_only_fields = ['committee_id', 'user_name', 'user_phone', 'role_name']


class CommitteeChangeSerializer(serializers.ModelSerializer):
    requested_by_name = serializers.CharField(source='requested_by.user_name', read_only=True)
    target_user_name = serializers.CharField(source='target_user.user_name', read_only=True)
    new_role_name = serializers.CharField(source='new_role.role_name', read_only=True)

    class Meta:
        model = CommitteeChange
        fields = [
            'request_id',
            'requested_by',
            'requested_by_name',
            'target_user',
            'target_user_name',
            'new_role',
            'new_role_name',
            'admin',
            'status',
        ]
        read_only_fields = ['request_id', 'requested_by', 'admin', 'status']


class CreateCommitteeChangeRequestSerializer(serializers.Serializer):
    target_user_id = serializers.CharField(max_length=5)
    new_role_id = serializers.CharField(max_length=5)

class PollOptionSerializer(serializers.ModelSerializer):
    votes_count = serializers.SerializerMethodField()

    class Meta:
        model = PollsOption
        fields = ['option_id', 'option_text', 'votes_count']

    def get_votes_count(self, obj):
        return PollsResponse.objects.filter(option=obj).count()


class PollSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.user_name', read_only=True)
    options = PollOptionSerializer(many=True, read_only=True)
    total_votes = serializers.SerializerMethodField()
    has_voted = serializers.SerializerMethodField()
    user_voted_option_id = serializers.SerializerMethodField()

    class Meta:
        model = Polls
        fields = [
            'poll_id',
            'poll_title',
            'poll_description',
            'created_by_name',
            'end_date',
            'status',
            'options',
            'total_votes',
            'has_voted',
            'user_voted_option_id',
        ]

    def get_total_votes(self, obj):
        return PollsResponse.objects.filter(poll=obj).count()

    def get_has_voted(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return PollsResponse.objects.filter(poll=obj, user=request.user).exists()
        return False

    def get_user_voted_option_id(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            vote = PollsResponse.objects.filter(poll=obj, user=request.user).first()
            return vote.option.option_id if vote and vote.option else None
        return None


class CreatePollSerializer(serializers.Serializer):
    poll_title = serializers.CharField(max_length=150)
    poll_description = serializers.CharField()
    end_date = serializers.DateField()
    options = serializers.ListField(
        child=serializers.CharField(max_length=100),
        min_length=2,
        max_length=6
    )


class CastVoteSerializer(serializers.Serializer):
    poll_id = serializers.CharField(max_length=6)
    option_id = serializers.CharField(max_length=5)

class LostFoundItemSerializer(serializers.ModelSerializer):
    reported_by_name = serializers.CharField(source='reported_by.user_name', read_only=True)
    handled_by_name = serializers.CharField(source='handled_by.user_name', read_only=True)

    class Meta:
        model = LostFoundItem
        fields = [
            'item_id',
            'item_name',
            'item_description',
            'item_status',
            'reported_by',
            'reported_by_name',
            'handled_by',
            'handled_by_name',
            'item_location',
            'reported_date',
        ]
        read_only_fields = ['item_id', 'reported_by', 'handled_by', 'reported_date']


class CreateLostFoundItemSerializer(serializers.Serializer):
    item_name = serializers.CharField(max_length=100)
    item_description = serializers.CharField()
    item_status = serializers.ChoiceField(choices=['Lost', 'Found'])
    item_location = serializers.CharField(max_length=100)