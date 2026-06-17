from .models import Vehicle,Resident,Complaint, AmenityBooking, Amenity, LostFoundItem
from datetime import datetime, timedelta
from django.utils import timezone

def get_resident_profile(user):
    return Resident.objects.filter(user_id=user.username).first()

def generate_vehicle_id():
    count = Vehicle.objects.count() + 1
    return f"V{count:05d}"

def add_vehicle_service(resident, data):
    vehicle = Vehicle.objects.create(
        vehicle_id=generate_vehicle_id(),
        resident=resident,
        vehicle_number=data['vehicle_number'],
        vehicle_type=data['vehicle_type'],
        vehicle_allotment_number=data.get('vehicle_allotment_number', '')
    )
    return vehicle


def create_complaint(resident, data):
    count = Complaint.objects.count() + 1
    return Complaint.objects.create(
        complaint_id=f"CM{count:03d}",
        resident=resident,
        title=data['title'],
        description=data['description'],
        status='pending'
    )

def check_booking_conflict(amenity_id, date, start_time, end_time):
    return AmenityBooking.objects.filter(
        amenity_id=amenity_id,
        booking_date=date,
        status__in=['pending', 'approved', 'approved_awaiting_payment']
    ).filter(start_time__lt=end_time, end_time__gt=start_time).exists()

def create_booking(resident, data, amenity, start_time, end_time):
    count = AmenityBooking.objects.count() + 1
    return AmenityBooking.objects.create(
        booking_id=f"BK{count:04d}",
        amenity=amenity,
        resident=resident,
        booking_date=data['booking_date'],
        start_time=start_time,
        end_time=end_time,
        status='pending',
        payment_deadline=timezone.now() + timedelta(minutes=60)
    )