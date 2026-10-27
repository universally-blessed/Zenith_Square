# In communication_api/views.py

import uuid
from django.utils import timezone
from django.db.models import Q
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from core_api.models import Resident, Blocks
from .models import Notice
from .serializers import NoticeSerializer, CreateNoticeSerializer


class NoticeListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        society = user.society
        if not society:
            return Response({'success': False, 'error': 'Society context missing.'}, status=status.HTTP_404_NOT_FOUND)

        role_name = user.role.role_name.lower() if user.role else 'resident'

        # Chairman, General Secretary, and Admin view all notices in the society
        if role_name in ['chairman', 'secretary', 'admin']:
            notices = Notice.objects.filter(society=society, is_active=True).order_by('-created_at')

        # Block Secretary sees society-wide notices + their specific block notices
        elif role_name in ['block_secretary', 'block secretary']:
            resident = Resident.objects.filter(user=user).first()
            user_block = resident.flat.block if (resident and resident.flat) else None

            notices = Notice.objects.filter(
                Q(society=society) & Q(is_active=True) & (Q(block__isnull=True) | Q(block=user_block))
            ).order_by('-created_at')

        # Residents see society-wide notices + notices for their flat's block
        else:
            resident = Resident.objects.filter(user=user).first()
            user_block = resident.flat.block if (resident and resident.flat) else None

            notices = Notice.objects.filter(
                Q(society=society) & Q(is_active=True) & (Q(block__isnull=True) | Q(block=user_block))
            ).order_by('-created_at')

        return Response({
            'success': True,
            'notices': NoticeSerializer(notices, many=True).data
        }, status=status.HTTP_200_OK)

    def post(self, request):
        user = request.user
        role_name = user.role.role_name.lower() if user.role else ''

        allowed_roles = ['chairman', 'secretary', 'admin', 'block_secretary', 'block secretary']
        if role_name not in allowed_roles:
            return Response({'success': False, 'error': 'Unauthorized to publish announcements.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = CreateNoticeSerializer(data=request.data)
        if not serializer.is_valid():
            first_err = next(iter(serializer.errors.values()))[0]
            return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        block_obj = None
        block_id_val = data.get('block_id')

        # Role-based block validation logic
        if role_name in ['block_secretary', 'block secretary']:
            # Block Secretary MUST publish to their assigned block only
            resident = Resident.objects.filter(user=user).first()
            user_block = resident.flat.block if (resident and resident.flat) else None

            if not user_block:
                return Response({'success': False, 'error': 'No assigned block found for this Block Secretary.'}, status=status.HTTP_400_BAD_REQUEST)

            block_obj = user_block

        else:
            # Secretary / Chairman / Admin can select a specific block or target "All Blocks" (None)
            if block_id_val and block_id_val.lower() != 'all':
                block_obj = Blocks.objects.filter(block_id=block_id_val, society=user.society).first()
                if not block_obj:
                    return Response({'success': False, 'error': 'Specified target block was not found.'}, status=status.HTTP_404_NOT_FOUND)

        notice = Notice.objects.create(
            notice_id=str(uuid.uuid4())[:5].upper(),
            society=user.society,
            block=block_obj,
            title=data['title'].strip(),
            description=data['description'].strip(),
            priority=data.get('priority', 'normal').lower(),
            created_by=user,
            created_at=timezone.now(),
            is_active=True
        )

        return Response({
            'success': True,
            'message': 'Notice published successfully!',
            'notice': NoticeSerializer(notice).data
        }, status=status.HTTP_201_CREATED)


class NoticeDetailDeleteView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, notice_id):
        user = request.user
        role_name = user.role.role_name.lower() if user.role else ''

        notice = Notice.objects.filter(notice_id=notice_id, society=user.society).first()
        if not notice:
            return Response({'success': False, 'error': 'Notice not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Permission check: Author, Chairman, Secretary, or Admin can delete
        if role_name in ['chairman', 'secretary', 'admin'] or notice.created_by == user:
            notice.is_active = False
            notice.save()
            return Response({'success': True, 'message': 'Notice archived successfully!'}, status=status.HTTP_200_OK)

        return Response({'success': False, 'error': 'Unauthorized to delete this notice.'}, status=status.HTTP_403_FORBIDDEN)