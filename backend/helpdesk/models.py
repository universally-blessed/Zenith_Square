from django.db import models
from django.utils import timezone

class Complaint(models.Model):
    complaint_id = models.CharField(primary_key=True, max_length=6)
    resident = models.ForeignKey('core_api.Resident', models.DO_NOTHING, db_column='resident_id', blank=True, null=True)
    block = models.ForeignKey('core_api.Blocks', models.DO_NOTHING, db_column='block_id', blank=True, null=True)
    title = models.CharField(max_length=100)
    description = models.TextField()
    status = models.CharField(max_length=20, default='pending')
    created_at = models.DateTimeField(default=timezone.now)
    resolved_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'complaint'
        verbose_name = 'Complaint'
        verbose_name_plural = 'Complaints'

    def __str__(self):
        return f"{self.title} - {self.status} ({self.complaint_id})"


class Feedback(models.Model):
    feedback_id = models.CharField(primary_key=True, max_length=10)
    resident = models.ForeignKey('core_api.Resident', models.CASCADE, db_column='resident_id', blank=True, null=True)
    feedback_text = models.TextField()
    rating = models.IntegerField(blank=True, null=True)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        managed = False
        db_table = 'feedback'
        verbose_name = 'Feedback'
        verbose_name_plural = 'Feedback'