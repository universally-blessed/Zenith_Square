import jwt
import uuid
from datetime import datetime, timedelta
from django.utils import timezone
from django.conf import settings
from django.db import transaction
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, viewsets
from rest_framework.permissions import AllowAny
from rest_framework.decorators import action
from django.db.models import Sum, Count, Q, Case, When, IntegerField, Avg, F, ExpressionWrapper, DurationField
from django.db.models.functions import TruncMonth
from django.contrib.auth.hashers import make_password
from .authentication import AdminJWTAuthentication
from .models import (
    Admin, Societies, SocietyCommittee, SocietyFeatures, Flats, Blocks, 
    Occupancy, Users, CommitteeChange, SocietyExpenses, MaintenanceBill, 
    Complaint, VisitorLogs, Feedback, Roles, Tenant
)
from .serializers import (
    AdminLoginSerializer, SocietySerializer, SocietyFeaturesSerializer, 
    UserManagementSerializer, CommitteeChangeSerializer, RoleSerializer, 
    OccupancySerializer, TenantSerializer, SecurityRegistrationSerializer
)
from .permissions import IsSuperAdmin

JWT_SECRET = getattr(settings, 'SECRET_KEY', 'default_secret_society_admin')
JWT_ALGORITHM = 'HS256'


class AdminLoginView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = AdminLoginSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            password = serializer.validated_data['password']
            try:
                admin = Admin.objects.get(a_email=email, a_password=password)
                
                payload = {
                    'admin_id': str(admin.a_id),
                    'username': admin.a_username,
                    'email': admin.a_email,
                    'exp': datetime.now(timezone.UTC) + timedelta(hours=24),
                    'iat': datetime.now(timezone.UTC),
                }
                
                token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
                
                return Response({
                    "token": token,
                    "admin": {
                        "admin_id": admin.a_id,
                        "username": admin.a_username,
                        "email": admin.a_email
                    }
                }, status=status.HTTP_200_OK)
            except Admin.DoesNotExist:
                return Response({"error": "Invalid email or password"}, status=status.HTTP_401_UNAUTHORIZED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SocietyViewSet(viewsets.ModelViewSet):
    queryset = Societies.objects.all()
    serializer_class = SocietySerializer
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsSuperAdmin]

    @transaction.atomic
    def create(self, request, *args, **kwargs):
        society_data = request.data.copy()
        has_block_sec = society_data.pop('has_block_secretary', False)
        has_nominee = society_data.pop('has_nominee', True)
        has_sec = society_data.pop('has_security', True)
        blocks_data = society_data.pop('blocks', [])

        serializer = self.get_serializer(data=society_data)
        serializer.is_valid(raise_exception=True)
        society = serializer.save(created_at=timezone.now())

        # FIX: Robust config_id generation to handle 'S' or 'SOC' prefixes and ensure exact 5-char length (VARCHAR(5))
        numeric_part = society.society_id.replace('SOC', '').replace('S', '')
        config_id = f"C{numeric_part.zfill(4)}"[:5]

        SocietyFeatures.objects.create(
            config_id=config_id,
            society=society,
            has_block_secretary=has_block_sec,
            has_nominee=has_nominee,
            has_security=has_sec
        )

        block_counter = Blocks.objects.count() + 1
        flat_counter = Flats.objects.count() + 1

        for b_item in blocks_data:
            block_name = str(b_item.get('block_name', '')).strip()
            if not block_name:
                continue

            block_id = f"B{str(block_counter).zfill(4)}"[:5]
            while Blocks.objects.filter(block_id=block_id).exists():
                block_counter += 1
                block_id = f"B{str(block_counter).zfill(4)}"[:5]

            block_obj = Blocks.objects.create(
                block_id=block_id,
                society=society,
                block_name=block_name
            )
            block_counter += 1

            flats_list = b_item.get('flats', [])
            for f_item in flats_list:
                flat_num = str(f_item.get('flat_number', '')).strip()
                floor_num = f_item.get('floor_number', 1)

                if not flat_num:
                    continue

                flat_id = f"F{str(flat_counter).zfill(4)}"[:5]
                while Flats.objects.filter(flat_id=flat_id).exists():
                    flat_counter += 1
                    flat_id = f"F{str(flat_counter).zfill(4)}"[:5]

                Flats.objects.create(
                    flat_id=flat_id,
                    block=block_obj,
                    flat_number=flat_num,
                    floor_number=int(floor_num)
                )
                flat_counter += 1

        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    @action(detail=True, methods=['post'])
    def toggle_status(self, request, pk=None):
        society = self.get_object()
        society.society_status = 'inactive' if society.society_status == 'active' else 'active'
        society.save()
        return Response({
            "message": f"Society is now {society.society_status}",
            "society_status": society.society_status
        }, status=status.HTTP_200_OK)


class SocietyFeaturesViewSet(viewsets.ModelViewSet):
    queryset = SocietyFeatures.objects.all()
    serializer_class = SocietyFeaturesSerializer
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsSuperAdmin]

    def get_queryset(self):
        queryset = SocietyFeatures.objects.all()
        society_id = self.request.query_params.get('society_id')
        if society_id:
            queryset = queryset.filter(society_id=society_id)
        return queryset


class UserManagementViewSet(viewsets.ModelViewSet):
    http_method_names = ['get', 'post', 'put', 'patch', 'head', 'options']
    queryset = Users.objects.all().select_related('society', 'role')
    serializer_class = UserManagementSerializer
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsSuperAdmin]

    def get_queryset(self):
        queryset = Users.objects.all().select_related('society', 'role')
        society_id = self.request.query_params.get('society_id')
        role_id = self.request.query_params.get('role_id')

        if society_id:
            queryset = queryset.filter(society_id=society_id)
        if role_id:
            queryset = queryset.filter(role_id=role_id)
            
        return queryset

    @action(detail=True, methods=['post'], url_path='assign-initial-role')
    @transaction.atomic
    def assign_initial_role(self, request, pk=None):
        user = self.get_object()
        role_id = request.data.get('role_id')
        
        if not role_id:
            return Response({'error': 'role_id is required.'}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            new_role = Roles.objects.get(role_id=role_id)
        except Roles.DoesNotExist:
            return Response({'error': 'Role does not exist.'}, status=status.HTTP_404_NOT_FOUND)

        if not user.society:
            return Response({'error': 'User must belong to a society before receiving a committee role.'}, status=status.HTTP_400_BAD_REQUEST)

        if new_role.role_name.strip().lower() != 'chairman':
            return Response({
                'success': False,
                'error': "Direct initial assignment is restricted exclusively to the 'Chairman' role. Other roles must be delegated via standard committee change requests."
            }, status=status.HTTP_400_BAD_REQUEST)

        existing_chairman = SocietyCommittee.objects.filter(
            society=user.society,
            role__role_name__iexact='Chairman',
            status='Active'
        ).first()

        if existing_chairman:
            return Response({
                'success': False,
                'error': (
                    f"'{user.society.society_name}' already has an active Chairman ({existing_chairman.user.user_name}). "
                    "All subsequent role changes must be initiated via dual approval (Committee Change Request)."
                )
            }, status=status.HTTP_400_BAD_REQUEST)

        user.role = new_role
        user.save()

        SocietyCommittee.objects.update_or_create(
            user=user,
            society=user.society,
            defaults={
                'committee_id': str(uuid.uuid4())[:6].upper(),
                'role': new_role,
                'election_date': timezone.now().date(),
                'status': 'Active'
            }
        )

        return Response({
            'success': True,
            'message': f"{user.user_name} has been successfully appointed as the initial Chairman for {user.society.society_name}.",
            'user': UserManagementSerializer(user).data
        }, status=status.HTTP_200_OK)

    @action(detail=False, methods=['post'], url_path='register-security')
    @transaction.atomic
    def register_security(self, request):
        serializer = SecurityRegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        data = serializer.validated_data
        society = Societies.objects.get(society_id=data['society_id'])
        
        security_role, _ = Roles.objects.get_or_create(
            role_name__iexact='Security',
            defaults={
                'role_id': f"R{str(Roles.objects.count() + 1).zfill(4)}"[:5],
                'role_name': 'Security'
            }
        )

        user_counter = Users.objects.count() + 1
        user_id = f"U{str(user_counter).zfill(4)}"[:5]
        while Users.objects.filter(user_id=user_id).exists():
            user_counter += 1
            user_id = f"U{str(user_counter).zfill(4)}"[:5]

        security_user = Users.objects.create(
            user_id=user_id,
            society=society,
            user_name=data['user_name'],
            user_phone=data['user_phone'],
            user_email=data['user_email'],
            role=security_role,
            password=make_password(data['password']),
            is_active=True
        )

        return Response({
            'success': True,
            'message': f"Security Guard {security_user.user_name} registered successfully for {society.society_name}.",
            'user': UserManagementSerializer(security_user).data
        }, status=status.HTTP_201_CREATED)


class CommitteeChangeViewSet(viewsets.ModelViewSet):
    queryset = CommitteeChange.objects.all().order_by('-request_id')
    serializer_class = CommitteeChangeSerializer
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsSuperAdmin]

    def create(self, request, *args, **kwargs):
        target_user_id = request.data.get('target_user')
        new_role_id = request.data.get('new_role')

        if not target_user_id or not new_role_id:
            return Response(
                {'error': 'target_user and new_role are required.'}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            target_user = Users.objects.get(user_id=target_user_id)
            new_role = Roles.objects.get(role_id=new_role_id)
        except (Users.DoesNotExist, Roles.DoesNotExist) as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

        req_id = f"REQ{str(uuid.uuid4())[:6].upper()}"[:10]
        while CommitteeChange.objects.filter(request_id=req_id).exists():
            req_id = f"REQ{str(uuid.uuid4())[:6].upper()}"[:10]

        admin_obj = request.user if isinstance(request.user, Admin) else None

        change_req = CommitteeChange.objects.create(
            request_id=req_id,
            requested_by=None,
            target_user=target_user,
            new_role=new_role,
            admin=admin_obj,
            status='Pending_Chairman_Approval'
        )

        return Response(
            CommitteeChangeSerializer(change_req).data, 
            status=status.HTTP_201_CREATED
        )

    @transaction.atomic
    @action(detail=True, methods=['post'])
    def process_action(self, request, pk=None):
        action_type = request.data.get('action')
        if action_type in ['Approved', 'approve']:
            return self.approve(request, pk=pk)
        elif action_type in ['Rejected', 'reject']:
            return self.reject(request, pk=pk)
        return Response({'error': "Invalid action. Use 'Approved' or 'Rejected'."}, status=status.HTTP_400_BAD_REQUEST)

    @transaction.atomic
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        req_obj = self.get_object()

        if req_obj.status == 'Pending_Chairman_Approval':
            return Response({
                'success': False,
                'error': 'This request was created by Admin and requires Chairman approval from the mobile app.'
            }, status=status.HTTP_400_BAD_REQUEST)

        if req_obj.status != 'Pending_Admin_Approval':
            return Response({
                'success': False,
                'error': f'Cannot process request with current status: {req_obj.status}.'
            }, status=status.HTTP_400_BAD_REQUEST)

        req_obj.status = 'Approved'
        if isinstance(request.user, Admin):
            req_obj.admin = request.user
        req_obj.save()

        target_user = req_obj.target_user
        new_role = req_obj.new_role
        today = timezone.now().date()

        if target_user and new_role:
            target_user.role = new_role
            target_user.save()

            society = target_user.society
            if society:
                leadership_roles = [
                    'chairman', 
                    'secretary', 
                    'treasurer', 
                    'block secretary', 
                    'committee member'
                ]
                is_leadership = new_role.role_name.strip().lower() in leadership_roles

                if is_leadership:
                    if new_role.role_name.strip().lower() in ['chairman', 'secretary', 'treasurer']:
                        previous_members = SocietyCommittee.objects.filter(
                            society=society,
                            role=new_role,
                            status='Active'
                        ).exclude(user=target_user)

                        for prev_mem in previous_members:
                            prev_mem.term_end = today
                            prev_mem.status = 'Terminated'
                            prev_mem.save()

                    comm_member = SocietyCommittee.objects.filter(
                        user=target_user, 
                        society=society
                    ).first()

                    if comm_member:
                        comm_member.role = new_role
                        comm_member.status = 'Active'
                        comm_member.election_date = today
                        comm_member.term_end = None
                        comm_member.save()
                    else:
                        SocietyCommittee.objects.create(
                            committee_id=str(uuid.uuid4())[:6].upper(),
                            user=target_user,
                            society=society,
                            role=new_role,
                            election_date=today,
                            status='Active'
                        )
                else:
                    active_memberships = SocietyCommittee.objects.filter(
                        user=target_user, 
                        society=society,
                        status='Active'
                    )
                    for mem in active_memberships:
                        mem.term_end = today
                        mem.status = 'Terminated'
                        mem.save()

        return Response({
            'success': True,
            'message': f"Role shift to '{new_role.role_name}' approved and committee records synchronized.",
            'request': CommitteeChangeSerializer(req_obj).data
        }, status=status.HTTP_200_OK)

    @transaction.atomic
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        req_obj = self.get_object()

        if req_obj.status != 'Pending_Admin_Approval':
            return Response({
                'success': False,
                'error': f'Cannot reject request with status: {req_obj.status}.'
            }, status=status.HTTP_400_BAD_REQUEST)

        req_obj.status = 'Rejected'
        if isinstance(request.user, Admin):
            req_obj.admin = request.user
        req_obj.save()

        return Response({
            'success': True,
            'message': 'Committee role change request rejected.',
            'request': CommitteeChangeSerializer(req_obj).data
        }, status=status.HTTP_200_OK)


class AdminReportsView(APIView):
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsSuperAdmin]

    def get(self, request):
        society_id = request.query_params.get('society_id')

        flats_qs = Flats.objects.all()
        occupancy_qs = Occupancy.objects.all()
        expenses_qs = SocietyExpenses.objects.all()
        bills_qs = MaintenanceBill.objects.all()
        complaints_qs = Complaint.objects.all()
        visitors_qs = VisitorLogs.objects.all()

        if society_id:
            flats_qs = flats_qs.filter(block__society_id=society_id)
            occupancy_qs = occupancy_qs.filter(flat__block__society_id=society_id)
            expenses_qs = expenses_qs.filter(society_id=society_id)
            bills_qs = bills_qs.filter(flat__block__society_id=society_id)
            complaints_qs = complaints_qs.filter(block__society_id=society_id)
            visitors_qs = visitors_qs.filter(flat__block__society_id=society_id)

        total_flats = flats_qs.count()
        owner_count = occupancy_qs.filter(occupancy_type__iexact='Owner').count()
        tenant_count = occupancy_qs.filter(occupancy_type__iexact='Tenant').count()
        vacant_count = max(0, total_flats - (owner_count + tenant_count))

        total_expenses = expenses_qs.aggregate(total=Sum('amount'))['total'] or 0.0
        total_bills = bills_qs.count()
        paid_bills = bills_qs.filter(status__iexact='paid').count()
        collection_rate = round((paid_bills / total_bills * 100), 1) if total_bills > 0 else 0.0

        expense_by_month = expenses_qs.annotate(
            month_date=TruncMonth('payment_date')
        ).values('month_date').annotate(
            total=Sum('amount')
        ).order_by('month_date')

        monthly_expenses = [
            {
                "month": item['month_date'].strftime('%b') if item['month_date'] else 'N/A',
                "amount": float(item['total'])
            }
            for item in expense_by_month
        ]

        bill_by_month = bills_qs.annotate(
            month_date=TruncMonth('due_date')
        ).values('month_date').annotate(
            total=Count('bill_id'),
            paid=Count('bill_id', filter=Q(status__iexact='paid'))
        ).order_by('month_date')

        collection_trend = [
            {
                "month": item['month_date'].strftime('%b') if item['month_date'] else 'N/A',
                "rate": round((item['paid'] / item['total'] * 100), 1) if item['total'] > 0 else 0.0
            }
            for item in bill_by_month
        ]

        filed_count = complaints_qs.count()
        resolved_qs = complaints_qs.filter(
            status__iexact='resolved',
            created_at__isnull=False,
            resolved_at__isnull=False
        )
        resolved_count = resolved_qs.count()

        avg_duration = resolved_qs.annotate(
            duration=ExpressionWrapper(
                F('resolved_at') - F('created_at'),
                output_field=DurationField()
            )
        ).aggregate(avg_time=Avg('duration'))['avg_time']

        avg_resolution_days = round(avg_duration.total_seconds() / 86400, 1) if avg_duration else 0.0

        visitor_by_month = visitors_qs.annotate(
            month_date=TruncMonth('entry_time')
        ).values('month_date').annotate(
            total=Count('log_id')
        ).order_by('month_date')

        monthly_visitors = [
            {
                "month": item['month_date'].strftime('%b') if item['month_date'] else 'N/A',
                "count": item['total']
            }
            for item in visitor_by_month
        ]

        return Response({
            "occupancy": {
                "owner_occupied": owner_count,
                "tenant_occupied": tenant_count,
                "vacant": vacant_count,
                "total_flats": total_flats
            },
            "financial_kpis": {
                "total_expenses": float(total_expenses),
                "collection_rate": collection_rate,
                "collection_trend": collection_trend,
                "monthly_expenses": monthly_expenses,
            },
            "complaints": {
                "filed": filed_count,
                "resolved": resolved_count,
                "avg_resolution_days": avg_resolution_days
            },
            "visitors": {
                "monthly_traffic": monthly_visitors
            }
        }, status=status.HTTP_200_OK)


class AdminProfileView(APIView):
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsSuperAdmin]

    def put(self, request):
        admin = request.user
        username = request.data.get('username')
        email = request.data.get('email')
        current_password = request.data.get('current_password')
        new_password = request.data.get('new_password')

        if username:
            admin.a_username = username.strip()
        if email:
            cleaned_email = email.strip().lower()
            if Admin.objects.filter(a_email=cleaned_email).exclude(a_id=admin.a_id).exists():
                return Response({"error": "Email is already in use by another admin."}, status=status.HTTP_400_BAD_REQUEST)
            admin.a_email = cleaned_email

        if new_password:
            if ' ' in new_password:
                return Response({"error": "New password cannot contain spaces."}, status=status.HTTP_400_BAD_REQUEST)
            if len(new_password) < 6:
                return Response({"error": "New password must be at least 6 characters long."}, status=status.HTTP_400_BAD_REQUEST)
            if not current_password:
                return Response({"error": "Current password is required to set a new password."}, status=status.HTTP_400_BAD_REQUEST)
            if admin.a_password != current_password:
                return Response({"error": "Current password does not match."}, status=status.HTTP_400_BAD_REQUEST)
            if new_password == current_password:
                return Response({"error": "New password must be different from current password."}, status=status.HTTP_400_BAD_REQUEST)
            
            admin.a_password = new_password

        admin.save()

        return Response({
            "message": "Profile updated successfully!",
            "admin": {
                "admin_id": admin.a_id,
                "username": admin.a_username,
                "email": admin.a_email
            }
        }, status=status.HTTP_200_OK)


class AdminOverviewDashboardView(APIView):
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsSuperAdmin]

    def get(self, request):
        total_societies = Societies.objects.count()
        total_users = Users.objects.count()
        active_societies_count = Societies.objects.filter(society_status__iexact='active').count()

        pending_admin_count = CommitteeChange.objects.filter(status='Pending_Admin_Approval').count()
        pending_chairman_count = CommitteeChange.objects.filter(status='Pending_Chairman_Approval').count()

        pending_requests = CommitteeChange.objects.filter(
            status__in=['Pending_Admin_Approval', 'Pending_Chairman_Approval']
        ).select_related('requested_by', 'target_user', 'new_role', 'target_user__society').order_by(
            Case(
                When(status='Pending_Admin_Approval', then=0),
                default=1,
                output_field=IntegerField()
            ),
            '-request_id'
        )[:5]

        pending_requests_data = [
            {
                "request_id": req.request_id,
                "society_name": req.target_user.society.society_name if req.target_user and req.target_user.society else "-",
                "requested_by": req.requested_by.user_name if req.requested_by else "Super Admin",
                "target_user": req.target_user.user_name if req.target_user else "-",
                "new_role": req.new_role.role_name if req.new_role else "-",
                "status": req.status
            }
            for req in pending_requests
        ]

        recent_users = Users.objects.select_related('society', 'role').order_by('-user_id')[:5]
        recent_users_data = [
            {
                "user_id": u.user_id,
                "user_name": u.user_name,
                "user_email": u.user_email or "-",
                "user_phone": u.user_phone,
                "society_name": u.society.society_name if u.society else "-",
                "role_name": u.role.role_name if u.role else "Resident",
                "is_active": u.is_active
            }
            for u in recent_users
        ]

        recent_feedbacks = Feedback.objects.select_related(
            'resident__user',
            'resident__flat__block__society'
        ).order_by('-created_at')[:5]

        recent_feedbacks_data = []
        for fb in recent_feedbacks:
            user = fb.resident.user if fb.resident and fb.resident.user else None
            flat = fb.resident.flat if fb.resident else None
            society = flat.block.society if (flat and flat.block and flat.block.society) else (user.society if user else None)

            recent_feedbacks_data.append({
                "feedback_id": fb.feedback_id,
                "rating": fb.rating or 5,
                "comments": fb.feedback_text,
                "society_name": society.society_name if society else "-",
                "user_name": user.user_name if user else "Resident",
                "created_at": fb.created_at.strftime('%d %b %Y') if fb.created_at else "-"
            })

        return Response({
            "kpis": {
                "total_societies": total_societies,
                "active_societies": active_societies_count,
                "total_users": total_users,
                "pending_admin_count": pending_admin_count,
                "pending_chairman_count": pending_chairman_count,
                "pending_requests_count": pending_admin_count + pending_chairman_count
            },
            "pending_committee_requests": pending_requests_data,
            "recent_users": recent_users_data,
            "recent_feedbacks": recent_feedbacks_data
        }, status=status.HTTP_200_OK)


class RoleViewSet(viewsets.ModelViewSet):
    queryset = Roles.objects.all()
    serializer_class = RoleSerializer
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsSuperAdmin]


class AdminFinancialsReportView(APIView):
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsSuperAdmin]

    def get(self, request):
        society_id = request.query_params.get('society_id')
        month = request.query_params.get('month')

        expenses_qs = SocietyExpenses.objects.all()
        bills_qs = MaintenanceBill.objects.all()

        if society_id:
            expenses_qs = expenses_qs.filter(society_id=society_id)
            bills_qs = bills_qs.filter(flat__block__society_id=society_id)

        if month:
            if '-' in month:
                year, m = month.split('-')
                expenses_qs = expenses_qs.filter(payment_date__year=year, payment_date__month=m)
                bills_qs = bills_qs.filter(due_date__year=year, due_date__month=m)
            else:
                expenses_qs = expenses_qs.filter(payment_date__month=month)
                bills_qs = bills_qs.filter(due_date__month=month)

        total_expenses = expenses_qs.aggregate(total=Sum('amount'))['total'] or 0.0
        total_bills = bills_qs.count()
        paid_bills = bills_qs.filter(status__iexact='paid').count()
        collection_rate = round((paid_bills / total_bills * 100), 1) if total_bills > 0 else 0.0

        expense_by_month = expenses_qs.annotate(
            month_date=TruncMonth('payment_date')
        ).values('month_date').annotate(total=Sum('amount')).order_by('month_date')

        monthly_expenses = [
            {"month": item['month_date'].strftime('%b') if item['month_date'] else 'N/A', "amount": float(item['total'])}
            for item in expense_by_month
        ]

        bill_by_month = bills_qs.annotate(
            month_date=TruncMonth('due_date')
        ).values('month_date').annotate(
            total=Count('bill_id'),
            paid=Count('bill_id', filter=Q(status__iexact='paid'))
        ).order_by('month_date')

        collection_trend = [
            {"month": item['month_date'].strftime('%b') if item['month_date'] else 'N/A', "rate": round((item['paid'] / item['total'] * 100), 1) if item['total'] > 0 else 0.0}
            for item in bill_by_month
        ]

        return Response({
            "total_expenses": float(total_expenses),
            "collection_rate": collection_rate,
            "monthly_expenses": monthly_expenses,
            "collection_trend": collection_trend,
            "amenity_revenue": 0.0
        }, status=status.HTTP_200_OK)


class AdminSecurityComplaintsReportView(APIView):
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsSuperAdmin]

    def get(self, request):
        society_id = request.query_params.get('society_id')
        complaints_qs = Complaint.objects.all()

        if society_id:
            complaints_qs = complaints_qs.filter(block__society_id=society_id)

        total_complaints = complaints_qs.count()
        resolved_qs = complaints_qs.filter(
            status__iexact='resolved',
            created_at__isnull=False,
            resolved_at__isnull=False
        )
        resolved_count = resolved_qs.count()
        pending_count = total_complaints - complaints_qs.filter(status__iexact='resolved').count()

        avg_duration = resolved_qs.annotate(
            duration=ExpressionWrapper(
                F('resolved_at') - F('created_at'),
                output_field=DurationField()
            )
        ).aggregate(avg_time=Avg('duration'))['avg_time']

        avg_resolution_days = round(avg_duration.total_seconds() / 86400, 1) if avg_duration else 0.0

        return Response({
            "total_complaints": total_complaints,
            "resolved": resolved_count,
            "pending": pending_count,
            "avg_resolution_days": avg_resolution_days
        }, status=status.HTTP_200_OK)


class AdminOperationsReportView(APIView):
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsSuperAdmin]

    def get(self, request):
        society_id = request.query_params.get('society_id')
        visitors_qs = VisitorLogs.objects.all()

        if society_id:
            visitors_qs = visitors_qs.filter(flat__block__society_id=society_id)

        visitor_by_month = visitors_qs.annotate(
            month_date=TruncMonth('entry_time')
        ).values('month_date').annotate(total=Count('log_id')).order_by('month_date')

        monthly_visitors = [
            {"month": item['month_date'].strftime('%b') if item['month_date'] else 'N/A', "count": item['total']}
            for item in visitor_by_month
        ]

        return Response({
            "total_visitors": visitors_qs.count(),
            "monthly_traffic": monthly_visitors,
            "amenity_bookings_count": 0
        }, status=status.HTTP_200_OK)


class OccupancyViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Occupancy.objects.select_related('flat__block__society', 'resident__user').all()
    serializer_class = OccupancySerializer
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsSuperAdmin]

    def get_queryset(self):
        qs = super().get_queryset()
        society_id = self.request.query_params.get('society_id')
        if society_id:
            qs = qs.filter(flat__block__society_id=society_id)
        return qs


class TenantViewSet(viewsets.ModelViewSet):
    http_method_names = ['get', 'patch', 'head', 'options']
    queryset = Tenant.objects.select_related('user', 'owner', 'flat__block__society').all()
    serializer_class = TenantSerializer
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsSuperAdmin]

    def get_queryset(self):
        qs = super().get_queryset()
        society_id = self.request.query_params.get('society_id')
        if society_id:
            qs = qs.filter(flat__block__society_id=society_id)
        return qs

    @action(detail=True, methods=['patch'])
    def update_status(self, request, pk=None):
        tenant = self.get_object()
        new_status = request.data.get('status')
        if not new_status:
            return Response({'error': 'status is required.'}, status=status.HTTP_400_BAD_REQUEST)
        
        tenant.status = new_status
        if new_status.lower() in ['inactive', 'terminated', 'evicted']:
            tenant.move_out_date = timezone.now().date()
        tenant.save()
        
        return Response({'success': True, 'message': f'Tenant status changed to {new_status}'})