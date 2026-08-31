from django.db import models
from django.utils import timezone

class Notice(models.Model):
    notice_id = models.CharField(primary_key=True, max_length=5)
    society = models.ForeignKey('core_api.Societies', models.DO_NOTHING, db_column='society_id', blank=True, null=True)
    block = models.ForeignKey('core_api.Blocks', models.DO_NOTHING, db_column='block_id', blank=True, null=True)
    title = models.CharField(max_length=150)
    description = models.TextField()
    created_by = models.ForeignKey('core_api.Users', models.DO_NOTHING, db_column='created_by', blank=True, null=True)
    created_at = models.DateTimeField(default=timezone.now)
    priority = models.CharField(max_length=10, default='normal')
    is_active = models.BooleanField(default=True)

    class Meta:
        managed = False
        db_table = 'notice'
        verbose_name = 'Notice'
        verbose_name_plural = 'Notices'

    def __str__(self):
        return f"{self.title} ({self.priority})"