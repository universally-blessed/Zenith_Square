from django.contrib import admin
from django.urls import path,include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/',include('core_api.urls')),
    path('api/finance/',include('finance.urls')),
    path('api/helpdesk/', include('helpdesk.urls')),
    path('api/communication/',include('communication.urls')),
    path('api/facilities/',include('facilities.urls')),
    path('api/community/',include('community.urls')),
    path('api/security/',include('security.urls')),
]
