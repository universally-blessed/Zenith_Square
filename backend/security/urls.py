from django.urls import path
from .views import (
    TriggerEmergencyAlertView,
    ActiveSecurityAlertsView,
    DismissSecurityAlertView,
    VisitorLogsListCreateView,
    LogVisitorExitView,
)

urlpatterns = [
    # Emergency Alerts
    path('trigger-emergency/', TriggerEmergencyAlertView.as_view(), name='trigger-emergency'),
    path('alerts/', ActiveSecurityAlertsView.as_view(), name='active-alerts'),
    path('alerts/<str:alert_id>/dismiss/', DismissSecurityAlertView.as_view(), name='dismiss-alert'),

    # Visitor Gate Management
    path('visitors/logs/', VisitorLogsListCreateView.as_view(), name='visitor-logs'),
    path('visitors/logs/<int:log_id>/exit/', LogVisitorExitView.as_view(), name='visitor-exit'),
]