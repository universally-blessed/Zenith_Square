from django.urls import path
from .views import (
    AmenityListCreateView,
    BookAmenityView,
    AmenityBookingsView,
    ConfirmAmenityPaymentView,
    CancelAmenityBookingView,
    AssetListCreateView,
    AssetMaintenanceListCreateView,
    VehicleDetailDeleteView,
    VehicleListCreateView,
    AmenityStatusUpdateView,
    AssetDetailDeleteView
)

urlpatterns = [
    # Amenities & Bookings
    path('amenities/', AmenityListCreateView.as_view(), name='amenity-list-create'),
    path('amenities/book/', BookAmenityView.as_view(), name='amenity-book'),
    path('amenities/bookings/', AmenityBookingsView.as_view(), name='amenity-bookings'),
    path('amenities/bookings/<str:booking_id>/confirm-payment/', ConfirmAmenityPaymentView.as_view(), name='confirm-booking-payment'),
    path('amenities/bookings/<str:booking_id>/cancel/', CancelAmenityBookingView.as_view(), name='cancel-booking'),
    path('amenities/<str:amenity_id>/status/', AmenityStatusUpdateView.as_view(), name='amenity-status-update'),

    # Assets & Maintenance
    path('assets/', AssetListCreateView.as_view(), name='asset-list-create'),
    path('assets/<str:asset_id>/maintenance/', AssetMaintenanceListCreateView.as_view(), name='asset-maintenance-list-create'),
    path('assets/<str:asset_id>/', AssetDetailDeleteView.as_view(), name='asset-delete'),

    path('vehicles/', VehicleListCreateView.as_view(), name='vehicle-list-create'),
    path('vehicles/<str:vehicle_id>/', VehicleDetailDeleteView.as_view(), name='vehicle-detail-delete'),
]