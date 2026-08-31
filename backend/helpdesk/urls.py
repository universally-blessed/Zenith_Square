from django.urls import path
from .views import ComplaintListCreateView, UpdateComplaintStatusView, FeedbackView

urlpatterns = [
    path('complaints/', ComplaintListCreateView.as_view(), name='complaints-list-create'),
    path('complaints/<str:complaint_id>/status/', UpdateComplaintStatusView.as_view(), name='complaint-status-update'),
    path('feedback/', FeedbackView.as_view(), name='feedback-view'),
]