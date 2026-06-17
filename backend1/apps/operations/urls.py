from django.urls import path
from . import views

urlpatterns = [
    path('vehicles/', views.manage_vehicles_api, name='api_vehicles'),
    path('vehicles/<str:pk>/', views.mutate_individual_vehicle_api, name='api_vehicle_mutate'),
]