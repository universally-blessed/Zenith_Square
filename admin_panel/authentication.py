import jwt
from django.conf import settings
from rest_framework import authentication, exceptions
from .models import Admin

JWT_SECRET = getattr(settings, 'SECRET_KEY', 'default_secret_society_admin')
JWT_ALGORITHM = 'HS256'

class AdminJWTAuthentication(authentication.BaseAuthentication):
    def authenticate(self, request):
        auth_header = authentication.get_authorization_header(request).split()

        # If no header is provided, return None (DRF will challenge with 401 via authenticate_header)
        if not auth_header:
            return None

        if len(auth_header) != 2 or auth_header[0].lower() != b'bearer':
            raise exceptions.AuthenticationFailed("Invalid token header. Format must be 'Bearer <token>'")

        token = auth_header[1].decode('utf-8')

        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
            admin_id = payload.get('admin_id')
            
            if not admin_id:
                raise exceptions.AuthenticationFailed("Invalid token payload")

            admin = Admin.objects.get(a_id=admin_id)
            return (admin, token)

        except jwt.ExpiredSignatureError:
            raise exceptions.AuthenticationFailed("Session token has expired. Please log in again.")
        except (jwt.DecodeError, jwt.InvalidTokenError):
            raise exceptions.AuthenticationFailed("Invalid or corrupted authentication token.")
        except Admin.DoesNotExist:
            raise exceptions.AuthenticationFailed("Admin account associated with this token does not exist.")

    def authenticate_header(self, request):
        """
        Returns a string that will be used as the value of the WWW-Authenticate
        header in a 401 response when authentication fails or is missing.
        """
        return 'Bearer realm="api"'