import uuid
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from core_api.models import Resident
from .models import Complaint, Feedback
from .serializers import ComplaintSerializer, CreateComplaintSerializer, FeedbackSerializer


# 1. Complaints List & File Complaint
class ComplaintListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else 'resident'
        
        # Chairman sees all complaints in their society; Resident sees only theirs
        if role_name in ['chairman', 'secretary', 'admin']:
            complaints = Complaint.objects.filter(block__society=request.user.society).order_by('-created_at')
        else:
            resident = Resident.objects.filter(user=request.user).first()
            if not resident:
                return Response({'success': True, 'complaints': []}, status=status.HTTP_200_OK)
            complaints = Complaint.objects.filter(resident=resident).order_by('-created_at')

        return Response({
            'success': True,
            'complaints': ComplaintSerializer(complaints, many=True).data
        }, status=status.HTTP_200_OK)

    def post(self, request):
            serializer = CreateComplaintSerializer(data=request.data)
            if not serializer.is_valid():
                first_err = next(iter(serializer.errors.values()))[0]
                return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

            resident = Resident.objects.filter(user=request.user).first()
            if not resident or not resident.flat:
                return Response({'success': False, 'error': 'Resident flat mapping missing.'}, status=status.HTTP_404_NOT_FOUND)

            complaint = Complaint.objects.create(
                complaint_id=str(uuid.uuid4())[:5].upper(),  # <--- Changed to 5 characters max
                resident=resident,
                block=resident.flat.block,
                title=serializer.validated_data['title'],
                description=serializer.validated_data['description'],
                status='pending',
                created_at=timezone.now()
            )

            return Response({
                'success': True,
                'message': 'Complaint registered successfully!',
                'complaint': ComplaintSerializer(complaint).data
            }, status=status.HTTP_201_CREATED)


# 2. Update Complaint Status (Chairman/Admin only)
class UpdateComplaintStatusView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, complaint_id):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        complaint = Complaint.objects.filter(complaint_id=complaint_id, block__society=request.user.society).first()
        if not complaint:
            return Response({'success': False, 'error': 'Complaint not found.'}, status=status.HTTP_404_NOT_FOUND)

        new_status = request.data.get('status')
        if new_status not in ['pending', 'in-progress', 'resolved', 'rejected']:
            return Response({'success': False, 'error': 'Invalid status value.'}, status=status.HTTP_400_BAD_REQUEST)

        complaint.status = new_status
        if new_status == 'resolved':
            complaint.resolved_at = timezone.now()
        complaint.save()

        return Response({
            'success': True,
            'message': f'Complaint status updated to {new_status}.',
            'complaint': ComplaintSerializer(complaint).data
        }, status=status.HTTP_200_OK)


# 3. Feedback Submission & Listing
class FeedbackView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        feedbacks = Feedback.objects.filter(resident__flat__block__society=request.user.society).order_by('-created_at')
        return Response({
            'success': True,
            'feedbacks': FeedbackSerializer(feedbacks, many=True).data
        }, status=status.HTTP_200_OK)

    def post(self, request):
        resident = Resident.objects.filter(user=request.user).first()
        if not resident:
            return Response({'success': False, 'error': 'Resident not found.'}, status=status.HTTP_404_NOT_FOUND)

        feedback_text = request.data.get('feedback_text')
        rating = request.data.get('rating')

        if not feedback_text:
            return Response({'success': False, 'error': 'Feedback text is required.'}, status=status.HTTP_400_BAD_REQUEST)

        feedback = Feedback.objects.create(
            feedback_id=str(uuid.uuid4())[:5].upper(),  # <--- Ensure 5 characters
            resident=resident,
            feedback_text=feedback_text,
            rating=rating,
            created_at=timezone.now()
        )

        return Response({
            'success': True,
            'message': 'Feedback submitted successfully!',
            'feedback': FeedbackSerializer(feedback).data
        }, status=status.HTTP_201_CREATED)