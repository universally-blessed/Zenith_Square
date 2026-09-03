from django.db import models


class Admin(models.Model):
    a_id = models.AutoField(primary_key=True)
    a_username = models.CharField(max_length=255)
    a_email = models.CharField(unique=True, max_length=255)
    a_password = models.CharField(max_length=255)

    class Meta:
        managed = True
        db_table = 'admin'


class Amenity(models.Model):
    amenity_id = models.CharField(primary_key=True, max_length=6)
    society = models.ForeignKey('Societies', models.DB_CASCADE, blank=True, null=True)
    amenity_name = models.CharField(max_length=100)
    amenity_location = models.CharField(max_length=100)
    amenity_capacity = models.IntegerField()
    amenity_status = models.CharField(max_length=20, blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'amenity'


class AmenityBooking(models.Model):
    booking_id = models.CharField(primary_key=True, max_length=6)
    amenity = models.ForeignKey(Amenity, models.DB_CASCADE, blank=True, null=True)
    resident = models.ForeignKey('Resident', models.DB_CASCADE, blank=True, null=True)
    booking_date = models.DateField()
    start_time = models.TimeField()
    end_time = models.TimeField()
    status = models.CharField(max_length=20, blank=True, null=True)
    payment_deadline = models.DateTimeField(blank=True, null=True)
    payment_id = models.CharField(max_length=5, blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'amenity_booking'


class Asset(models.Model):
    asset_id = models.CharField(primary_key=True, max_length=5)
    society = models.ForeignKey('Societies', models.DB_CASCADE, blank=True, null=True)
    asset_name = models.CharField(max_length=100)
    asset_type = models.CharField(max_length=50)
    asset_location = models.CharField(max_length=100)
    purchase_date = models.DateField()

    class Meta:
        managed = True
        db_table = 'asset'


class AssetMaintenance(models.Model):
    maintenance_id = models.CharField(primary_key=True, max_length=6)
    asset = models.ForeignKey(Asset, models.DB_CASCADE, blank=True, null=True)
    description = models.TextField()
    maintenance_date = models.DateField()
    maintenance_cost = models.DecimalField(max_digits=10, decimal_places=2)
    recorded_by = models.ForeignKey('Resident', models.DO_NOTHING, db_column='recorded_by', blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'asset_maintenance'


class Blocks(models.Model):
    block_id = models.CharField(primary_key=True, max_length=5)
    society = models.ForeignKey('Societies', models.DB_CASCADE, blank=True, null=True)
    block_name = models.CharField(max_length=50)

    class Meta:
        managed = True
        db_table = 'blocks'


class CommitteeChange(models.Model):
    request_id = models.CharField(primary_key=True, max_length=10)
    requested_by = models.ForeignKey('Users', models.DO_NOTHING, db_column='requested_by', blank=True, null=True)
    target_user = models.ForeignKey('Users', models.DO_NOTHING, db_column='target_user', related_name='committeechange_target_user_set', blank=True, null=True)
    new_role = models.ForeignKey('Roles', models.DO_NOTHING, blank=True, null=True)
    admin = models.ForeignKey('Users', models.DO_NOTHING, related_name='committeechange_admin_set', blank=True, null=True)
    status = models.CharField(max_length=50, blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'committee_change'


class Complaint(models.Model):
    complaint_id = models.CharField(primary_key=True, max_length=10)
    resident = models.ForeignKey('Resident', models.DB_CASCADE, blank=True, null=True)
    block = models.ForeignKey(Blocks, models.DB_SET_NULL, blank=True, null=True)
    title = models.CharField(max_length=150)
    description = models.TextField()
    status = models.CharField(max_length=20, blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    resolved_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'complaint'


class CoreApiTemporaryotp(models.Model):
    id = models.BigAutoField(primary_key=True)
    email = models.CharField(unique=True, max_length=254)
    otp_code = models.CharField(max_length=4)
    created_at = models.DateTimeField()

    class Meta:
        managed = True
        db_table = 'core_api_temporaryotp'


class Feedback(models.Model):
    feedback_id = models.CharField(primary_key=True, max_length=10)
    resident = models.ForeignKey('Resident', models.DB_CASCADE, blank=True, null=True)
    feedback_text = models.TextField()
    rating = models.IntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'feedback'


class Flats(models.Model):
    flat_id = models.CharField(primary_key=True, max_length=5)
    block = models.ForeignKey(Blocks, models.DB_CASCADE, blank=True, null=True)
    flat_number = models.CharField(max_length=20)
    floor_number = models.IntegerField()

    class Meta:
        managed = True
        db_table = 'flats'


class LostFoundItem(models.Model):
    item_id = models.CharField(primary_key=True, max_length=5)
    item_name = models.CharField(max_length=100)
    item_description = models.TextField()
    item_status = models.CharField(max_length=20)
    reported_by = models.ForeignKey('Users', models.DO_NOTHING, db_column='reported_by', blank=True, null=True)
    handled_by = models.ForeignKey('Users', models.DO_NOTHING, db_column='handled_by', related_name='lostfounditem_handled_by_set', blank=True, null=True)
    item_location = models.CharField(max_length=100)
    reported_date = models.DateField()

    class Meta:
        managed = True
        db_table = 'lost_found_item'


class MaintenanceBill(models.Model):
    bill_id = models.CharField(primary_key=True, max_length=6)
    flat = models.ForeignKey(Flats, models.DB_CASCADE, blank=True, null=True)
    payer = models.ForeignKey('Users', models.DO_NOTHING, blank=True, null=True)
    bill_month = models.CharField(max_length=20)
    payable_amount = models.DecimalField(max_digits=10, decimal_places=2)
    due_date = models.DateField()
    status = models.CharField(max_length=20, blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'maintenance_bill'


class Meeting(models.Model):
    meeting_id = models.CharField(primary_key=True, max_length=6)
    title = models.CharField(max_length=150)
    agenda = models.TextField()
    meeting_date = models.DateField()
    start_time = models.TimeField()
    location = models.CharField(max_length=100)
    organized_by = models.ForeignKey('Users', models.DO_NOTHING, db_column='organized_by', blank=True, null=True)
    minutes_doc = models.TextField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'meeting'


class Messages(models.Model):
    message_id = models.UUIDField(primary_key=True)
    sender = models.ForeignKey('Users', models.DB_CASCADE)
    receiver = models.ForeignKey('Users', models.DB_CASCADE, related_name='messages_receiver_set')
    message_text = models.TextField()
    timestamp = models.DateTimeField()

    class Meta:
        managed = True
        db_table = 'messages'


class Nominee(models.Model):
    nominee_id = models.CharField(primary_key=True, max_length=5)
    resident = models.ForeignKey('Resident', models.DB_CASCADE, blank=True, null=True)
    nominee_name = models.CharField(max_length=100)
    relationship = models.CharField(max_length=50)
    phone = models.CharField(max_length=10)
    email = models.CharField(max_length=100, blank=True, null=True)
    address = models.TextField()

    class Meta:
        managed = True
        db_table = 'nominee'


class Notice(models.Model):
    notice_id = models.CharField(primary_key=True, max_length=5)
    society = models.ForeignKey('Societies', models.DB_CASCADE, blank=True, null=True)
    block = models.ForeignKey(Blocks, models.DB_SET_NULL, blank=True, null=True)
    title = models.CharField(max_length=150)
    description = models.TextField()
    created_by = models.ForeignKey('Users', models.DO_NOTHING, db_column='created_by', blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    priority = models.CharField(max_length=10, blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'notice'


class Occupancy(models.Model):
    occupancy_id = models.CharField(primary_key=True, max_length=5)
    flat = models.ForeignKey(Flats, models.DB_CASCADE, blank=True, null=True)
    resident = models.ForeignKey('Resident', models.DB_CASCADE, blank=True, null=True)
    occupancy_type = models.CharField(max_length=50)
    is_primary = models.BooleanField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'occupancy'


class Payment(models.Model):
    payment_id = models.CharField(primary_key=True, max_length=5)
    resident = models.ForeignKey('Resident', models.DB_CASCADE, blank=True, null=True)
    bill_id = models.CharField(max_length=6, blank=True, null=True)
    payment_type = models.CharField(max_length=20)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    payment_method = models.CharField(max_length=20)
    status = models.CharField(max_length=20, blank=True, null=True)
    payment_date = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'payment'


class PaymentReceipt(models.Model):
    receipt_id = models.CharField(primary_key=True, max_length=6)
    payment = models.ForeignKey(Payment, models.DB_CASCADE, blank=True, null=True)
    receipt_number = models.CharField(unique=True, max_length=50)
    generated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'payment_receipt'


class Polls(models.Model):
    poll_id = models.CharField(primary_key=True, max_length=6)
    poll_title = models.CharField(max_length=150)
    poll_description = models.TextField()
    created_by = models.ForeignKey('Users', models.DO_NOTHING, db_column='created_by', blank=True, null=True)
    end_date = models.DateField()
    status = models.CharField(max_length=20, blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'polls'


class PollsOption(models.Model):
    option_id = models.CharField(primary_key=True, max_length=5)
    poll = models.ForeignKey(Polls, models.DB_CASCADE, blank=True, null=True)
    option_text = models.CharField(max_length=100)

    class Meta:
        managed = True
        db_table = 'polls_option'


class PollsResponse(models.Model):
    response_id = models.CharField(primary_key=True, max_length=6)
    poll = models.ForeignKey(Polls, models.DB_CASCADE, blank=True, null=True)
    option = models.ForeignKey(PollsOption, models.DB_CASCADE, blank=True, null=True)
    user = models.ForeignKey('Users', models.DB_CASCADE, blank=True, null=True)
    voted_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'polls_response'


class Resident(models.Model):
    resident_id = models.CharField(primary_key=True, max_length=6)
    user = models.ForeignKey('Users', models.DB_CASCADE, blank=True, null=True)
    flat = models.ForeignKey(Flats, models.DB_CASCADE, blank=True, null=True)
    move_in_date = models.DateField()

    class Meta:
        managed = True
        db_table = 'resident'


class Roles(models.Model):
    role_id = models.CharField(primary_key=True, max_length=5)
    role_name = models.CharField(unique=True, max_length=50)

    class Meta:
        managed = True
        db_table = 'roles'


class SecurityAlerts(models.Model):
    alert_id = models.CharField(primary_key=True, max_length=6)
    alert_type = models.CharField(max_length=50)
    description = models.TextField()
    triggered_by = models.ForeignKey('Users', models.DO_NOTHING, db_column='triggered_by', blank=True, null=True)
    status = models.CharField(max_length=20, blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'security_alerts'


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
        managed = True
        db_table = 'societies'


class SocietyCommittee(models.Model):
    committee_id = models.CharField(primary_key=True, max_length=6)
    user = models.ForeignKey('Users', models.DB_CASCADE, blank=True, null=True)
    society = models.ForeignKey(Societies, models.DB_CASCADE, blank=True, null=True)
    role = models.ForeignKey(Roles, models.DO_NOTHING, blank=True, null=True)
    election_date = models.DateField()
    term_end = models.DateField(blank=True, null=True)
    status = models.CharField(max_length=20, blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'society_committee'


class SocietyExpenses(models.Model):
    expense_id = models.CharField(primary_key=True, max_length=6)
    society = models.ForeignKey(Societies, models.DB_CASCADE, blank=True, null=True)
    expense_type = models.CharField(max_length=50)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    payment_date = models.DateField()
    description = models.TextField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'society_expenses'


class SocietyFeatures(models.Model):
    config_id = models.CharField(primary_key=True, max_length=5)
    society = models.ForeignKey(Societies, models.DB_CASCADE, blank=True, null=True)
    has_block_secretary = models.BooleanField(blank=True, null=True)
    has_nominee = models.BooleanField(blank=True, null=True)
    has_security = models.BooleanField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'society_features'


class Tenant(models.Model):
    tenant_id = models.CharField(primary_key=True, max_length=6)
    user = models.ForeignKey('Users', models.DB_CASCADE, blank=True, null=True)
    flat = models.ForeignKey(Flats, models.DB_CASCADE, blank=True, null=True)
    owner = models.ForeignKey('Users', models.DO_NOTHING, related_name='tenant_owner_set', blank=True, null=True)
    custom_maintenance = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    status = models.CharField(max_length=20, blank=True, null=True)
    move_in_date = models.DateField()
    move_out_date = models.DateField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'tenant'


class Users(models.Model):
    user_id = models.CharField(primary_key=True, max_length=5)
    society = models.ForeignKey(Societies, models.DB_CASCADE, blank=True, null=True)
    user_name = models.CharField(max_length=100)
    user_phone = models.CharField(unique=True, max_length=10)
    user_email = models.CharField(unique=True, max_length=100, blank=True, null=True)
    role = models.ForeignKey(Roles, models.DO_NOTHING, blank=True, null=True)
    password = models.CharField(max_length=255)
    is_active = models.BooleanField(blank=True, null=True)
    last_login = models.DateTimeField(blank=True, null=True)
    is_superuser = models.BooleanField(blank=True, null=True)
    is_staff = models.BooleanField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'users'


class Vehicle(models.Model):
    vehicle_id = models.CharField(primary_key=True, max_length=6)
    resident = models.ForeignKey(Resident, models.DB_CASCADE, blank=True, null=True)
    vehicle_number = models.CharField(unique=True, max_length=20)
    vehicle_type = models.CharField(max_length=20)
    vehicle_allotment_number = models.CharField(max_length=50)

    class Meta:
        managed = True
        db_table = 'vehicle'


class Visitor(models.Model):
    visitor_id = models.CharField(primary_key=True, max_length=5)
    visitor_name = models.CharField(max_length=100)
    visitor_phone = models.CharField(max_length=10)

    class Meta:
        managed = True
        db_table = 'visitor'


class VisitorLogs(models.Model):
    log_id = models.AutoField(primary_key=True)
    visitor = models.ForeignKey(Visitor, models.DO_NOTHING, blank=True, null=True)
    flat = models.ForeignKey(Flats, models.DO_NOTHING, blank=True, null=True)
    entry_time = models.DateTimeField()
    exit_time = models.DateTimeField(blank=True, null=True)
    purpose = models.CharField(max_length=200)
    recorded_by = models.ForeignKey(Users, models.DO_NOTHING, db_column='recorded_by', blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'visitor_logs'
