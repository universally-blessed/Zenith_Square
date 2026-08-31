import uuid
from datetime import timedelta
from django.utils import timezone
from django.db.models import Q
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from core_api.models import Resident
from .models import Amenity, AmenityBooking, Asset, AssetMaintenance,Vehicle
from .serializers import (
    AmenitySerializer,
    AmenityBookingSerializer,
    CreateAmenityBookingSerializer,
    ConfirmBookingPaymentSerializer,
    AssetSerializer,
    AssetMaintenanceSerializer,
    VehicleSerializer
)


def auto_expire_stale_bookings():
    AmenityBooking.objects.filter(
        status='pending_payment',
        payment_deadline__isnull=False,
        payment_deadline__lt=timezone.now()
    ).update(status='expired')


# 1. Amenities List & Creation
class AmenityListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        society = request.user.society
        amenities = Amenity.objects.filter(society=society)
        return Response({'success': True, 'amenities': AmenitySerializer(amenities, many=True).data}, status=status.HTTP_200_OK)

    def post(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = AmenitySerializer(data=request.data)
        if not serializer.is_valid():
            first_err = next(iter(serializer.errors.values()))[0]
            return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

        amenity = Amenity.objects.create(
            amenity_id=str(uuid.uuid4())[:6].upper(),
            society=request.user.society,
            **serializer.validated_data
        )
        return Response({'success': True, 'message': 'Amenity created!', 'amenity': AmenitySerializer(amenity).data}, status=status.HTTP_201_CREATED)


# 2. Book Amenity (Blocks for 1 Hour Under 'pending_payment')
class BookAmenityView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        # Clear any stale expired holds first
        auto_expire_stale_bookings()

        serializer = CreateAmenityBookingSerializer(data=request.data)
        if not serializer.is_valid():
            first_err = next(iter(serializer.errors.values()))[0]
            return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        resident = Resident.objects.filter(user=request.user).first()
        if not resident:
            return Response({'success': False, 'error': 'Resident profile missing.'}, status=status.HTTP_404_NOT_FOUND)

        amenity = Amenity.objects.filter(amenity_id=data['amenity_id'], society=request.user.society).first()
        if not amenity:
            return Response({'success': False, 'error': 'Amenity not found.'}, status=status.HTTP_404_NOT_FOUND)

        if amenity.amenity_status != 'available':
            return Response({'success': False, 'error': 'This amenity is currently unavailable.'}, status=status.HTTP_400_BAD_REQUEST)

        # Check for conflicts:
        # Overlapping bookings that are either 'confirmed' or currently held ('pending_payment' with valid deadline)
        overlap = AmenityBooking.objects.filter(
            amenity=amenity,
            booking_date=data['booking_date']
        ).filter(
            Q(status='confirmed') | (Q(status='pending_payment') & Q(payment_deadline__gte=timezone.now()))
        ).filter(
            Q(start_time__lt=data['end_time']) & Q(end_time__gt=data['start_time'])
        ).exists()

        if overlap:
            return Response({'success': False, 'error': 'This time slot is currently booked or held pending payment.'}, status=status.HTTP_400_BAD_REQUEST)

        deadline = timezone.now() + timedelta(hours=1)

        booking = AmenityBooking.objects.create(
            booking_id=str(uuid.uuid4())[:6].upper(),
            amenity=amenity,
            resident=resident,
            booking_date=data['booking_date'],
            start_time=data['start_time'],
            end_time=data['end_time'],
            status='pending_payment',
            payment_deadline=deadline
        )

        return Response({
            'success': True,
            'message': 'Amenity temporarily reserved! Please complete payment within 1 hour to confirm.',
            'booking': AmenityBookingSerializer(booking).data
        }, status=status.HTTP_201_CREATED)


# 3. View Bookings (Resident / Chairman)
class AmenityBookingsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        auto_expire_stale_bookings()
        role_name = request.user.role.role_name.lower() if request.user.role else 'resident'
        my_only = request.query_params.get('my', 'false').lower() == 'true'

        if my_only or role_name not in ['chairman', 'secretary', 'admin']:
            resident = Resident.objects.filter(user=request.user).first()
            bookings = AmenityBooking.objects.filter(resident=resident).order_by('-booking_date')
        else:
            bookings = AmenityBooking.objects.filter(amenity__society=request.user.society).order_by('-booking_date')

        return Response({'success': True, 'bookings': AmenityBookingSerializer(bookings, many=True).data}, status=status.HTTP_200_OK)


# 4. Confirm Payment (Chairman / Secretary verifies payment -> 'confirmed')
class ConfirmAmenityPaymentView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id):
        auto_expire_stale_bookings()
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized. Chairman/Secretary privilege required.'}, status=status.HTTP_403_FORBIDDEN)

        booking = AmenityBooking.objects.filter(booking_id=booking_id, amenity__society=request.user.society).first()
        if not booking:
            return Response({'success': False, 'error': 'Booking not found.'}, status=status.HTTP_404_NOT_FOUND)

        if booking.status == 'confirmed':
            return Response({'success': False, 'error': 'Booking is already confirmed.'}, status=status.HTTP_400_BAD_REQUEST)

        # Ensure timezone-aware comparison
        deadline = booking.payment_deadline
        if deadline and timezone.is_naive(deadline):
            deadline = timezone.make_aware(deadline, timezone.get_current_timezone())

        if booking.status == 'expired' or (deadline and timezone.now() > deadline):
            booking.status = 'expired'
            booking.save()
            return Response({'success': False, 'error': 'Cannot confirm: 1-hour payment window has expired.'}, status=status.HTTP_400_BAD_REQUEST)

        serializer = ConfirmBookingPaymentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        payment_ref = serializer.validated_data.get('payment_id') or str(uuid.uuid4())[:5].upper()

        booking.status = 'confirmed'
        booking.payment_id = payment_ref
        booking.save()

        return Response({
            'success': True,
            'message': 'Payment confirmed! Amenity booking is now officially locked.',
            'booking': AmenityBookingSerializer(booking).data
        }, status=status.HTTP_200_OK)

# 5. Cancel Booking (Chairman / Secretary cancels accidental bookings)
class CancelAmenityBookingView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, booking_id):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        booking = AmenityBooking.objects.filter(booking_id=booking_id, amenity__society=request.user.society).first()
        if not booking:
            return Response({'success': False, 'error': 'Booking not found.'}, status=status.HTTP_404_NOT_FOUND)

        booking.status = 'cancelled'
        booking.save()

        return Response({
            'success': True,
            'message': 'Booking has been cancelled and slot released.',
            'booking': AmenityBookingSerializer(booking).data
        }, status=status.HTTP_200_OK)
class AmenityStatusUpdateView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, amenity_id):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        amenity = Amenity.objects.filter(amenity_id=amenity_id, society=request.user.society).first()
        if not amenity:
            return Response({'success': False, 'error': 'Amenity not found.'}, status=status.HTTP_404_NOT_FOUND)

        new_status = request.data.get('amenity_status')
        if new_status not in ['available', 'maintenance', 'unavailable']:
            return Response({'success': False, 'error': 'Invalid amenity status.'}, status=status.HTTP_400_BAD_REQUEST)

        amenity.amenity_status = new_status
        amenity.save()
        return Response({'success': True, 'message': f'Status updated to {new_status}.', 'amenity': AmenitySerializer(amenity).data}, status=status.HTTP_200_OK)


# Asset Detail & Soft Deletion / Decommission
class AssetDetailDeleteView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, asset_id):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        asset = Asset.objects.filter(asset_id=asset_id, society=request.user.society).first()
        if not asset:
            return Response({'success': False, 'error': 'Asset not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Deletes the asset record or archives it
        asset.delete()
        return Response({'success': True, 'message': 'Asset removed successfully!'}, status=status.HTTP_200_OK)

# 6. Assets & Maintenance Handlers
class AssetListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        assets = Asset.objects.filter(society=request.user.society)
        return Response({'success': True, 'assets': AssetSerializer(assets, many=True).data}, status=status.HTTP_200_OK)

    def post(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = AssetSerializer(data=request.data)
        if not serializer.is_valid():
            first_err = next(iter(serializer.errors.values()))[0]
            return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

        asset = Asset.objects.create(
            asset_id=str(uuid.uuid4())[:5].upper(),
            society=request.user.society,
            **serializer.validated_data
        )
        return Response({'success': True, 'message': 'Asset registered successfully!', 'asset': AssetSerializer(asset).data}, status=status.HTTP_201_CREATED)


class AssetMaintenanceListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, asset_id):
        logs = AssetMaintenance.objects.filter(asset_id=asset_id, asset__society=request.user.society).order_by('-maintenance_date')
        return Response({'success': True, 'maintenance_logs': AssetMaintenanceSerializer(logs, many=True).data}, status=status.HTTP_200_OK)

    def post(self, request, asset_id):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        asset = Asset.objects.filter(asset_id=asset_id, society=request.user.society).first()
        if not asset:
            return Response({'success': False, 'error': 'Asset not found.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = AssetMaintenanceSerializer(data=request.data)
        if not serializer.is_valid():
            first_err = next(iter(serializer.errors.values()))[0]
            return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

        # 1. Look up the resident_id associated with the logged-in Chairman
        resident = Resident.objects.filter(user=request.user).first()
        recorded_by_id = resident.resident_id if resident else None

        # 2. Save using resident_id
        log = AssetMaintenance.objects.create(
            maintenance_id=str(uuid.uuid4())[:6].upper(),
            asset=asset,
            recorded_by=recorded_by_id,
            **serializer.validated_data
        )
        return Response({
            'success': True, 
            'message': 'Maintenance log recorded!', 
            'log': AssetMaintenanceSerializer(log).data
        }, status=status.HTTP_201_CREATED)

class VehicleListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else 'resident'
        all_society = request.query_params.get('all', 'false').lower() == 'true'

        if all_society:
            # Strictly restrict society-wide vehicle directory to chairman/secretary/admin
            if role_name not in ['chairman', 'secretary', 'admin']:
                return Response({
                    'success': False,
                    'error': 'Unauthorized. Chairman/Admin privilege required to view all society vehicles.'
                }, status=status.HTTP_403_FORBIDDEN)
            
            vehicles = Vehicle.objects.filter(resident__flat__block__society=request.user.society)
        else:
            # Default: Return only vehicles belonging to the logged-in resident
            resident = Resident.objects.filter(user=request.user).first()
            if not resident:
                return Response({'success': True, 'vehicles': []}, status=status.HTTP_200_OK)
            vehicles = Vehicle.objects.filter(resident=resident)

        return Response({
            'success': True,
            'vehicles': VehicleSerializer(vehicles, many=True).data
        }, status=status.HTTP_200_OK)

    def post(self, request):
        serializer = VehicleSerializer(data=request.data)
        if not serializer.is_valid():
            first_err = next(iter(serializer.errors.values()))[0]
            return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

        resident = Resident.objects.filter(user=request.user).first()
        if not resident:
            return Response({'success': False, 'error': 'Resident profile missing.'}, status=status.HTTP_404_NOT_FOUND)

        vehicle_num = serializer.validated_data['vehicle_number'].strip().upper()
        
        # Check duplicate registration within society
        if Vehicle.objects.filter(vehicle_number=vehicle_num, resident__flat__block__society=request.user.society).exists():
            return Response({'success': False, 'error': 'This vehicle number is already registered in this society.'}, status=status.HTTP_400_BAD_REQUEST)

        vehicle = Vehicle.objects.create(
            vehicle_id=str(uuid.uuid4())[:6].upper(),
            resident=resident,
            vehicle_number=vehicle_num,
            vehicle_type=serializer.validated_data['vehicle_type'],
            vehicle_allotment_number=serializer.validated_data['vehicle_allotment_number']
        )

        return Response({
            'success': True,
            'message': 'Vehicle registered successfully!',
            'vehicle': VehicleSerializer(vehicle).data
        }, status=status.HTTP_201_CREATED)


# 8. Vehicle Delete
class VehicleDetailDeleteView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, vehicle_id):
        role_name = request.user.role.role_name.lower() if request.user.role else 'resident'
        
        if role_name in ['chairman', 'secretary', 'admin']:
            vehicle = Vehicle.objects.filter(vehicle_id=vehicle_id, resident__flat__block__society=request.user.society).first()
        else:
            resident = Resident.objects.filter(user=request.user).first()
            vehicle = Vehicle.objects.filter(vehicle_id=vehicle_id, resident=resident).first()

        if not vehicle:
            return Response({'success': False, 'error': 'Vehicle not found or unauthorized.'}, status=status.HTTP_404_NOT_FOUND)

        vehicle.delete()
        return Response({'success': True, 'message': 'Vehicle removed successfully!'}, status=status.HTTP_200_OK)