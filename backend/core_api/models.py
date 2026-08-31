# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#   * Rearrange models' order
#   * Make sure each model has one field with primary_key=True
#   * Make sure each ForeignKey and OneToOneField has `on_delete` set to the desired behavior
#   * Remove `managed = False` lines if you wish to allow Django to create, modify, and delete the table
# Feel free to rename the models, but don't rename db_table values or field names.
from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
import random

class Admin(models.Model):
    a_id = models.AutoField(primary_key=True)
    a_username = models.CharField(max_length=255)
    a_email = models.CharField(unique=True, max_length=255)
    a_password = models.CharField(max_length=255)

    class Meta:
        managed = False
        db_table = 'admin'

class AuthGroup(models.Model):
    name = models.CharField(unique=True, max_length=150)

    class Meta:
        managed = False
        db_table = 'auth_group'


class AuthGroupPermissions(models.Model):
    id = models.BigAutoField(primary_key=True)
    group = models.ForeignKey(AuthGroup, models.DO_NOTHING)
    permission = models.ForeignKey('AuthPermission', models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'auth_group_permissions'
        unique_together = (('group', 'permission'),)


class AuthPermission(models.Model):
    name = models.CharField(max_length=255)
    content_type = models.ForeignKey('DjangoContentType', models.DO_NOTHING)
    codename = models.CharField(max_length=100)

    class Meta:
        managed = False
        db_table = 'auth_permission'
        unique_together = (('content_type', 'codename'),)


class AuthUser(models.Model):
    password = models.CharField(max_length=128)
    last_login = models.DateTimeField(blank=True, null=True)
    is_superuser = models.BooleanField()
    username = models.CharField(unique=True, max_length=150)
    first_name = models.CharField(max_length=150)
    last_name = models.CharField(max_length=150)
    email = models.CharField(max_length=254)
    is_staff = models.BooleanField()
    is_active = models.BooleanField()
    date_joined = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'auth_user'


class AuthUserGroups(models.Model):
    id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(AuthUser, models.DO_NOTHING)
    group = models.ForeignKey(AuthGroup, models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'auth_user_groups'
        unique_together = (('user', 'group'),)


class AuthUserUserPermissions(models.Model):
    id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(AuthUser, models.DO_NOTHING)
    permission = models.ForeignKey(AuthPermission, models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'auth_user_user_permissions'
        unique_together = (('user', 'permission'),)


class AuthtokenToken(models.Model):
    key = models.CharField(primary_key=True, max_length=40)
    created = models.DateTimeField()
    user = models.OneToOneField(AuthUser, models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'authtoken_token'


class Blocks(models.Model):
    block_id = models.CharField(primary_key=True, max_length=5)
    society = models.ForeignKey('Societies', models.DO_NOTHING, blank=True, null=True)
    block_name = models.CharField(max_length=50)

    class Meta:
        managed = False
        db_table = 'blocks'

class TemporaryOTP(models.Model):
    id = models.BigAutoField(primary_key=True)
    email = models.CharField(unique=True, max_length=254)
    otp_code = models.CharField(max_length=4)
    created_at = models.DateTimeField(auto_now=True)

    class Meta:
        managed = False
        db_table = 'core_api_temporaryotp'

    @classmethod
    def generate_otp(cls, email):
        code = str(random.randint(1000, 9999))
        cls.objects.update_or_create(email=email, defaults={'otp_code': code})
        return code


class DjangoAdminLog(models.Model):
    action_time = models.DateTimeField()
    object_id = models.TextField(blank=True, null=True)
    object_repr = models.CharField(max_length=200)
    action_flag = models.SmallIntegerField()
    change_message = models.TextField()
    content_type = models.ForeignKey('DjangoContentType', models.DO_NOTHING, blank=True, null=True)
    user = models.ForeignKey(AuthUser, models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'django_admin_log'


class DjangoContentType(models.Model):
    app_label = models.CharField(max_length=100)
    model = models.CharField(max_length=100)

    class Meta:
        managed = False
        db_table = 'django_content_type'
        unique_together = (('app_label', 'model'),)


class DjangoMigrations(models.Model):
    id = models.BigAutoField(primary_key=True)
    app = models.CharField(max_length=255)
    name = models.CharField(max_length=255)
    applied = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'django_migrations'


class DjangoSession(models.Model):
    session_key = models.CharField(primary_key=True, max_length=40)
    session_data = models.TextField()
    expire_date = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'django_session'


class Flats(models.Model):
    flat_id = models.CharField(primary_key=True, max_length=5)
    block = models.ForeignKey(Blocks, models.DO_NOTHING, blank=True, null=True)
    flat_number = models.CharField(max_length=20)
    floor_number = models.IntegerField()

    class Meta:
        managed = False
        db_table = 'flats'

class Messages(models.Model):
    message_id = models.UUIDField(primary_key=True)
    sender = models.ForeignKey('Users', models.DO_NOTHING)
    receiver = models.ForeignKey('Users', models.DO_NOTHING, related_name='messages_receiver_set')
    message_text = models.TextField()
    timestamp = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'messages'


class Nominee(models.Model):
    nominee_id = models.CharField(primary_key=True, max_length=5)
    resident = models.ForeignKey('Resident', models.CASCADE, blank=True, null=True, db_column='resident_id')
    nominee_name = models.CharField(max_length=100)
    relationship = models.CharField(max_length=50)
    phone = models.CharField(max_length=10)
    email = models.CharField(max_length=100, blank=True, null=True)
    address = models.TextField()

    class Meta:
        managed = False
        db_table = 'nominee'
        verbose_name = 'Nominee'
        verbose_name_plural = 'Nominees'

    def __str__(self):
        return f"{self.nominee_name} ({self.relationship})"

class Occupancy(models.Model):
    occupancy_id = models.CharField(primary_key=True, max_length=5)
    flat = models.ForeignKey(Flats, models.DO_NOTHING, blank=True, null=True)
    resident = models.ForeignKey('Resident', models.DO_NOTHING, blank=True, null=True)
    occupancy_type = models.CharField(max_length=50)
    is_primary = models.BooleanField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'occupancy'

class Resident(models.Model):
    resident_id = models.CharField(primary_key=True, max_length=6)
    user = models.ForeignKey('Users', models.DO_NOTHING, blank=True, null=True)
    flat = models.ForeignKey(Flats, models.DO_NOTHING, blank=True, null=True)
    move_in_date = models.DateField()

    class Meta:
        managed = False
        db_table = 'resident'


class Roles(models.Model):
    role_id = models.CharField(primary_key=True, max_length=5)
    role_name = models.CharField(unique=True, max_length=50)

    class Meta:
        managed = False
        db_table = 'roles'

class Societies(models.Model):
    society_id = models.CharField(primary_key=True, max_length=5)
    society_name = models.CharField(max_length=100)
    society_address = models.TextField()
    society_city = models.CharField(max_length=50)
    society_pincode = models.CharField(max_length=10)
    society_email = models.CharField(unique=True, max_length=100, blank=True, null=True)
    society_phone = models.CharField(max_length=15)
    standard_rate = models.DecimalField(max_digits=10, decimal_places=2)
    late_fee_percent = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    billing_cycle = models.CharField(max_length=20, blank=True, null=True)
    society_status = models.CharField(max_length=20, blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'societies'
    
class SocietyFeatures(models.Model):
    config_id = models.CharField(primary_key=True, max_length=5)
    society = models.ForeignKey(Societies, models.DO_NOTHING, blank=True, null=True)
    has_block_secretary = models.BooleanField(blank=True, null=True)
    has_nominee = models.BooleanField(blank=True, null=True)
    has_security = models.BooleanField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'society_features'


class Tenant(models.Model):
    tenant_id = models.CharField(primary_key=True, max_length=6)
    user = models.ForeignKey('Users', models.DO_NOTHING, blank=True, null=True)
    flat = models.ForeignKey(Flats, models.DO_NOTHING, blank=True, null=True)
    owner = models.ForeignKey('Users', models.DO_NOTHING, related_name='tenant_owner_set', blank=True, null=True)
    custom_maintenance = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    status = models.CharField(max_length=20, blank=True, null=True)
    move_in_date = models.DateField()
    move_out_date = models.DateField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'tenant'

class CustomUserManager(BaseUserManager):
    def create_user(self, user_phone, user_name, password=None, **extra_fields):
        if not user_phone:
            raise ValueError("Phone number is required")
        user = self.model(user_phone=user_phone, user_name=user_name, **extra_fields)
        if password:
            user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, user_phone, user_name, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)
        return self.create_user(user_phone, user_name, password, **extra_fields)


class Users(AbstractBaseUser, PermissionsMixin):
    user_id = models.CharField(primary_key=True, max_length=5)
    society = models.ForeignKey('Societies', models.DO_NOTHING, blank=True, null=True)
    user_name = models.CharField(max_length=100)
    user_phone = models.CharField(unique=True, max_length=10)
    user_email = models.CharField(unique=True, max_length=100, blank=True, null=True)
    role = models.ForeignKey('Roles', models.DO_NOTHING, blank=True, null=True)
    password = models.CharField(max_length=255)
    is_active = models.BooleanField(default=False)
    is_staff = models.BooleanField(default=False)

    objects = CustomUserManager()

    USERNAME_FIELD = 'user_phone'
    REQUIRED_FIELDS = ['user_name']

    @property
    def id(self):
        return self.user_id

    class Meta:
        managed = False
        db_table = 'users'

    def __str__(self):
        return f"{self.user_name} ({self.user_phone})"
