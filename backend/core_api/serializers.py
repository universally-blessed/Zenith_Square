from rest_framework import serializers
from django.contrib.auth.hashers import make_password
from .models import (
    Societies, Blocks, Flats, Roles, Users, Resident, Tenant,
    Vehicle, Complaint, Amenity, AmenityBooking, Notice, 
    MaintenanceBill, SocietyExpenses, LostFoundItem, Polls, 
    PollsOption, PollsResponse, Meeting, SecurityAlerts
)

# ==========================================
# 🏢 1. STRUCTURAL CORE SERIALIZERS
# ==========================================
class SocietySerializer(serializers.ModelSerializer):
    class Meta:
        model = Societies
        fields = '__all__'

class BlockSerializer(serializers.ModelSerializer):
    class Meta:
        model = Blocks
        fields = '__all__'

class FlatSerializer(serializers.ModelSerializer):
    block_name = serializers.CharField(source='block_id.block_name', read_only=True)
    
    class Meta:
        model = Flats
        fields = ['flat_id', 'block_id', 'block_name', 'flat_number', 'floor_number']

# ==========================================
# 🔐 2. AUTHENTICATION & IDENTITY SERIALIZERS
# ==========================================
class RoleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Roles
        fields = '__all__'

class UserProfileSerializer(serializers.ModelSerializer):
    role_name = serializers.CharField(source='role_id.role_name', read_only=True)
    society_name = serializers.CharField(source='society_id.society_name', read_only=True)

    class Meta:
        model = Users
        fields = ['user_id', 'society_id', 'society_name', 'user_name', 'user_phone', 'user_email', 'role_id', 'role_name', 'is_active']

# ==========================================
# 🚗 3. FLEET & INFRASTRUCTURE SERIALIZERS
# ==========================================
class VehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = ['vehicle_id', 'resident_id', 'vehicle_number', 'vehicle_type', 'vehicle_allotment_number']
        read_only_fields = ['vehicle_id', 'resident_id']

# ==========================================
# 🛠️ 4. FEEDBACK & BROADCAST SERIALIZERS
# ==========================================
class ComplaintSerializer(serializers.ModelSerializer):
    resident_name = serializers.CharField(source='resident_id.user_id.user_name', read_only=True)
    
    class Meta:
        model = Complaint
        fields = ['complaint_id', 'resident_id', 'resident_name', 'block_id', 'title', 'description', 'status', 'created_at']
        read_only_fields = ['complaint_id', 'resident_id', 'status', 'created_at']

class NoticeSerializer(serializers.ModelSerializer):
    creator_name = serializers.CharField(source='created_by.user_name', read_only=True)

    class Meta:
        model = Notice
        fields = ['notice_id', 'society_id', 'block_id', 'title', 'description', 'created_by', 'creator_name', 'created_at']

class MeetingSerializer(serializers.ModelSerializer):
    organizer_name = serializers.CharField(source='organized_by.user_name', read_only=True)

    class Meta:
        model = Meeting
        fields = ['meeting_id', 'title', 'agenda', 'meeting_date', 'start_time', 'location', 'organized_by', 'organizer_name', 'minutes_doc']

# ==========================================
# 📅 5. AMENITY & RESERVATION SERIALIZERS
# ==========================================
class AmenitySerializer(serializers.ModelSerializer):
    class Meta:
        model = Amenity
        fields = '__all__'

class AmenityBookingSerializer(serializers.ModelSerializer):
    amenity_name = serializers.CharField(source='amenity_id.amenity_name', read_only=True)
    resident_name = serializers.CharField(source='resident_id.user_id.user_name', read_only=True)

    class Meta:
        model = AmenityBooking
        fields = ['booking_id', 'amenity_id', 'amenity_name', 'resident_id', 'resident_name', 'booking_date', 'start_time', 'end_time', 'status', 'payment_deadline', 'payment_id']
        read_only_fields = ['booking_id', 'resident_id', 'status', 'payment_deadline']

# ==========================================
# 💳 6. FINANCIAL MANAGEMENT SERIALIZERS
# ==========================================
class MaintenanceBillSerializer(serializers.ModelSerializer):
    payer_name = serializers.CharField(source='payer_id.user_name', read_only=True)
    flat_number = serializers.CharField(source='flat_id.flat_number', read_only=True)

    class Meta:
        model = MaintenanceBill
        fields = ['bill_id', 'flat_id', 'flat_number', 'payer_id', 'payer_name', 'bill_month', 'payable_amount', 'due_date', 'status']
        read_only_fields = ['bill_id', 'status']

class SocietyExpensesSerializer(serializers.ModelSerializer):
    class Meta:
        model = SocietyExpenses
        fields = ['expense_id', 'society_id', 'expense_type', 'amount', 'payment_date', 'description']
        read_only_fields = ['expense_id', 'society_id']

# ==========================================
# 🔍 7. MISPLACED BULLETIN SERIALIZERS
# ==========================================
class LostFoundItemSerializer(serializers.ModelSerializer):
    reporter_name = serializers.CharField(source='reported_by.user_name', read_only=True)

    class Meta:
        model = LostFoundItem
        fields = ['item_id', 'item_name', 'item_description', 'item_status', 'reported_by', 'reporter_name', 'handled_by', 'item_location', 'reported_date']
        read_only_fields = ['item_id', 'reported_by', 'reported_date']

# ==========================================
# 📊 8. CONSULTATION POLL SERIALIZERS
# ==========================================
class PollsOptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = PollsOption
        fields = ['option_id', 'poll_id', 'option_text']

class PollsSerializer(serializers.ModelSerializer):
    options = PollsOptionSerializer(many=True, read_only=True, source='polls_option_set') # Reverse relation hook

    class Meta:
        model = Polls
        fields = ['poll_id', 'poll_title', 'poll_description', 'created_by', 'end_date', 'status', 'options']

class PollsResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = PollsResponse
        fields = ['response_id', 'poll_id', 'option_id', 'user_id', 'voted_at']
        read_only_fields = ['response_id', 'user_id', 'voted_at']


class SecurityAlertsSerializer(serializers.ModelSerializer):
    triggered_by_name = serializers.CharField(source='triggered_by.user_name', read_only=True)

    class Meta:
        model = SecurityAlerts
        fields = ['alert_id', 'alert_type', 'description', 'status', 'created_at', 'triggered_by', 'triggered_by_name']