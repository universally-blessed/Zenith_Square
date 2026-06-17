from django.utils import timezone #type: ignore
from .models import Polls, PollsOption, PollsResponse, Meeting, Notice

def get_active_polls_with_results(user_id):
    polls = Polls.objects.filter(end_date__gte=timezone.now().date())
    results = []
    
    for poll in polls:
        total_votes = PollsResponse.objects.filter(poll=poll).count()
        options = PollsOption.objects.filter(poll=poll)
        
        opt_data = []
        for opt in options:
            opt_votes = PollsResponse.objects.filter(option=opt).count()
            opt_data.append({
                'option_id': opt.option_id,
                'option_text': opt.option_text,
                'percentage': round((opt_votes / total_votes * 100), 1) if total_votes > 0 else 0.0
            })
            
        results.append({
            'poll_id': poll.poll_id,
            'title': poll.poll_title,
            'has_voted': PollsResponse.objects.filter(poll=poll, user_id=user_id).exists(),
            'options': opt_data
        })
    return results

def cast_vote_service(poll_id, option_id, user_id):
    if PollsResponse.objects.filter(poll_id=poll_id, user_id=user_id).exists():
        return False, "Already voted."
    
    PollsResponse.objects.create(
        response_id=f"R{PollsResponse.objects.count() + 1:05d}",
        poll_id_id=poll_id, 
        option_id_id=option_id, 
        user_id_id=user_id, 
        voted_at=timezone.now()
    )
    return True, None

def get_latest_notices():
    """Retrieves all society notices ordered by recency."""
    notices = Notice.objects.all().order_by('-created_at')
    return [{
        'notice_id': n.notice_id, 
        'title': n.title, 
        'description': n.description,
        'created_at': n.created_at.strftime('%Y-%m-%d') if n.created_at else str(timezone.now().date())
    } for n in notices]

def get_upcoming_meetings():
    """Retrieves all society meetings ordered by date."""
    meetings = Meeting.objects.all().order_by('-meeting_date')
    return [{
        'meeting_id': m.meeting_id, 
        'title': m.title, 
        'agenda': m.agenda,
        'meeting_date': str(m.meeting_date), 
        'start_time': str(m.start_time), 
        'location': m.location, 
        'minutes_doc': m.minutes_doc or ''
    } for m in meetings]