from django.urls import path, include

urlpatterns = [
    path('api/admin/', include('admin_panel.urls')),
]