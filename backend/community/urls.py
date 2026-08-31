from django.urls import path
from .views import (
    MeetingListCreateView,
    MeetingDetailUpdateView,
    SocietyCommitteeListView,
    CommitteeChangeRequestView,
    HandleCommitteeChangeActionView,
    ActivePollsListView,
    CreatePollView,
    CastVoteView,
    PollDetailDeleteView,
    LostFoundItemClaimView,
    LostFoundItemListCreateView,
    MeetingDetailDeleteView,
    SocietyMembersDropdownListView
)

urlpatterns = [
    # Meetings
    path('meetings/', MeetingListCreateView.as_view(), name='meetings-list-create'),
    path('meetings/<str:meeting_id>/', MeetingDetailUpdateView.as_view(), name='meeting-detail-update'),
    path('meetings/<str:meeting_id>/delete/', MeetingDetailDeleteView.as_view(), name='meeting-delete'),
    # Committee & Roles
    path('committee/', SocietyCommitteeListView.as_view(), name='committee-list'),
    path('committee/change-request/', CommitteeChangeRequestView.as_view(), name='committee-change-request'),
    path('committee/change-request/<str:request_id>/action/', HandleCommitteeChangeActionView.as_view(), name='committee-change-action'),
    path('committee/members-dropdown/', SocietyMembersDropdownListView.as_view(), name='society-members-dropdown'),

    # Polls & Voting
    path('polls/active/', ActivePollsListView.as_view(), name='active-polls'),
    path('polls/create/', CreatePollView.as_view(), name='create-poll'),
    path('polls/vote/', CastVoteView.as_view(), name='cast-vote'),
    path('polls/<str:poll_id>/delete/', PollDetailDeleteView.as_view(), name='delete-poll'),

    # Lost & Found
    path('lost-found/', LostFoundItemListCreateView.as_view(), name='lost-found-list-create'),
    path('lost-found/<str:item_id>/claim/', LostFoundItemClaimView.as_view(), name='lost-found-claim'),
]