from rest_framework.permissions import BasePermission
from .models import Admin

class IsSuperAdmin(BasePermission):
    """
    Allows access only to authenticated Super Admins from the admin table.
    """
    def has_permission(self, request, view):
        return bool(request.user and isinstance(request.user, Admin))