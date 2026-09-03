from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    AdminLoginView, 
    SocietyViewSet, 
    SocietyFeaturesViewSet, 
    UserManagementViewSet, 
    CommitteeChangeViewSet,
    AdminReportsView,
    AdminProfileView,
    AdminOverviewDashboardView,
    RoleViewSet,AdminFinancialsReportView,AdminSecurityComplaintsReportView,AdminOperationsReportView,
    OccupancyViewSet,TenantViewSet
)

router = DefaultRouter()
router.register(r'societies', SocietyViewSet, basename='society')
router.register(r'society-features', SocietyFeaturesViewSet, basename='society-features')
router.register(r'users', UserManagementViewSet, basename='user-management')
router.register(r'committee-requests', CommitteeChangeViewSet, basename='committee-requests')
router.register(r'roles', RoleViewSet, basename='roles')
router.register(r'occupancies', OccupancyViewSet, basename='occupancy')
router.register(r'tenants', TenantViewSet, basename='tenant')

urlpatterns = [
    path('auth/login/', AdminLoginView.as_view(), name='admin-login'),
    path('profile/', AdminProfileView.as_view(), name='admin-profile'),
    path('dashboard/overview/', AdminOverviewDashboardView.as_view(), name='dashboard-overview'),
    path('reports/summary/', AdminReportsView.as_view(), name='reports-summary'),
    path('reports/financials/', AdminFinancialsReportView.as_view(), name='reports-financials'),
    path('reports/security-complaints/', AdminSecurityComplaintsReportView.as_view(), name='reports-security-complaints'),
    path('reports/operations/', AdminOperationsReportView.as_view(), name='reports-operations'),
    path('', include(router.urls)),
]