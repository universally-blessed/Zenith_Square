from django.urls import path
from .views import (
    PublicSocietiesView,
    PublicBlocksView,
    RegisterResidentView,
    VerifyOTPView,
    LoginView,
    RequestPasswordResetView,
    ConfirmPasswordResetView,
    UserProfileView,
    ChangePasswordView,
    NomineeView,
)

urlpatterns = [
    # Operational endpoints
    path('societies/', PublicSocietiesView.as_view(), name='public-societies'),
    path('societies/<str:society_id>/blocks/', PublicBlocksView.as_view(), name='public-blocks'),

    # Auth endpoints
    path('auth/register/', RegisterResidentView.as_view(), name='register-resident'),
    path('auth/verify-otp/', VerifyOTPView.as_view(), name='verify-otp'),
    path('auth/login/', LoginView.as_view(), name='login'),
    path('auth/forgot-password/', RequestPasswordResetView.as_view(), name='forgot-password'),
    path('auth/reset-password-confirm/', ConfirmPasswordResetView.as_view(), name='reset-password-confirm'),

    path('profile/', UserProfileView.as_view(), name='user-profile'),
    path('profile/change-password/', ChangePasswordView.as_view(), name='change-password'),
    path('profile/nominee/', NomineeView.as_view(), name='nominee-management'),
]