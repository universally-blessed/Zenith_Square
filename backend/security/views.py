import uuid
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from core_api.models import Resident, Flats
from .models import SecurityAlerts, Visitor, VisitorLogs
from .serializers import (
    SecurityAlertSerializer,
    TriggerAlertSerializer,
    VisitorLogSerializer,
    LogVisitorEntrySerializer,
)


# 1. Trigger Emergency Alert (Residents & Management)
class TriggerEmergencyAlertView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = TriggerAlertSerializer(data=request.data)
        if not serializer.is_valid():
            first_err = next(iter(serializer.errors.values()))[0]
            return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

        alert = SecurityAlerts.objects.create(
            alert_id=str(uuid.uuid4())[:6].upper(),
            alert_type=serializer.validated_data['alert_type'],
            description=serializer.validated_data['description'],
            triggered_by=request.user,
            status='active',
            created_at=timezone.now()
        )

        return Response({
            'success': True,
            'message': 'EMERGENCY ALERT BROADCASTED TO SECURITY & SOCIETY MEMBERS!',
            'alert': SecurityAlertSerializer(alert).data
        }, status=status.HTTP_201_CREATED)


# 2. List Active Security Alerts
class ActiveSecurityAlertsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        society = request.user.society
        alerts = SecurityAlerts.objects.filter(
            triggered_by__society=society,
            status='active'
        ).order_by('-created_at')

        return Response({
            'success': True,
            'alerts': SecurityAlertSerializer(alerts, many=True).data
        }, status=status.HTTP_200_OK)


# 3. Dismiss / Resolve Emergency Alert (Chairman / Security / Admin)
class DismissSecurityAlertView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, alert_id):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin', 'security']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        alert = SecurityAlerts.objects.filter(alert_id=alert_id, triggered_by__society=request.user.society).first()
        if not alert:
            return Response({'success': False, 'error': 'Alert not found.'}, status=status.HTTP_404_NOT_FOUND)

        alert.status = 'resolved'
        alert.save()

        return Response({
            'success': True,
            'message': 'Emergency alert marked as resolved.',
            'alert': SecurityAlertSerializer(alert).data
        }, status=status.HTTP_200_OK)


# 4. Visitor Entry & Logs
class VisitorLogsListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else 'resident'
        
        # Resident sees visitors to their own flat; Chairman/Security sees all society visitors
        if role_name in ['chairman', 'secretary', 'admin', 'security']:
            logs = VisitorLogs.objects.filter(flat__block__society=request.user.society).order_by('-entry_time')
        else:
            resident = Resident.objects.filter(user=request.user).first()
            if not resident or not resident.flat:
                return Response({'success': True, 'logs': []}, status=status.HTTP_200_OK)
            logs = VisitorLogs.objects.filter(flat=resident.flat).order_by('-entry_time')

        return Response({
            'success': True,
            'logs': VisitorLogSerializer(logs, many=True).data
        }, status=status.HTTP_200_OK)

    def post(self, request):
        # Only Gate Security, Chairman, or Admin log physical visitor entry
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['security', 'chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = LogVisitorEntrySerializer(data=request.data)
        if not serializer.is_valid():
            first_err = next(iter(serializer.errors.values()))[0]
            return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        flat_obj = Flats.objects.filter(flat_id=data['flat_id'], block__society=request.user.society).first()
        if not flat_obj:
            return Response({'success': False, 'error': 'Invalid flat destination.'}, status=status.HTTP_404_NOT_FOUND)

        # Get or create visitor entry
        visitor, _ = Visitor.objects.get_or_create(
            visitor_phone=data['visitor_phone'],
            defaults={
                'visitor_id': str(uuid.uuid4())[:5].upper(),
                'visitor_name': data['visitor_name'],
            }
        )

        log = VisitorLogs.objects.create(
            visitor=visitor,
            flat=flat_obj,
            entry_time=timezone.now(),
            purpose=data['purpose'],
            recorded_by=request.user
        )

        return Response({
            'success': True,
            'message': 'Visitor entry logged successfully!',
            'log': VisitorLogSerializer(log).data
        }, status=status.HTTP_201_CREATED)


# 5. Log Visitor Exit
class LogVisitorExitView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, log_id):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['security', 'chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        log = VisitorLogs.objects.filter(log_id=log_id, flat__block__society=request.user.society).first()
        if not log:
            return Response({'success': False, 'error': 'Visitor log not found.'}, status=status.HTTP_404_NOT_FOUND)

        log.exit_time = timezone.now()
        log.save()

        return Response({
            'success': True,
            'message': 'Visitor exit timestamp recorded.',
            'log': VisitorLogSerializer(log).data
        }, status=status.HTTP_200_OK)