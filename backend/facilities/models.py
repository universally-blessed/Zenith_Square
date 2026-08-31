from django.db import models

class Amenity(models.Model):
    amenity_id = models.CharField(primary_key=True, max_length=6)
    society = models.ForeignKey('core_api.Societies', models.DO_NOTHING, db_column='society_id', blank=True, null=True)
    amenity_name = models.CharField(max_length=100)
    amenity_location = models.CharField(max_length=100)
    amenity_capacity = models.IntegerField()
    amenity_status = models.CharField(max_length=20, default='available')

    class Meta:
        managed = False
        db_table = 'amenity'
        verbose_name = 'Amenity'
        verbose_name_plural = 'Amenities'

    def __str__(self):
        return f"{self.amenity_name} ({self.amenity_status})"


class AmenityBooking(models.Model):
    booking_id = models.CharField(primary_key=True, max_length=6)
    amenity = models.ForeignKey(Amenity, models.DO_NOTHING, db_column='amenity_id', blank=True, null=True)
    resident = models.ForeignKey('core_api.Resident', models.DO_NOTHING, db_column='resident_id', blank=True, null=True)
    booking_date = models.DateField()
    start_time = models.TimeField()
    end_time = models.TimeField()
    status = models.CharField(max_length=20, default='pending')
    payment_deadline = models.DateTimeField(blank=True, null=True)
    payment_id = models.CharField(max_length=5, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'amenity_booking'
        verbose_name = 'Amenity Booking'
        verbose_name_plural = 'Amenity Bookings'


class Asset(models.Model):
    asset_id = models.CharField(primary_key=True, max_length=5)
    society = models.ForeignKey('core_api.Societies', models.DO_NOTHING, db_column='society_id', blank=True, null=True)
    asset_name = models.CharField(max_length=100)
    asset_type = models.CharField(max_length=50)
    asset_location = models.CharField(max_length=100)
    purchase_date = models.DateField()

    class Meta:
        managed = False
        db_table = 'asset'
        verbose_name = 'Asset'
        verbose_name_plural = 'Assets'

    def __str__(self):
        return f"{self.asset_name} ({self.asset_type})"


class AssetMaintenance(models.Model):
    maintenance_id = models.CharField(primary_key=True, max_length=6)
    asset = models.ForeignKey(Asset, models.DO_NOTHING, db_column='asset_id', blank=True, null=True)
    description = models.TextField()
    maintenance_date = models.DateField()
    maintenance_cost = models.DecimalField(max_digits=10, decimal_places=2)
    recorded_by = models.CharField(max_length=6, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_maintenance'
        verbose_name = 'Asset Maintenance'
        verbose_name_plural = 'Asset Maintenances'

class Vehicle(models.Model):
    vehicle_id = models.CharField(primary_key=True, max_length=6)
    resident = models.ForeignKey('core_api.Resident', models.CASCADE, db_column='resident_id', blank=True, null=True)
    vehicle_number = models.CharField(max_length=20)
    vehicle_type = models.CharField(max_length=20)  # e.g., '2-Wheeler', '4-Wheeler'
    vehicle_allotment_number = models.CharField(max_length=50)  # Parking Slot / Sticker No

    class Meta:
        managed = False
        db_table = 'vehicle'
        verbose_name = 'Vehicle'
        verbose_name_plural = 'Vehicles'

    def __str__(self):
        return f"{self.vehicle_number} ({self.vehicle_type})"