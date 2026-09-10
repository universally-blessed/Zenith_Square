import datetime
from decimal import Decimal
from rest_framework import serializers
from core_api.models import Resident, Occupancy
from .models import (
    Meeting,
    SocietyCommittee,
    CommitteeChange,
    Polls,
    PollsOption,
    PollsResponse,
    LostFoundItem,
    Tenant,
)


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
    title = serializers.CharField(
        max_length=150,
        min_length=3,
        trim_whitespace=True,
        error_messages={
            'required': 'Meeting title is required.',
            'blank': 'Meeting title cannot be blank.',
            'min_length': 'Meeting title must be at least 3 characters.',
        }
    )
    agenda = serializers.CharField(
        min_length=5,
        trim_whitespace=True,
        error_messages={
            'required': 'Meeting agenda is required.',
            'blank': 'Agenda cannot be blank.',
            'min_length': 'Please provide more details for the agenda (at least 5 characters).',
        }
    )
    meeting_date = serializers.DateField(
        error_messages={'required': 'Meeting date is required.', 'invalid': 'Enter a valid date (YYYY-MM-DD).'}
    )
    start_time = serializers.TimeField(
        error_messages={'required': 'Start time is required.', 'invalid': 'Enter a valid time (HH:MM).'}
    )
    location = serializers.CharField(
        max_length=100,
        min_length=2,
        trim_whitespace=True,
        error_messages={
            'required': 'Meeting venue/location is required.',
            'blank': 'Location cannot be blank.',
        }
    )
    minutes_doc = serializers.CharField(required=False, allow_blank=True, allow_null=True)

    def validate_meeting_date(self, value):
        if value < datetime.date.today():
            raise serializers.ValidationError('Meeting date cannot be scheduled in the past.')
        return value


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
    requested_by_name = serializers.SerializerMethodField()
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

    def get_requested_by_name(self, obj):
        if obj.requested_by and obj.requested_by.user_name:
            return obj.requested_by.user_name
        return "Admin"


class CreateCommitteeChangeRequestSerializer(serializers.Serializer):
    target_user_id = serializers.CharField(
        max_length=5,
        min_length=1,
        trim_whitespace=True,
        error_messages={'required': 'Target resident is required.', 'blank': 'Target resident cannot be empty.'}
    )
    new_role_id = serializers.CharField(
        max_length=5,
        min_length=1,
        trim_whitespace=True,
        error_messages={'required': 'Proposed role is required.', 'blank': 'Proposed role cannot be empty.'}
    )


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
    poll_title = serializers.CharField(
        max_length=150,
        min_length=5,
        trim_whitespace=True,
        error_messages={
            'required': 'Poll question/title is required.',
            'blank': 'Poll title cannot be blank.',
            'min_length': 'Poll title must be at least 5 characters.',
        }
    )
    poll_description = serializers.CharField(
        min_length=5,
        trim_whitespace=True,
        error_messages={
            'required': 'Poll description is required.',
            'blank': 'Description cannot be blank.',
        }
    )
    end_date = serializers.DateField(
        error_messages={'required': 'Poll end date is required.', 'invalid': 'Enter a valid date (YYYY-MM-DD).'}
    )
    options = serializers.ListField(
        child=serializers.CharField(max_length=100, trim_whitespace=True),
        min_length=2,
        max_length=6,
        error_messages={
            'required': 'Poll options are required.',
            'min_length': 'A poll requires at least 2 options.',
            'max_length': 'A poll cannot have more than 6 options.',
        }
    )

    def validate_end_date(self, value):
        if value <= datetime.date.today():
            raise serializers.ValidationError('Poll end date must be in the future.')
        return value

    def validate_options(self, value):
        cleaned_options = [opt.strip() for opt in value if opt and opt.strip()]
        if len(cleaned_options) < 2:
            raise serializers.ValidationError('Please provide at least 2 non-empty options.')
        if len(cleaned_options) != len(set(cleaned_options)):
            raise serializers.ValidationError('Poll options must be distinct and unique.')
        return cleaned_options


class CastVoteSerializer(serializers.Serializer):
    poll_id = serializers.CharField(max_length=6, error_messages={'required': 'Poll ID is required.'})
    option_id = serializers.CharField(max_length=5, error_messages={'required': 'Selected option is required.'})


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
    item_name = serializers.CharField(
        max_length=100,
        min_length=2,
        trim_whitespace=True,
        error_messages={
            'required': 'Item name is required.',
            'blank': 'Item name cannot be blank.',
        }
    )
    item_description = serializers.CharField(
        min_length=5,
        trim_whitespace=True,
        error_messages={
            'required': 'Item description is required.',
            'blank': 'Please describe the item.',
        }
    )
    item_status = serializers.ChoiceField(
        choices=['Lost', 'Found'],
        error_messages={'invalid_choice': "Status must be either 'Lost' or 'Found'."}
    )
    item_location = serializers.CharField(
        max_length=100,
        min_length=2,
        trim_whitespace=True,
        error_messages={
            'required': 'Location is required.',
            'blank': 'Please specify where the item was found or lost.',
        }
    )


class TenantSerializer(serializers.ModelSerializer):
    tenant_name = serializers.CharField(source='user.user_name', read_only=True)
    tenant_phone = serializers.CharField(source='user.user_phone', read_only=True)
    tenant_email = serializers.CharField(source='user.user_email', read_only=True)
    owner_name = serializers.CharField(source='owner.user_name', read_only=True)
    flat_number = serializers.CharField(source='flat.flat_number', read_only=True)
    block_name = serializers.CharField(source='flat.block.block_name', read_only=True)

    class Meta:
        model = Tenant
        fields = [
            'tenant_id',
            'user',
            'tenant_name',
            'tenant_phone',
            'tenant_email',
            'flat',
            'flat_number',
            'block_name',
            'owner',
            'owner_name',
            'custom_maintenance',
            'status',
            'move_in_date',
            'move_out_date',
        ]
        read_only_fields = ['tenant_id', 'status']


class CreateTenantSerializer(serializers.Serializer):
    tenant_name = serializers.CharField(
        max_length=100,
        min_length=2,
        trim_whitespace=True,
        error_messages={
            'required': 'Tenant full name is required.',
            'blank': 'Tenant name cannot be blank.',
        }
    )
    tenant_phone = serializers.CharField(
        max_length=10,
        min_length=10,
        trim_whitespace=True,
        error_messages={
            'required': 'Tenant 10-digit mobile number is required.',
            'blank': 'Phone number cannot be blank.',
            'max_length': 'Phone number must be exactly 10 digits.',
            'min_length': 'Phone number must be exactly 10 digits.',
        }
    )
    tenant_email = serializers.EmailField(
        required=False,
        allow_blank=True,
        allow_null=True,
        error_messages={'invalid': 'Enter a valid email address.'}
    )
    flat_id = serializers.CharField(
        max_length=5,
        error_messages={'required': 'Target flat is required.'}
    )
    owner_id = serializers.CharField(max_length=5, required=False, allow_blank=True, allow_null=True)
    custom_maintenance = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        required=False,
        allow_null=True,
        min_value=Decimal('0.00'),
        error_messages={'min_value': 'Maintenance amount cannot be negative.'}
    )
    move_in_date = serializers.DateField(
        error_messages={'required': 'Move-in date is required.', 'invalid': 'Enter a valid date (YYYY-MM-DD).'}
    )

    def validate_tenant_phone(self, value):
        if not value.isdigit() or len(value) != 10:
            raise serializers.ValidationError('Enter a valid 10-digit numeric contact number.')
        return value


class ResidentMemberSerializer(serializers.ModelSerializer):
    user_id = serializers.CharField(source='user.user_id', read_only=True)
    user_name = serializers.CharField(source='user.user_name', read_only=True)
    user_phone = serializers.CharField(source='user.user_phone', read_only=True)
    user_email = serializers.CharField(source='user.user_email', read_only=True)
    role_name = serializers.CharField(source='user.role.role_name', read_only=True)
    flat_id = serializers.CharField(source='flat.flat_id', read_only=True)
    flat_number = serializers.CharField(source='flat.flat_number', read_only=True)
    block_id = serializers.CharField(source='flat.block.block_id', read_only=True)
    block_name = serializers.CharField(source='flat.block.block_name', read_only=True)
    occupancy_type = serializers.SerializerMethodField()

    class Meta:
        model = Resident
        fields = [
            'resident_id',
            'user_id',
            'user_name',
            'user_phone',
            'user_email',
            'role_name',
            'flat_id',
            'flat_number',
            'block_id',
            'block_name',
            'occupancy_type',
            'move_in_date',
        ]

    def get_occupancy_type(self, obj):
        occ = Occupancy.objects.filter(resident=obj, flat=obj.flat).first()
        return occ.occupancy_type if occ else 'Owner'