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
from django.db.models import Sum, Count, Q, Case, When, IntegerField
from django.db.models.functions import TruncMonth
from .authentication import AdminJWTAuthentication
from .models import Admin, Societies, SocietyCommittee,SocietyFeatures, Flats,Blocks,Occupancy,Users, CommitteeChange, SocietyExpenses, MaintenanceBill, Complaint, VisitorLogs, Feedback,Roles,Tenant
from .serializers import AdminLoginSerializer, SocietySerializer, SocietyFeaturesSerializer, UserManagementSerializer, CommitteeChangeSerializer,RoleSerializer,OccupancySerializer,TenantSerializer
from .permissions import IsSuperAdmin

JWT_SECRET = getattr(settings, 'SECRET_KEY', 'default_secret_society_admin')
JWT_ALGORITHM = 'HS256'


# 1. Admin Authentication
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
                
                # Payload with 24-hour expiration
                payload = {
                    'admin_id': admin.a_id,
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

# 2. Society Management CRUD
# 2. Society Management CRUD
class SocietyViewSet(viewsets.ModelViewSet):
    queryset = Societies.objects.all()
    serializer_class = SocietySerializer
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsSuperAdmin]

    @transaction.atomic
    def create(self, request, *args, **kwargs):
        # 1. Extract society data, embedded feature flags, and blocks hierarchy
        society_data = request.data.copy()
        has_block_sec = society_data.pop('has_block_secretary', False)
        has_nominee = society_data.pop('has_nominee', True)
        has_sec = society_data.pop('has_security', True)
        blocks_data = society_data.pop('blocks', [])

        # 2. Save Society
        serializer = self.get_serializer(data=society_data)
        serializer.is_valid(raise_exception=True)
        society = serializer.save()

        # 3. Automatically create matching SocietyFeatures row (max 5 chars for config_id)
        config_id = f"C{society.society_id.replace('SOC', '')}"[:5].ljust(5, '0')
        SocietyFeatures.objects.create(
            config_id=config_id,
            society=society,
            has_block_secretary=has_block_sec,
            has_nominee=has_nominee,
            has_security=has_sec
        )

        # 4. Generate Blocks and Flats with strictly <= 5-character IDs
        block_counter = Blocks.objects.count() + 1
        flat_counter = Flats.objects.count() + 1

        for b_item in blocks_data:
            block_name = str(b_item.get('block_name', '')).strip()
            if not block_name:
                continue

            # Ensure unique 5-char block_id (e.g., 'B0001')
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

            # Extract and create flats under this block
            flats_list = b_item.get('flats', [])
            for f_item in flats_list:
                flat_num = str(f_item.get('flat_number', '')).strip()
                floor_num = f_item.get('floor_number', 1)

                if not flat_num:
                    continue

                # Ensure unique 5-char flat_id (e.g., 'F0001')
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
        """Soft delete / restore society status"""
        society = self.get_object()
        society.society_status = 'inactive' if society.society_status == 'active' else 'active'
        society.save()
        return Response({
            "message": f"Society is now {society.society_status}",
            "society_status": society.society_status
        }, status=status.HTTP_200_OK)

# 3. Society Feature Configuration
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


# 4. Global User Management
# views.py -> Inside UserManagementViewSet

class UserManagementViewSet(viewsets.ModelViewSet):
    http_method_names = ['get', 'post','put', 'patch', 'head', 'options']
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
        """
        Direct role assignment for bootstrap scenario.
        Allowed ONLY if the society does not yet have an active Chairman.
        Once an active Chairman exists, all committee appointments must 
        go through the two-way dual approval process.
        """
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

        # Check if an active Chairman already exists for this society
        has_active_chairman = SocietyCommittee.objects.filter(
            society=user.society,
            role__role_name__iexact='Chairman',
            status='Active'
        ).exists()

        is_assigning_committee_role = new_role.role_name.lower() in [
            'chairman', 'secretary', 'treasurer', 'committee member'
        ]

        # If a Chairman already exists, block direct assignment for any committee role
        if has_active_chairman and is_assigning_committee_role:
            return Response({
                'success': False,
                'error': (
                    f"'{user.society.society_name}' already has an active Chairman. "
                    "All subsequent committee appointments or changes must be initiated "
                    "via dual approval (Committee Change Request)."
                )
            }, status=status.HTTP_400_BAD_REQUEST)

        # 1. Update User's role
        user.role = new_role
        user.save()

        # 2. If assigning the bootstrap Chairman (or any committee role prior to Chairman lock), record in SocietyCommittee
        if is_assigning_committee_role:
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
            'message': f"Role '{new_role.role_name}' assigned directly to {user.user_name}.",
            'user': UserManagementSerializer(user).data
        }, status=status.HTTP_200_OK)

    
# 5. Committee Change Requests
# views.py -> Replace CommitteeChangeViewSet
class CommitteeChangeViewSet(viewsets.ModelViewSet):
    queryset = CommitteeChange.objects.all().order_by('-request_id')
    serializer_class = CommitteeChangeSerializer
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsSuperAdmin]

    def create(self, request, *args, **kwargs):
        """
        Super Admin initiates a committee role change.
        Status is set to 'Pending_Chairman_Approval' so the Chairman must approve on the app.
        """
        target_user_id = request.data.get('target_user')
        new_role_id = request.data.get('new_role')

        if not target_user_id or not new_role_id:
            return Response(
                {'error': 'target_user and new_role are required.'}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        target_user = Users.objects.get(user_id=target_user_id)
        new_role = Roles.objects.get(role_id=new_role_id)

        change_req = CommitteeChange.objects.create(
            request_id=f"REQ{str(uuid.uuid4())[:6].upper()}",
            requested_by=None,  # Initiated by Super Admin
            target_user=target_user,
            new_role=new_role,
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
        """Super Admin approves requests created by Chairman."""
        req_obj = self.get_object()

        # Enforce direction: Admin can only approve requests pending Admin approval
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

        # 1. Update status
        req_obj.status = 'Approved'
        req_obj.save()

        # 2. Apply role to User
        target_user = req_obj.target_user
        if target_user and req_obj.new_role:
            target_user.role = req_obj.new_role
            target_user.save()

            # 3. Update SocietyCommittee
            society = target_user.society
            if society:
                comm_member, _ = SocietyCommittee.objects.get_or_create(
                    user=target_user,
                    society=society,
                    defaults={
                        'committee_id': str(uuid.uuid4())[:6].upper(),
                        'role': req_obj.new_role,
                        'election_date': timezone.now().date(),
                        'status': 'Active'
                    }
                )
                comm_member.role = req_obj.new_role
                comm_member.status = 'Active'
                comm_member.save()

        return Response({
            'success': True,
            'message': 'Committee role change approved and applied.',
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
        req_obj.save()

        return Response({
            'success': True,
            'message': 'Committee role change request rejected.',
            'request': CommitteeChangeSerializer(req_obj).data
        }, status=status.HTTP_200_OK)

# 6. Executive MIS Report Analytics Endpoint
class AdminReportsView(APIView):
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsSuperAdmin]

    def get(self, request):
        society_id = request.query_params.get('society_id')

        # 1. Base Querysets
        flats_qs = Flats.objects.all()
        occupancy_qs = Occupancy.objects.all()
        expenses_qs = SocietyExpenses.objects.all()
        bills_qs = MaintenanceBill.objects.all()
        complaints_qs = Complaint.objects.all()
        visitors_qs = VisitorLogs.objects.all()

        # Dynamic filter by society if selected
        if society_id:
            flats_qs = flats_qs.filter(block__society_id=society_id)
            occupancy_qs = occupancy_qs.filter(flat__block__society_id=society_id)
            expenses_qs = expenses_qs.filter(society_id=society_id)
            bills_qs = bills_qs.filter(flat__block__society_id=society_id)
            complaints_qs = complaints_qs.filter(block__society_id=society_id)
            visitors_qs = visitors_qs.filter(flat__block__society_id=society_id)

        # 2. Dynamic Occupancy Breakdown
        total_flats = flats_qs.count()
        owner_count = occupancy_qs.filter(occupancy_type__iexact='Owner').count()
        tenant_count = occupancy_qs.filter(occupancy_type__iexact='Tenant').count()
        vacant_count = max(0, total_flats - (owner_count + tenant_count))

        # 3. Dynamic Overall Financial KPIs
        total_expenses = expenses_qs.aggregate(total=Sum('amount'))['total'] or 0.0
        total_bills = bills_qs.count()
        paid_bills = bills_qs.filter(status__iexact='paid').count()
        collection_rate = round((paid_bills / total_bills * 100), 1) if total_bills > 0 else 0.0

        # 4. Dynamic Monthly Expenses Trend (Grouped by payment_date)
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

        # 5. Dynamic Monthly Collection Rate Trend (Grouped by due_date or bill_month)
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

        # 6. Dynamic Complaints & SLA Resolution
        filed_count = complaints_qs.count()
        resolved_count = complaints_qs.filter(status__iexact='resolved').count()

        # 7. Dynamic Monthly Visitor Traffic (Grouped by entry_time)
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
                "avg_resolution_days": 3  # Calculated or default
            },
            "visitors": {
                "monthly_traffic": monthly_visitors
            }
        }, status=status.HTTP_200_OK)

class AdminProfileView(APIView):
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsSuperAdmin]

    def get(self, request):
        admin = request.user
        return Response({
            "admin_id": admin.a_id,
            "username": admin.a_username,
            "email": admin.a_email
        }, status=status.HTTP_200_OK)

    def put(self, request):
        admin = request.user
        username = request.data.get('username')
        email = request.data.get('email')
        current_password = request.data.get('current_password')
        new_password = request.data.get('new_password')

        # 1. Update basic info
        if username:
            admin.a_username = username
        if email:
            # Check unique email constraint
            if Admin.objects.filter(a_email=email).exclude(a_id=admin.a_id).exists():
                return Response({"error": "Email is already in use by another admin."}, status=status.HTTP_400_BAD_REQUEST)
            admin.a_email = email

        # 2. Password change logic
        if new_password:
            if not current_password:
                return Response({"error": "Current password is required to set a new password."}, status=status.HTTP_400_BAD_REQUEST)
            if admin.a_password != current_password:
                return Response({"error": "Current password does not match."}, status=status.HTTP_400_BAD_REQUEST)
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

# views.py -> AdminOverviewDashboardView
class AdminOverviewDashboardView(APIView):
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsSuperAdmin]

    def get(self, request):
        total_societies = Societies.objects.count()
        total_users = Users.objects.count()
        active_societies_count = Societies.objects.filter(society_status__iexact='active').count()

        # Split pending counts
        pending_admin_count = CommitteeChange.objects.filter(status='Pending_Admin_Approval').count()
        pending_chairman_count = CommitteeChange.objects.filter(status='Pending_Chairman_Approval').count()

        # Fetch requests that need attention (prioritize requests awaiting Admin action)
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

# 1. Financial Analytics View
class AdminFinancialsReportView(APIView):
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsSuperAdmin]

    def get(self, request):
        society_id = request.query_params.get('society_id')
        month = request.query_params.get('month')  # e.g., '2026-05' or '05'

        expenses_qs = SocietyExpenses.objects.all()
        bills_qs = MaintenanceBill.objects.all()

        if society_id:
            expenses_qs = expenses_qs.filter(society_id=society_id)
            bills_qs = bills_qs.filter(flat__block__society_id=society_id)

        if month:
            # Filter by month if passed
            if '-' in month:  # YYYY-MM
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

        # Monthly Expense Trend
        expense_by_month = expenses_qs.annotate(
            month_date=TruncMonth('payment_date')
        ).values('month_date').annotate(total=Sum('amount')).order_by('month_date')

        monthly_expenses = [
            {"month": item['month_date'].strftime('%b') if item['month_date'] else 'N/A', "amount": float(item['total'])}
            for item in expense_by_month
        ]

        # Monthly Collection Trend
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


# 2. Security & Complaints View
class AdminSecurityComplaintsReportView(APIView):
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsSuperAdmin]

    def get(self, request):
        society_id = request.query_params.get('society_id')
        complaints_qs = Complaint.objects.all()

        if society_id:
            complaints_qs = complaints_qs.filter(block__society_id=society_id)

        total_complaints = complaints_qs.count()
        resolved_count = complaints_qs.filter(status__iexact='resolved').count()
        pending_count = total_complaints - resolved_count

        return Response({
            "total_complaints": total_complaints,
            "resolved": resolved_count,
            "pending": pending_count,
            "avg_resolution_days": 3
        }, status=status.HTTP_200_OK)


# 3. Operations & Visitors View
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

# views.py
from .models import Occupancy, Tenant
from .serializers import OccupancySerializer, TenantSerializer

class OccupancyViewSet(viewsets.ReadOnlyModelViewSet):
    """Read-only view for platform-level occupancy audits."""
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
    """Allows Super Admin to audit tenants or terminate/evict in disputes."""
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