from django.urls import path # type: ignore
from . import views

urlpatterns = [
    path('auth/register/', views.register_resident, name='api_register'),
    path('auth/login/', views.login_user, name='api_login'),
    path('auth/change-password/', views.change_password, name='api_change_password'),
    path('auth/verify-otp/', views.verify_registration_otp, name='api_verify_otp'),
    path('auth/forgot-password/', views.request_password_reset, name='api_forgot_password'),
    
    path('public/societies/', views.list_societies_public, name='api_public_societies'),
    path('public/societies/<str:society_id>/blocks/', views.list_blocks_by_society, name='api_public_blocks'),

    path('vehicles/', views.manage_vehicles_api, name='api_vehicles'),
    path('vehicles/<str:pk>/', views.mutate_individual_vehicle_api, name='api_vehicle_mutate'),
    
    path('complaints/', views.manage_complaints_api, name='api_complaints'),
    path('bookings/', views.manage_amenity_bookings_api, name='api_bookings'),
    path('lost-found/', views.manage_lost_found_board, name='api_lost_found_root'),
    
    path('maintenance/current/', views.get_latest_maintenance_bill, name='api_current_bill'),
    path('maintenance/pay/', views.settle_maintenance_payment, name='api_pay_bill'),
    path('payments/history/', views.get_payment_history, name='api_payment_history'),
    path('expenses/', views.society_expense_report_api, name='api_expenses'),
    
    path('resident/dashboard-meta/', views.get_resident_dashboard_meta, name='api_dashboard_meta'),
    path('polls/active/', views.get_active_polls, name='api_active_polls'),
    path('polls/vote/', views.cast_poll_vote, name='api_cast_vote'),
    path('broadcasts/notices/', views.get_society_notices, name='api_notices'),
    path('broadcasts/meetings/', views.get_society_meetings, name='api_meetings'),

    path('resident/update-profile/', views.update_profile_details, name='api_update_profile'),
    path('resident/nominee/', views.manage_resident_nominee, name='api_resident_nominee'),
]