import uuid
from django.utils import timezone
from django.db import transaction
from django.db.models import Q
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from core_api.models import Users, Roles, Resident,Flats
from .models import Meeting, SocietyCommittee, CommitteeChange, Polls,PollsOption,PollsResponse,LostFoundItem,Tenant
from .serializers import (
    MeetingSerializer,
    CreateMeetingSerializer,
    SocietyCommitteeSerializer,
    CommitteeChangeSerializer,
    CreateCommitteeChangeRequestSerializer,
    PollSerializer,
    CreatePollSerializer,
    CastVoteSerializer,
    LostFoundItemSerializer,
    CreateLostFoundItemSerializer,
    TenantSerializer,
    CreateTenantSerializer
)



# 1. Meetings List & Create
class MeetingListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        society = request.user.society
        meetings = Meeting.objects.filter(organized_by__society=society).order_by('-meeting_date', '-start_time')
        return Response({
            'success': True,
            'meetings': MeetingSerializer(meetings, many=True).data
        }, status=status.HTTP_200_OK)

    def post(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized. Chairman/Secretary privilege required.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = CreateMeetingSerializer(data=request.data)
        if not serializer.is_valid():
            first_err = next(iter(serializer.errors.values()))[0]
            return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

        meeting = Meeting.objects.create(
            meeting_id=str(uuid.uuid4())[:6].upper(),
            title=serializer.validated_data['title'],
            agenda=serializer.validated_data['agenda'],
            meeting_date=serializer.validated_data['meeting_date'],
            start_time=serializer.validated_data['start_time'],
            location=serializer.validated_data['location'],
            organized_by=request.user,
            minutes_doc=serializer.validated_data.get('minutes_doc')
        )

        return Response({
            'success': True,
            'message': 'Meeting scheduled successfully!',
            'meeting': MeetingSerializer(meeting).data
        }, status=status.HTTP_201_CREATED)


# 2. Update Meeting Minutes / Agenda
class MeetingDetailUpdateView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, meeting_id):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        meeting = Meeting.objects.filter(meeting_id=meeting_id, organized_by__society=request.user.society).first()
        if not meeting:
            return Response({'success': False, 'error': 'Meeting not found.'}, status=status.HTTP_404_NOT_FOUND)

        if 'minutes_doc' in request.data:
            meeting.minutes_doc = request.data['minutes_doc']
        if 'agenda' in request.data:
            meeting.agenda = request.data['agenda']
        meeting.save()

        return Response({
            'success': True,
            'message': 'Meeting details updated!',
            'meeting': MeetingSerializer(meeting).data
        }, status=status.HTTP_200_OK)


# 3. Active Committee Members Listing
# 3. Active Committee Members Listing
class SocietyCommitteeListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        society = request.user.society
        committee_members = SocietyCommittee.objects.filter(
            society=society, 
            status='Active'
        ).exclude(role_id='R01')  # <-- Exclude R01 records
        
        return Response({
            'success': True,
            'committee_members': SocietyCommitteeSerializer(committee_members, many=True).data
        }, status=status.HTTP_200_OK)

# Committee Change Requests (Submit & List pending queue)
class CommitteeChangeRequestView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        # Match requests either targeted at or requested by someone in this society
        requests = CommitteeChange.objects.filter(
            Q(target_user__society=request.user.society) | Q(requested_by__society=request.user.society)
        ).order_by('-request_id')
        
        return Response({
            'success': True,
            'requests': CommitteeChangeSerializer(requests, many=True).data
        }, status=status.HTTP_200_OK)

    def post(self, request):
        initiator_role = request.user.role.role_name.lower() if request.user.role else ''
        if initiator_role not in ['chairman', 'admin']:
            return Response({
                'success': False,
                'error': 'Unauthorized. Only Chairman or Admin can initiate role change requests.'
            }, status=status.HTTP_403_FORBIDDEN)

        serializer = CreateCommitteeChangeRequestSerializer(data=request.data)
        if not serializer.is_valid():
            first_err = next(iter(serializer.errors.values()))[0]
            return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        target_user = Users.objects.filter(user_id=data['target_user_id'], society=request.user.society).first()
        if not target_user:
            return Response({'success': False, 'error': 'Target user not found in this society.'}, status=status.HTTP_404_NOT_FOUND)

        new_role = Roles.objects.filter(role_id=data['new_role_id']).first()
        if not new_role:
            return Response({'success': False, 'error': 'Invalid role specified.'}, status=status.HTTP_400_BAD_REQUEST)

        # Prevent duplicate concurrent pending requests for the same user
        pending_exists = CommitteeChange.objects.filter(
            target_user=target_user,
            status__in=['Pending_Admin_Approval', 'Pending_Chairman_Approval']
        ).exists()
        if pending_exists:
            return Response({'success': False, 'error': 'A pending role change request already exists for this member.'}, status=status.HTTP_400_BAD_REQUEST)

        # Routing status depending on who initiated
        initial_status = 'Pending_Admin_Approval' if initiator_role == 'chairman' else 'Pending_Chairman_Approval'

        change_req = CommitteeChange.objects.create(
            request_id=str(uuid.uuid4())[:6].upper(),
            requested_by=request.user,
            target_user=target_user,
            new_role=new_role,
            status=initial_status
        )

        target_approver = 'Admin' if initiator_role == 'chairman' else 'Chairman'
        return Response({
            'success': True,
            'message': f'Role change requested. Awaiting approval from {target_approver}.',
            'request': CommitteeChangeSerializer(change_req).data
        }, status=status.HTTP_201_CREATED)

class MeetingDetailDeleteView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, meeting_id):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        meeting = Meeting.objects.filter(meeting_id=meeting_id, organized_by__society=request.user.society).first()
        if not meeting:
            return Response({'success': False, 'error': 'Meeting not found.'}, status=status.HTTP_404_NOT_FOUND)

        meeting.delete()
        return Response({'success': True, 'message': 'Meeting deleted successfully!'}, status=status.HTTP_200_OK)


# 2. List Society Residents (For dropdown selection)
class SocietyMembersDropdownListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        # Get all users residing in this society
        residents = Resident.objects.filter(flat__block__society=request.user.society).select_related('user', 'flat', 'flat__block')
        
        data = []
        for r in residents:
            if r.user:
                data.append({
                    'user_id': r.user.user_id,
                    'user_name': r.user.user_name,
                    'flat_number': r.flat.flat_number if r.flat else '--',
                    'block_name': r.flat.block.block_name if (r.flat and r.flat.block) else '--',
                })

        return Response({'success': True, 'members': data}, status=status.HTTP_200_OK)
    
# Dual-Approval Handler & Cancellation
class HandleCommitteeChangeActionView(APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def patch(self, request, request_id):
        current_user = request.user
        current_role = current_user.role.role_name.lower() if current_user.role else ''
        action = request.data.get('action')

        if action not in ['Approved', 'Rejected', 'Cancelled']:
            return Response({
                'success': False,
                'error': "Invalid action. Use 'Approved', 'Rejected', or 'Cancelled'."
            }, status=status.HTTP_400_BAD_REQUEST)

        # 1. Fetch by target_user's society so admin vs chairman society mismatches don't cause 404s
        req_obj = CommitteeChange.objects.select_for_update().filter(
            request_id=request_id
        ).first()

        if not req_obj:
            return Response({'success': False, 'error': 'Request not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Verify society boundary (ensure chairman is acting only on their own society)
        target_society = req_obj.target_user.society if hasattr(req_obj.target_user, 'society') else current_user.society
        if current_role == 'chairman' and target_society != current_user.society:
            return Response({'success': False, 'error': 'Unauthorized for this society.'}, status=status.HTTP_403_FORBIDDEN)

        # Ensure request is in a pending state
        if req_obj.status not in ['Pending_Admin_Approval', 'Pending_Chairman_Approval']:
            return Response({
                'success': False,
                'error': f'Request cannot be altered because it is already {req_obj.status}.'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Case 1: Initiator Cancels
        if action == 'Cancelled':
            if req_obj.requested_by != current_user:
                return Response({'success': False, 'error': 'Only the initiator can cancel this request.'}, status=status.HTTP_403_FORBIDDEN)

            req_obj.status = 'Cancelled'
            req_obj.save()
            return Response({'success': True, 'message': 'Role change request has been cancelled.', 'request': CommitteeChangeSerializer(req_obj).data}, status=status.HTTP_200_OK)

        # Case 2: Approvals & Rejections (Must be the counter-party)
        if req_obj.requested_by == current_user:
            return Response({'success': False, 'error': 'Self-approval is forbidden. The other party must approve or reject.'}, status=status.HTTP_403_FORBIDDEN)

        # Enforce exact role match
        if req_obj.status == 'Pending_Admin_Approval' and current_role != 'admin':
            return Response({'success': False, 'error': 'Admin approval required for this request.'}, status=status.HTTP_403_FORBIDDEN)

        if req_obj.status == 'Pending_Chairman_Approval' and current_role != 'chairman':
            return Response({'success': False, 'error': 'Chairman approval required for this request.'}, status=status.HTTP_403_FORBIDDEN)

        req_obj.status = action
        if current_role == 'admin':
            req_obj.admin = current_user
        req_obj.save()

        # If Approved, finalize role and committee updates
        if action == 'Approved':
            req_obj.target_user.role = req_obj.new_role
            req_obj.target_user.save()

            if req_obj.new_role.role_id == 'R01':
                SocietyCommittee.objects.filter(
                    user=req_obj.target_user,
                    society=target_society
                ).delete()
            else:
                comm_member, created = SocietyCommittee.objects.get_or_create(
                    user=req_obj.target_user,
                    society=target_society,
                    defaults={
                        'committee_id': str(uuid.uuid4())[:6].upper(),
                        'role': req_obj.new_role,
                        'election_date': timezone.now().date(),
                        'status': 'Active'
                    }
                )
                if not created:
                    comm_member.role = req_obj.new_role
                    comm_member.status = 'Active'
                    comm_member.save()

        return Response({
            'success': True,
            'message': f'Committee role request successfully {action.lower()}!',
            'request': CommitteeChangeSerializer(req_obj).data
        }, status=status.HTTP_200_OK)

# 1. Active Polls List
class ActivePollsListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        today = timezone.now().date()
        # Auto-update status for expired polls
        Polls.objects.filter(created_by__society=request.user.society, status='active', end_date__lt=today).update(status='closed')

        polls = Polls.objects.filter(created_by__society=request.user.society).order_by('-end_date')
        serializer = PollSerializer(polls, many=True, context={'request': request})
        return Response({'success': True, 'polls': serializer.data}, status=status.HTTP_200_OK)


# 2. Create Poll (Chairman/Admin)
class CreatePollView(APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized. Chairman privilege required.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = CreatePollSerializer(data=request.data)
        if not serializer.is_valid():
            first_err = next(iter(serializer.errors.values()))[0]
            return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        poll_id = str(uuid.uuid4())[:6].upper()

        poll = Polls.objects.create(
            poll_id=poll_id,
            poll_title=data['poll_title'],
            poll_description=data['poll_description'],
            created_by=request.user,
            end_date=data['end_date'],
            status='active'
        )

        # Create poll options
        for opt_text in data['options']:
            PollsOption.objects.create(
                option_id=str(uuid.uuid4())[:5].upper(),
                poll=poll,
                option_text=opt_text.strip()
            )

        return Response({
            'success': True,
            'message': 'Poll created successfully!',
            'poll': PollSerializer(poll, context={'request': request}).data
        }, status=status.HTTP_201_CREATED)


# 3. Cast Vote
class CastVoteView(APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        serializer = CastVoteSerializer(data=request.data)
        if not serializer.is_valid():
            first_err = next(iter(serializer.errors.values()))[0]
            return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        poll = Polls.objects.filter(poll_id=data['poll_id'], created_by__society=request.user.society).first()
        if not poll:
            return Response({'success': False, 'error': 'Poll not found.'}, status=status.HTTP_404_NOT_FOUND)

        if poll.status != 'active' or poll.end_date < timezone.now().date():
            return Response({'success': False, 'error': 'This poll is closed for voting.'}, status=status.HTTP_400_BAD_REQUEST)

        # Ensure single vote per user
        if PollsResponse.objects.filter(poll=poll, user=request.user).exists():
            return Response({'success': False, 'error': 'You have already voted on this poll.'}, status=status.HTTP_400_BAD_REQUEST)

        option = PollsOption.objects.filter(option_id=data['option_id'], poll=poll).first()
        if not option:
            return Response({'success': False, 'error': 'Invalid poll option selected.'}, status=status.HTTP_400_BAD_REQUEST)

        PollsResponse.objects.create(
            response_id=str(uuid.uuid4())[:6].upper(),
            poll=poll,
            option=option,
            user=request.user,
            voted_at=timezone.now()
        )

        return Response({
            'success': True,
            'message': 'Vote recorded successfully!',
            'poll': PollSerializer(poll, context={'request': request}).data
        }, status=status.HTTP_200_OK)

# Delete Poll (Cascades across polls_option and polls_response)
class PollDetailDeleteView(APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def delete(self, request, poll_id):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized. Chairman privilege required.'}, status=status.HTTP_403_FORBIDDEN)

        poll = Polls.objects.filter(poll_id=poll_id, created_by__society=request.user.society).first()
        if not poll:
            return Response({'success': False, 'error': 'Poll not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Deletes the poll; options and user responses cascade automatically
        poll.delete()

        return Response({
            'success': True,
            'message': 'Poll and all associated votes have been deleted successfully.'
        }, status=status.HTTP_200_OK)

# 1. List & Report Lost/Found Items
class LostFoundItemListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # All members can view the lost & found board for their society
        items = LostFoundItem.objects.filter(
            reported_by__society=request.user.society
        ).order_by('-reported_date', '-item_id')

        return Response({
            'success': True,
            'items': LostFoundItemSerializer(items, many=True).data
        }, status=status.HTTP_200_OK)

    def post(self, request):
        # Restricted to Chairman, Secretary, Block Secretary, Admin
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        authorized_roles = ['chairman', 'secretary', 'block secretary', 'block_secretary', 'admin']
        
        if role_name not in authorized_roles:
            return Response({
                'success': False,
                'error': 'Unauthorized. Only Chairman, Secretary, or Block Secretary can report items.'
            }, status=status.HTTP_403_FORBIDDEN)

        serializer = CreateLostFoundItemSerializer(data=request.data)
        if not serializer.is_valid():
            first_err = next(iter(serializer.errors.values()))[0]
            return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        item = LostFoundItem.objects.create(
            item_id=str(uuid.uuid4())[:5].upper(),
            item_name=data['item_name'],
            item_description=data['item_description'],
            item_status=data['item_status'],
            reported_by=request.user,
            handled_by=request.user,
            item_location=data['item_location'],
            reported_date=timezone.now().date()
        )

        return Response({
            'success': True,
            'message': 'Lost & Found item entry created successfully!',
            'item': LostFoundItemSerializer(item).data
        }, status=status.HTTP_201_CREATED)


# 2. Update Status to Claimed / Resolved
class LostFoundItemClaimView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, item_id):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        authorized_roles = ['chairman', 'secretary', 'block secretary', 'block_secretary', 'admin']

        if role_name not in authorized_roles:
            return Response({
                'success': False,
                'error': 'Unauthorized. Only Chairman, Secretary, or Block Secretary can update item resolution.'
            }, status=status.HTTP_403_FORBIDDEN)

        item = LostFoundItem.objects.filter(
            item_id=item_id,
            reported_by__society=request.user.society
        ).first()

        if not item:
            return Response({'success': False, 'error': 'Item not found in this society.'}, status=status.HTTP_404_NOT_FOUND)

        new_status = request.data.get('status', 'Claimed')
        if new_status not in ['Claimed', 'Resolved', 'Returned', 'Lost', 'Found']:
            return Response({'success': False, 'error': 'Invalid resolution status provided.'}, status=status.HTTP_400_BAD_REQUEST)

        item.item_status = new_status
        item.handled_by = request.user
        item.save()

        return Response({
            'success': True,
            'message': f'Item status updated to {new_status}.',
            'item': LostFoundItemSerializer(item).data
        }, status=status.HTTP_200_OK)

class TenantListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized access.'}, status=status.HTTP_403_FORBIDDEN)

        tenants = Tenant.objects.filter(
            flat__block__society=request.user.society
        ).select_related('user', 'flat', 'owner', 'flat__block').order_by('-move_in_date')

        return Response({
            'success': True,
            'tenants': TenantSerializer(tenants, many=True).data
        }, status=status.HTTP_200_OK)

    @transaction.atomic
    def post(self, request):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized. Chairman privilege required.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = CreateTenantSerializer(data=request.data)
        if not serializer.is_valid():
            first_err = next(iter(serializer.errors.values()))[0]
            return Response({'success': False, 'error': str(first_err)}, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data

        # 1. Validate Flat belongs to this Society
        flat = Flats.objects.filter(flat_id=data['flat_id'], block__society=request.user.society).first()
        if not flat:
            return Response({'success': False, 'error': 'Selected flat was not found in your society.'}, status=status.HTTP_404_NOT_FOUND)

        # 2. Check if flat already has an active tenant
        active_tenant = Tenant.objects.filter(flat=flat, status='active').exists()
        if active_tenant:
            return Response({'success': False, 'error': 'An active tenant is already registered for this flat.'}, status=status.HTTP_400_BAD_REQUEST)

        # 3. Resolve Owner (from request or from flat's resident/owner record)
        owner = None
        if data.get('owner_id'):
            owner = Users.objects.filter(user_id=data['owner_id'], society=request.user.society).first()
        if not owner:
            primary_res = Resident.objects.filter(flat=flat).select_related('user').first()
            if primary_res:
                owner = primary_res.user

        # 4. Resolve or Create the Tenant User Account
        tenant_user = Users.objects.filter(user_phone=data['tenant_phone']).first()
        if not tenant_user:
            # Default resident role 'R01' or fallback
            default_role = Roles.objects.filter(role_id='R01').first() or request.user.role
            tenant_user = Users.objects.create(
                user_id=str(uuid.uuid4())[:5].upper(),
                society=request.user.society,
                user_name=data['tenant_name'],
                user_phone=data['tenant_phone'],
                user_email=data.get('tenant_email'),
                role=default_role,
                password='pbkdf2_sha256$default_temporary_hash',
                is_active=True
            )

        # 5. Create Tenant Record
        new_tenant = Tenant.objects.create(
            tenant_id=str(uuid.uuid4())[:6].upper(),
            user=tenant_user,
            flat=flat,
            owner=owner,
            custom_maintenance=data.get('custom_maintenance'),
            status='active',
            move_in_date=data['move_in_date']
        )

        return Response({
            'success': True,
            'message': 'Tenant registered successfully!',
            'tenant': TenantSerializer(new_tenant).data
        }, status=status.HTTP_201_CREATED)


class SocietyFlatsDropdownListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        flats = Flats.objects.filter(
            block__society=request.user.society
        ).select_related('block').order_by('block__block_name', 'flat_number')

        flats_data = [
            {
                'flat_id': f.flat_id,
                'flat_number': f.flat_number,
                'block_name': f.block.block_name if f.block else '',
                'display_label': f"{f.block.block_name} - {f.flat_number}" if f.block else f.flat_number
            }
            for f in flats
        ]
        return Response({'success': True, 'flats': flats_data}, status=status.HTTP_200_OK)

class TenantMoveOutView(APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def patch(self, request, tenant_id):
        role_name = request.user.role.role_name.lower() if request.user.role else ''
        if role_name not in ['chairman', 'secretary', 'admin']:
            return Response({'success': False, 'error': 'Unauthorized. Chairman privilege required.'}, status=status.HTTP_403_FORBIDDEN)

        tenant = Tenant.objects.filter(
            tenant_id=tenant_id,
            flat__block__society=request.user.society
        ).first()

        if not tenant:
            return Response({'success': False, 'error': 'Tenant record not found in this society.'}, status=status.HTTP_404_NOT_FOUND)

        if tenant.status == 'inactive':
            return Response({'success': False, 'error': 'This tenant has already been marked as moved out.'}, status=status.HTTP_400_BAD_REQUEST)

        # Allow Chairman to optionally specify a move-out date, defaulting to today
        move_out_date_str = request.data.get('move_out_date')
        if move_out_date_str:
            try:
                tenant.move_out_date = timezone.datetime.strptime(move_out_date_str, '%Y-%m-%d').date()
            except ValueError:
                return Response({'success': False, 'error': 'Invalid date format. Expected YYYY-MM-DD.'}, status=status.HTTP_400_BAD_REQUEST)
        else:
            tenant.move_out_date = timezone.now().date()

        tenant.status = 'inactive'
        tenant.save()

        return Response({
            'success': True,
            'message': 'Tenant marked as moved out successfully.',
            'tenant': TenantSerializer(tenant).data
        }, status=status.HTTP_200_OK)