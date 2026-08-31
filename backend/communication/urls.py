from django.urls import path
from .views import NoticeListCreateView, NoticeDetailDeleteView

urlpatterns = [
    path('notices/', NoticeListCreateView.as_view(), name='notices-list-create'),
    path('notices/<str:notice_id>/', NoticeDetailDeleteView.as_view(), name='notice-delete'),
]