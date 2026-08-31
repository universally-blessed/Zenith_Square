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

        # Chairman/Admin sees all notices in the society
        if role_name in ['chairman', 'secretary', 'admin']:
            notices = Notice.objects.filter(society=society, is_active=True).order_by('-created_at')
        else:
            # Resident sees society-wide notices (block_id IS NULL) + their specific block notices
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
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized. Chairman privilege required.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = CreateNoticeSerializer(data=request.data)
        if not serializer.is_valid():
            first_err = next(iter(serializer.errors.values()))[0]
            return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        block_obj = None
        if data.get('block_id'):
            block_obj = Blocks.objects.filter(block_id=data['block_id'], society=request.user.society).first()

        notice = Notice.objects.create(
            notice_id=str(uuid.uuid4())[:5].upper(),
            society=request.user.society,
            block=block_obj,
            title=data['title'],
            description=data['description'],
            priority=data.get('priority', 'normal'),
            created_by=request.user,
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
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        notice = Notice.objects.filter(notice_id=notice_id, society=request.user.society).first()
        if not notice:
            return Response({'success': False, 'error': 'Notice not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Soft delete
        notice.is_active = False
        notice.save()

        return Response({'success': True, 'message': 'Notice archived successfully!'}, status=status.HTTP_200_OK)