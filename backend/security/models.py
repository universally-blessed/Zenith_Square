from django.db import models
from django.utils import timezone

class SecurityAlerts(models.Model):
    alert_id = models.CharField(primary_key=True, max_length=6)
    alert_type = models.CharField(max_length=50)  # e.g., 'Fire', 'Medical', 'Theft', 'Lift Stuck'
    description = models.TextField()
    triggered_by = models.ForeignKey('core_api.Users', models.DO_NOTHING, db_column='triggered_by', blank=True, null=True)
    status = models.CharField(max_length=20, default='active')
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        managed = False
        db_table = 'security_alerts'
        verbose_name = 'Security Alert'
        verbose_name_plural = 'Security Alerts'

    def __str__(self):
        return f"{self.alert_type} ({self.status})"


class Visitor(models.Model):
    visitor_id = models.CharField(primary_key=True, max_length=5)
    visitor_name = models.CharField(max_length=100)
    visitor_phone = models.CharField(max_length=10)

    class Meta:
        managed = False
        db_table = 'visitor'
        verbose_name = 'Visitor'
        verbose_name_plural = 'Visitors'

    def __str__(self):
        return f"{self.visitor_name} ({self.visitor_phone})"


class VisitorLogs(models.Model):
    log_id = models.AutoField(primary_key=True)
    visitor = models.ForeignKey(Visitor, models.DO_NOTHING, db_column='visitor_id', blank=True, null=True)
    flat = models.ForeignKey('core_api.Flats', models.DO_NOTHING, db_column='flat_id', blank=True, null=True)
    entry_time = models.DateTimeField(default=timezone.now)
    exit_time = models.DateTimeField(blank=True, null=True)
    purpose = models.CharField(max_length=200)
    recorded_by = models.ForeignKey('core_api.Users', models.DO_NOTHING, db_column='recorded_by', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'visitor_logs'
        verbose_name = 'Visitor Log'
        verbose_name_plural = 'Visitor Logs'