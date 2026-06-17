from django.urls import path
from . import views

urlpatterns = [
    # PUBLIC ACCESS (For sign-up)
    path('societies/', views.list_societies_public, name='api_public_societies'),
    path('societies/<str:society_id>/blocks/', views.list_blocks_by_society, name='api_public_blocks'),
    
    # ASSET MANAGEMENT (Chairman-only)
    # path('assets/', views.manage_assets_api, name='api_assets'),
    # path('amenities/', views.list_amenities_api, name='api_amenities'),
]