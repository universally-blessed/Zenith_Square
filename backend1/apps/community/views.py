from rest_framework.decorators import api_view, permission_classes, authentication_classes#type:ignore
from rest_framework.authentication import TokenAuthentication#type:ignore
from rest_framework.permissions import IsAuthenticated#type:ignore
from rest_framework.response import Response#type:ignore
from .services import get_active_polls_with_results, cast_vote_service, get_latest_notices, get_upcoming_meetings

@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_active_polls(request):
    data = get_active_polls_with_results(request.user.username)
    return Response(data)

@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def cast_poll_vote(request):
    success, error = cast_vote_service(
        request.data.get('poll_id'), 
        request.data.get('option_id'), 
        request.user.username
    )
    if not success:
        return Response({'error': error}, status=400)
    return Response({'success': True}, status=201)

@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_society_notices(request):
    return Response(get_latest_notices())

@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_society_meetings(request):
    return Response(get_upcoming_meetings())