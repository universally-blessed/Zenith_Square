from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
import datetime
from .models import Vehicle, Resident,Amenity
from .services import get_resident_profile, add_vehicle_service,create_complaint, check_booking_conflict, create_booking
from .serializers import VehicleSerializer

@api_view(['GET', 'POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def manage_vehicles_api(request):
    resident = get_resident_profile(request.user)
    if not resident:
        return Response({'error': 'Resident profile not found.'}, status=404)

    if request.method == 'GET':
        vehicles = Vehicle.objects.filter(resident=resident)
        serializer = VehicleSerializer(vehicles, many=True)
        return Response(serializer.data)

    if request.method == 'POST':
        vehicle = add_vehicle_service(resident, request.data)
        return Response({'success': True, 'vehicle_id': vehicle.vehicle_id}, status=201)

@api_view(['PUT', 'DELETE'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def mutate_individual_vehicle_api(request, pk):
    resident = get_resident_profile(request.user)
    try:
        vehicle = Vehicle.objects.get(vehicle_id=pk, resident=resident)
    except Vehicle.DoesNotExist:
        return Response({'error': 'Not found.'}, status=404)

    if request.method == 'DELETE':
        vehicle.delete()
        return Response({'success': 'Deleted.'}, status=200)
    
    # PUT logic would go here
    return Response({'error': 'Method not supported.'}, status=405)

@api_view(['GET', 'POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def manage_complaints_api(request):
    resident = Resident.objects.filter(user_id=request.user.username).first()
    if request.method == 'POST':
        complaint = create_complaint(resident, request.data)
        return Response({'success': True, 'id': complaint.complaint_id}, status=status.HTTP_201_CREATED)
    # GET logic here...
    return Response({'error': 'Method not allowed'}, status=405)

@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def manage_amenity_bookings_api(request):
    resident = Resident.objects.filter(user_id=request.user.username).first()
    data = request.data
    
    amenity = Amenity.objects.filter(amenity_name=data['amenity_name']).first()
    start_time = datetime.strptime(data['slots'].split(' - ')[0].strip(), '%I:%M %p').time()
    end_time = datetime.strptime(data['slots'].split(' - ')[1].strip(), '%I:%M %p').time()

    if check_booking_conflict(amenity.amenity_id, data['booking_date'], start_time, end_time):
        return Response({'error': 'Time slot conflict.'}, status=400)
    
    booking = create_booking(resident, data, amenity, start_time, end_time)
    return Response({'success': True, 'booking_id': booking.booking_id}, status=201)