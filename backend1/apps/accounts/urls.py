from django.urls import path
from . import views

urlpatterns = [
    path('login/', views.login_user, name='login'),
    path('register/', views.register_resident, name='register'),
    path('verify-otp/', views.verify_registration_otp, name='verify_otp'),
    path('change-password/', views.change_password, name='change_password'),
    path('forgot-password/', views.request_password_reset, name='forgot_password'),
    # path('resident/dashboard-meta/', views.get_resident_dashboard_meta, name='api_dashboard_meta'),#done
    # path('resident/update-profile/', views.update_profile_details, name='api_update_profile'),
    # path('resident/nominee/', views.manage_resident_nominee, name='api_resident_nominee'),
]