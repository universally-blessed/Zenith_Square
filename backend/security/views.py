import uuid
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny

from core_api.models import Resident, Flats,SocietyFeatures
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
        features = SocietyFeatures.objects.filter(society=request.user.society).first()
        if features and features.has_security is False:
            return Response({'success': False, 'error': 'Security alerts are disabled for your society.'}, status=status.HTTP_403_FORBIDDEN)

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
        features = SocietyFeatures.objects.filter(society=request.user.society).first()
        if features and features.has_security is False:
            return Response({'success': False, 'error': 'Security features are disabled for your society.'}, status=status.HTTP_403_FORBIDDEN)

        society = request.user.society
        alerts = SecurityAlerts.objects.filter(
            triggered_by__society=society,
            status='active'
        ).order_by('-created_at')

        return Response({
            'success': True,
            'alerts': SecurityAlertSerializer(alerts, many=True).data
        }, status=status.HTTP_200_OK)

def is_security_or_management(user):
    role_name = user.role.role_name.lower() if user.role else ''
    return role_name in ['chairman', 'secretary', 'admin', 'security', 'security guard', 'guard'] or 'security' in role_name or 'guard' in role_name


# 3. Dismiss / Resolve Emergency Alert (Chairman / Security / Admin)
class DismissSecurityAlertView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, alert_id):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'admin', 'security']:
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
        features = SocietyFeatures.objects.filter(society=request.user.society).first()
        if features and features.has_security is False:
            return Response({'success': False, 'error': 'Security panel & visitor logs are disabled for your society.'}, status=status.HTTP_403_FORBIDDEN)
        
        # Resident sees visitors to their own flat; Chairman/Security sees all society visitors
        if is_security_or_management(request.user):
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
        if not is_security_or_management(request.user):
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = LogVisitorEntrySerializer(data=request.data)
        if not serializer.is_valid():
            first_err = next(iter(serializer.errors.values()))[0]
            return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        flat_obj = Flats.objects.filter(flat_id=data['flat_id'], block__society=request.user.society).first()
        if not flat_obj:
            return Response({'success': False, 'error': 'Invalid flat destination.'}, status=status.HTTP_404_NOT_FOUND)

        # Get or create visitor entry in visitor table
        phone = data['visitor_phone'].strip()
        visitor = Visitor.objects.filter(visitor_phone=phone).first()
        if not visitor:
            vid = str(uuid.uuid4())[:5].upper()
            while Visitor.objects.filter(visitor_id=vid).exists():
                vid = str(uuid.uuid4())[:5].upper()
            visitor = Visitor.objects.create(
                visitor_id=vid,
                visitor_name=data['visitor_name'].strip(),
                visitor_phone=phone,
            )
        else:
            if data['visitor_name'] and visitor.visitor_name != data['visitor_name'].strip():
                visitor.visitor_name = data['visitor_name'].strip()
                visitor.save()

        # Create entry in visitor_logs table with society explicitly stored
        society_obj = flat_obj.block.society if (flat_obj and flat_obj.block) else request.user.society
        log = VisitorLogs.objects.create(
            visitor=visitor,
            flat=flat_obj,
            society=society_obj,
            entry_time=timezone.now(),
            purpose=data['purpose'].strip(),
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
        if not is_security_or_management(request.user):
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


# 6. Lookup Visitor by Phone
class VisitorLookupView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        phone = request.query_params.get('phone', '').strip()
        if not phone or len(phone) < 10:
            return Response({'success': True, 'found': False}, status=status.HTTP_200_OK)

        visitor = Visitor.objects.filter(visitor_phone=phone).first()
        if visitor:
            return Response({
                'success': True,
                'found': True,
                'visitor': {
                    'visitor_id': visitor.visitor_id,
                    'visitor_name': visitor.visitor_name,
                    'visitor_phone': visitor.visitor_phone,
                }
            }, status=status.HTTP_200_OK)
        return Response({'success': True, 'found': False}, status=status.HTTP_200_OK)


# 7. Flats Dropdown for Security Gate
class SecurityFlatsDropdownView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        from core_api.models import Societies
        society = getattr(request.user, 'society', None) if request.user and request.user.is_authenticated else None
        if not society:
            society = Societies.objects.filter(society_id='SOC01').first() or Societies.objects.first()
        society_name = society.society_name if society else 'Serene Heights'

        flats = Flats.objects.filter(
            block__society=society
        ).select_related('block', 'block__society')

        def sort_key(f):
            b_name = f.block.block_name if f.block else 'A'
            try:
                num = int(''.join(filter(str.isdigit, str(f.flat_number))))
            except (ValueError, TypeError):
                num = 999999
            return (b_name, num)

        sorted_flats = sorted(flats, key=sort_key)

        flats_data = [
            {
                'flat_id': f.flat_id,
                'flat_number': f.flat_number,
                'block_name': f.block.block_name if f.block else 'A',
                'society_name': society_name,
                'display_label': f"Flat {f.flat_number} - Block {f.block.block_name if f.block else 'A'} ({society_name})"
            }
            for f in sorted_flats
        ]
        return Response({
            'success': True,
            'society_name': society_name,
            'flats': flats_data
        }, status=status.HTTP_200_OK)