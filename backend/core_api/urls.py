from django.urls import path# type: ignore
from . import views

urlpatterns = [
    path('auth/register/', views.register_resident, name='api_register'),
    path('auth/login/', views.login_user, name='api_login'),
    path('auth/change-password/', views.change_password, name='api_change_password'),
]