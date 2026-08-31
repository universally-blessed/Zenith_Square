from django.contrib import admin
from .models import Societies, SocietyFeatures, Blocks, Flats, Roles, Users, Resident

@admin.register(Societies)
class SocietiesAdmin(admin.ModelAdmin):
    list_display = ('society_id', 'society_name', 'society_city', 'society_status')
    search_fields = ('society_name', 'society_city')

@admin.register(Blocks)
class BlocksAdmin(admin.ModelAdmin):
    list_display = ('block_id', 'block_name', 'society')
    list_filter = ('society',)

@admin.register(Flats)
class FlatsAdmin(admin.ModelAdmin):
    list_display = ('flat_id', 'flat_number', 'block', 'floor_number')
    list_filter = ('block__society', 'block')

@admin.register(Roles)
class RolesAdmin(admin.ModelAdmin):
    list_display = ('role_id', 'role_name')

@admin.register(Users)
class UsersAdmin(admin.ModelAdmin):
    list_display = ('user_name', 'user_phone', 'user_email', 'role', 'is_active', 'is_staff')
    search_fields = ('user_name', 'user_phone', 'user_email')
    list_filter = ('role', 'is_active')

@admin.register(Resident)
class ResidentAdmin(admin.ModelAdmin):
    list_display = ('resident_id', 'user', 'flat', 'move_in_date')