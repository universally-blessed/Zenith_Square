# from rest_framework.test import APITestCase
# from rest_framework import status
# from .models import Admin, Societies, SocietyFeatures, Users, Roles, CommitteeChange

# class AdminPanelAPITests(APITestCase):

#     def setUp(self):
#         # 1. Super Admin
#         self.admin = Admin.objects.create(
#             a_username="superadmin",
#             a_email="admin@society.com",
#             a_password="admin123"
#         )

#         # 2. Base Society (IDs must be <= 5 chars)
#         self.society = Societies.objects.create(
#             society_id="SOC01",
#             society_name="Greenwood Residency",
#             society_address="123 Main Avenue, High Tech City",
#             society_city="Ahmedabad",
#             society_pincode="380015",
#             society_email="contact@greenwood.com",
#             society_phone="9876543210",
#             standard_rate=2500.00,
#             late_fee_percent=5.00,
#             billing_cycle="MONTHLY",
#             society_status="active"
#         )

#         # 3. Role (ID <= 5 chars)
#         self.role = Roles.objects.create(
#             role_id="ROL01",
#             role_name="Chairman"
#         )

#         # 4. Society User (All IDs <= 5 chars, Phone exactly 10 digits)
#         self.user = Users.objects.create(
#             user_id="USR01",
#             society=self.society,
#             user_name="Rajesh Sharma",
#             user_phone="9898989898",
#             user_email="rajesh@society.com",
#             role=self.role,
#             password="password123",
#             is_active=True
#         )

#     # Test 1: Admin Login (Success)
#     def test_admin_login_success(self):
#         url = "/api/admin/auth/login/"
#         payload = {
#             "email": "admin@society.com",
#             "password": "admin123"
#         }
#         response = self.client.post(url, payload, format='json')
#         self.assertEqual(response.status_code, status.HTTP_200_OK)
#         self.assertEqual(response.data["email"], "admin@society.com")

#     # Test 2: Admin Login (Failure)
#     def test_admin_login_failure(self):
#         url = "/api/admin/auth/login/"
#         payload = {
#             "email": "admin@society.com",
#             "password": "wrongpassword"
#         }
#         response = self.client.post(url, payload, format='json')
#         self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

#     # Test 3: Create Society
#     def test_create_society(self):
#         url = "/api/admin/societies/"
#         payload = {
#             "society_id": "SOC02",
#             "society_name": "Sunrise Heights",
#             "society_address": "456 Park Road",
#             "society_city": "Mumbai",
#             "society_pincode": "400001",
#             "society_email": "info@sunrise.com",
#             "society_phone": "9123456780",
#             "standard_rate": 3000.00,
#             "late_fee_percent": 2.50,
#             "billing_cycle": "MONTHLY",
#             "society_status": "active"
#         }
#         response = self.client.post(url, payload, format='json')
#         self.assertEqual(response.status_code, status.HTTP_201_CREATED)
#         self.assertEqual(Societies.objects.filter(society_id="SOC02").count(), 1)

#     # Test 4: Configure Society Features
#     def test_configure_society_features(self):
#         url = "/api/admin/society-features/"
#         payload = {
#             "config_id": "CFG01",
#             "society": "SOC01",
#             "has_block_secretary": True,
#             "has_nominee": True,
#             "has_security": True
#         }
#         response = self.client.post(url, payload, format='json')
#         self.assertEqual(response.status_code, status.HTTP_201_CREATED)
#         self.assertEqual(SocietyFeatures.objects.filter(config_id="CFG01").count(), 1)

#     # Test 5: Create User
#     def test_create_user(self):
#         url = "/api/admin/users/"
#         payload = {
#             "user_id": "USR02",
#             "society": "SOC01",
#             "user_name": "Priya Patel",
#             "user_phone": "9797979797",
#             "user_email": "priya@society.com",
#             "role": "ROL01",
#             "password": "userpass456",
#             "is_active": True
#         }
#         response = self.client.post(url, payload, format='json')
#         self.assertEqual(response.status_code, status.HTTP_201_CREATED)
#         self.assertEqual(Users.objects.filter(user_id="USR02").count(), 1)

#     # Test 6: Create Committee Change Request (request_id <= 6 chars)
#     def test_create_committee_change_request(self):
#         url = "/api/admin/committee-requests/"
#         payload = {
#             "request_id": "REQ01",
#             "requested_by": "USR01",
#             "target_user": "USR01",
#             "new_role": "ROL01",
#             "status": "Pending"
#         }
#         response = self.client.post(url, payload, format='json')
#         self.assertEqual(response.status_code, status.HTTP_201_CREATED)
#         self.assertEqual(CommitteeChange.objects.filter(request_id="REQ01").count(), 1)

#     # Test 7: Analytics Summary Report
#     def test_get_summary_report(self):
#         url = "/api/admin/reports/summary/?society_id=SOC01"
#         response = self.client.get(url)
#         self.assertEqual(response.status_code, status.HTTP_200_OK)
#         self.assertIn("financial_overview", response.data)
#         self.assertIn("complaint_metrics", response.data)
# #         self.assertIn("visitor_traffic", response.data)
# import jwt
# from datetime import datetime, timedelta, timezone
# from django.conf import settings
# from rest_framework.test import APITestCase
# from rest_framework import status
# from .models import Admin, Societies, Roles, Users

# JWT_SECRET = getattr(settings, 'SECRET_KEY', 'default_secret_society_admin')

# class AdminPanelAPITests(APITestCase):

#     def setUp(self):
#         # 1. Admin
#         self.admin = Admin.objects.create(
#             a_username="superadmin",
#             a_email="admin@society.com",
#             a_password="admin123"
#         )

#         # Generate valid test JWT token
#         payload = {
#             'admin_id': self.admin.a_id,
#             'username': self.admin.a_username,
#             'email': self.admin.a_email,
#             'exp': datetime.now(timezone.utc) + timedelta(hours=1),
#         }
#         self.token = jwt.encode(payload, JWT_SECRET, algorithm='HS256')
#         # Attach Bearer token to all test client requests
#         self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')

#         # 2. Society
#         self.society = Societies.objects.create(
#             society_id="SOC01",
#             society_name="Greenwood Residency",
#             society_address="123 Main Avenue, High Tech City",
#             society_city="Ahmedabad",
#             society_pincode="380015",
#             society_phone="9876543210",
#             standard_rate=2500.00,
#             late_fee_percent=5.00,
#             billing_cycle="MONTHLY",
#             society_status="active"
#         )

#         # 3. Role
#         self.role = Roles.objects.create(role_id="ROL01", role_name="Chairman")

#         # 4. User
#         self.user = Users.objects.create(
#             user_id="USR01",
#             society=self.society,
#             user_name="Rajesh Sharma",
#             user_phone="9898989898",
#             role=self.role,
#             password="password123",
#             is_active=True
#         )

#     # Test Unauthenticated Access Rejection
#     def test_unauthorized_request_rejected(self):
#         self.client.credentials()  # Clear Authorization header
#         response = self.client.get("/api/admin/societies/")
#         self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
import jwt
from datetime import datetime, timedelta, timezone
from django.conf import settings
from rest_framework.test import APITestCase
from rest_framework import status
from .models import Admin, Societies, Roles, Users, CommitteeChange, SocietyCommittee

JWT_SECRET = getattr(settings, 'SECRET_KEY', 'default_secret_society_admin')

class AdminPanelAPITests(APITestCase):

    def setUp(self):
        # 1. Super Admin (Decoupled from society)
        self.admin = Admin.objects.create(
            a_username="superadmin",
            a_email="admin@society.com",
            a_password="admin123"
        )

        # Generate Bearer JWT Token for Super Admin
        payload = {
            'admin_id': self.admin.a_id,
            'username': self.admin.a_username,
            'email': self.admin.a_email,
            'exp': datetime.now(timezone.utc) + timedelta(hours=1),
        }
        self.token = jwt.encode(payload, JWT_SECRET, algorithm='HS256')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')

        # 2. Base Society
        self.society = Societies.objects.create(
            society_id="SOC01",
            society_name="Greenwood Residency",
            society_address="123 Main Avenue",
            society_city="Ahmedabad",
            society_pincode="380015",
            society_phone="9876543210",
            standard_rate=2500.00,
            late_fee_percent=5.00,
            billing_cycle="MONTHLY",
            society_status="active"
        )

        # 3. Roles
        self.chairman_role = Roles.objects.create(role_id="ROL01", role_name="Chairman")
        self.secretary_role = Roles.objects.create(role_id="ROL02", role_name="Secretary")
        self.resident_role = Roles.objects.create(role_id="ROL03", role_name="Resident")

        # 4. Initiator (Chairman) & Target Member (Resident)
        self.chairman_user = Users.objects.create(
            user_id="USR01",
            society=self.society,
            user_name="Rajesh Sharma",
            user_phone="9898989898",
            user_email="rajesh@society.com",
            role=self.chairman_role,
            password="password123",
            is_active=True
        )

        self.target_user = Users.objects.create(
            user_id="USR02",
            society=self.society,
            user_name="Amit Verma",
            user_phone="9797979797",
            user_email="amit@society.com",
            role=self.resident_role,
            password="password123",
            is_active=True
        )

    # Test 1: Super Admin Approves Pending_Admin_Approval Request
    def test_approve_committee_change_request_success(self):
        # Create a pending role change request submitted by the Chairman
        req = CommitteeChange.objects.create(
            request_id="REQ01",
            requested_by=self.chairman_user,
            target_user=self.target_user,
            new_role=self.secretary_role,
            status="Pending_Admin_Approval"
        )

        url = f"/api/admin/committee-requests/{req.request_id}/approve/"
        response = self.client.post(url, format='json')

        # 1. Check HTTP response
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data["success"])

        # 2. Verify status changed to Approved in CommitteeChange
        req.refresh_from_db()
        self.assertEqual(req.status, "Approved")

        # 3. Verify target user's role updated in Users table
        self.target_user.refresh_from_db()
        self.assertEqual(self.target_user.role, self.secretary_role)

        # 4. Verify SocietyCommittee active record was created
        comm_exists = SocietyCommittee.objects.filter(
            user=self.target_user,
            society=self.society,
            role=self.secretary_role,
            status="Active"
        ).exists()
        self.assertTrue(comm_exists)

    # Test 2: Super Admin Rejects Pending_Admin_Approval Request
    def test_reject_committee_change_request_success(self):
        req = CommitteeChange.objects.create(
            request_id="REQ02",
            requested_by=self.chairman_user,
            target_user=self.target_user,
            new_role=self.secretary_role,
            status="Pending_Admin_Approval"
        )

        url = f"/api/admin/committee-requests/{req.request_id}/reject/"
        response = self.client.post(url, format='json')

        # 1. Check HTTP response
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data["success"])

        # 2. Verify status changed to Rejected
        req.refresh_from_db()
        self.assertEqual(req.status, "Rejected")

        # 3. Verify target user's role remains unchanged (still Resident)
        self.target_user.refresh_from_db()
        self.assertEqual(self.target_user.role, self.resident_role)

    # Test 3: Attempting to Approve an Already Processed Request Fails
    def test_approve_already_approved_request_fails(self):
        req = CommitteeChange.objects.create(
            request_id="REQ03",
            requested_by=self.chairman_user,
            target_user=self.target_user,
            new_role=self.secretary_role,
            status="Approved"
        )

        url = f"/api/admin/committee-requests/{req.request_id}/approve/"
        response = self.client.post(url, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(response.data["success"])

def test_unified_committee_action_approve(self):
        req = CommitteeChange.objects.create(
            request_id="REQ99",
            requested_by=self.chairman_user,
            target_user=self.target_user,
            new_role=self.secretary_role,
            status="Pending_Admin_Approval"
        )

        url = f"/api/admin/committee-requests/{req.request_id}/action/"
        response = self.client.post(url, {"action": "Approved"}, format='json')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data["success"])
        
        req.refresh_from_db()
        self.assertEqual(req.status, "Approved")
        
        self.target_user.refresh_from_db()
        self.assertEqual(self.target_user.role, self.secretary_role)

# tests.py -> Add to AdminPanelAPITests

# Test Scenario 1: Super Admin Directly Assigns Initial Role
def test_assign_initial_role_direct(self):
    url = f"/api/admin/users/{self.target_user.user_id}/assign-initial-role/"
    response = self.client.post(url, {"role_id": self.secretary_role.role_id}, format='json')
    self.assertEqual(response.status_code, status.HTTP_200_OK)
    self.target_user.refresh_from_db()
    self.assertEqual(self.target_user.role, self.secretary_role)
    # Confirm Committee record was created
    comm_exists = SocietyCommittee.objects.filter(
        user=self.target_user,
        role=self.secretary_role,
        status="Active"
    ).exists()
    self.assertTrue(comm_exists)
# Test Scenario 2A: Super Admin Proposes Role Change (Pending Chairman Approval)
def test_admin_initiate_committee_change_request(self):
    url = "/api/admin/committee-requests/"
    payload = {
        "target_user": self.target_user.user_id,
        "new_role": self.secretary_role.role_id
    }
    response = self.client.post(url, payload, format='json')
    self.assertEqual(response.status_code, status.HTTP_201_CREATED)
    self.assertEqual(response.data["status"], "Pending_Chairman_Approval")
    # Ensure target user role has NOT changed yet
    self.target_user.refresh_from_db()
    self.assertEqual(self.target_user.role, self.resident_role)
# Test Scenario 2B: Super Admin Cannot Approve Their Own Initiated Request
def test_admin_cannot_approve_pending_chairman_request(self):
    req = CommitteeChange.objects.create(
        request_id="REQ50",
        requested_by=None,
        target_user=self.target_user,
        new_role=self.secretary_role,
        status="Pending_Chairman_Approval"
    )
    url = f"/api/admin/committee-requests/{req.request_id}/approve/"
    response = self.client.post(url, format='json')
    self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    self.assertFalse(response.data["success"])
    # Status and user remain unchanged
    req.refresh_from_db()
    self.assertEqual(req.status, "Pending_Chairman_Approval")