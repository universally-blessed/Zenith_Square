from django.db import models
from django.utils import timezone


class Meeting(models.Model):
    meeting_id = models.CharField(primary_key=True, max_length=6)
    title = models.CharField(max_length=150)
    agenda = models.TextField()
    meeting_date = models.DateField()
    start_time = models.TimeField()
    location = models.CharField(max_length=100)
    organized_by = models.ForeignKey('core_api.Users', models.DO_NOTHING, db_column='organized_by', blank=True, null=True)
    minutes_doc = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'meeting'
        verbose_name = 'Meeting'
        verbose_name_plural = 'Meetings'

    def __str__(self):
        return f"{self.title} ({self.meeting_date})"


class SocietyCommittee(models.Model):
    committee_id = models.CharField(primary_key=True, max_length=6)
    user = models.ForeignKey('core_api.Users', models.CASCADE, db_column='user_id', blank=True, null=True)
    society = models.ForeignKey('core_api.Societies', models.CASCADE, db_column='society_id', blank=True, null=True)
    role = models.ForeignKey('core_api.Roles', models.DO_NOTHING, db_column='role_id', blank=True, null=True)
    election_date = models.DateField()
    term_end = models.DateField(blank=True, null=True)
    status = models.CharField(max_length=20, default='Active')

    class Meta:
        managed = False
        db_table = 'society_committee'
        verbose_name = 'Society Committee Member'
        verbose_name_plural = 'Society Committee Members'

    def __str__(self):
        return f"{self.user.user_name if self.user else ''} - {self.role.role_name if self.role else ''}"


class CommitteeChange(models.Model):
    request_id = models.CharField(primary_key=True, max_length=6)
    requested_by = models.ForeignKey('core_api.Users', models.DO_NOTHING, related_name='change_requests_made', db_column='requested_by', blank=True, null=True)
    target_user = models.ForeignKey('core_api.Users', models.DO_NOTHING, related_name='change_requests_targeted', db_column='target_user', blank=True, null=True)
    new_role = models.ForeignKey('core_api.Roles', models.DO_NOTHING, db_column='new_role_id', blank=True, null=True)
    admin = models.ForeignKey('core_api.Users', models.DO_NOTHING, related_name='change_requests_handled', db_column='admin_id', blank=True, null=True)
    status = models.CharField(max_length=50, default='Pending')

    class Meta:
        managed = False
        db_table = 'committee_change'
        verbose_name = 'Committee Change Request'
        verbose_name_plural = 'Committee Change Requests'

class Polls(models.Model):
    poll_id = models.CharField(primary_key=True, max_length=6)
    poll_title = models.CharField(max_length=150)
    poll_description = models.TextField()
    created_by = models.ForeignKey('core_api.Users', models.DO_NOTHING, db_column='created_by', blank=True, null=True)
    end_date = models.DateField()
    status = models.CharField(max_length=20, default='active')

    class Meta:
        managed = False
        db_table = 'polls'
        verbose_name = 'Poll'
        verbose_name_plural = 'Polls'

    def __str__(self):
        return self.poll_title


class PollsOption(models.Model):
    option_id = models.CharField(primary_key=True, max_length=5)
    poll = models.ForeignKey(Polls, models.CASCADE, db_column='poll_id', related_name='options', blank=True, null=True)
    option_text = models.CharField(max_length=100)

    class Meta:
        managed = False
        db_table = 'polls_option'
        verbose_name = 'Poll Option'
        verbose_name_plural = 'Poll Options'

    def __str__(self):
        return f"{self.poll.poll_title} - {self.option_text}"


class PollsResponse(models.Model):
    response_id = models.CharField(primary_key=True, max_length=6)
    poll = models.ForeignKey(Polls, models.CASCADE, db_column='poll_id', blank=True, null=True)
    option = models.ForeignKey(PollsOption, models.CASCADE, db_column='option_id', blank=True, null=True)
    user = models.ForeignKey('core_api.Users', models.CASCADE, db_column='user_id', blank=True, null=True)
    voted_at = models.DateTimeField(default=timezone.now)

    class Meta:
        managed = False
        db_table = 'polls_response'
        verbose_name = 'Poll Response'
        verbose_name_plural = 'Poll Responses'

class LostFoundItem(models.Model):
    item_id = models.CharField(primary_key=True, max_length=5)
    item_name = models.CharField(max_length=100)
    item_description = models.TextField()
    item_status = models.CharField(max_length=20)  # e.g., 'Lost', 'Found', 'Claimed', 'Resolved'
    reported_by = models.ForeignKey('core_api.Users', models.DO_NOTHING, related_name='reported_items', db_column='reported_by', blank=True, null=True)
    handled_by = models.ForeignKey('core_api.Users', models.DO_NOTHING, related_name='handled_items', db_column='handled_by', blank=True, null=True)
    item_location = models.CharField(max_length=100)
    reported_date = models.DateField(default=timezone.now)

    class Meta:
        managed = False
        db_table = 'lost_found_item'
        verbose_name = 'Lost & Found Item'
        verbose_name_plural = 'Lost & Found Items'

    def __str__(self):
        return f"{self.item_name} ({self.item_status})"

