from django.urls import path #type:ignore
from . import views

urlpatterns = [
    path('polls/active/', views.get_active_polls, name='api_active_polls'),
    path('polls/vote/', views.cast_poll_vote, name='api_cast_vote'),
    path('notices/', views.get_society_notices, name='api_notices'),
    path('meetings/', views.get_society_meetings, name='api_meetings'),
]