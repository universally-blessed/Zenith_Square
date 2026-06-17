from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from .models import Societies, Blocks

@api_view(['GET'])
@permission_classes([AllowAny])
def list_societies_public(request):
    """Yields registered society identities for user signup lookups."""
    societies = Societies.objects.filter(society_status='active').order_by('society_name')
    data = [{'id': s.society_id, 'name': s.society_name} for s in societies]
    return Response(data, status=status.HTTP_200_OK)

@api_view(['GET'])
@permission_classes([AllowAny])
def list_blocks_by_society(request, society_id):
    """Pulls relational blocks linked to the chosen parent society."""
    blocks = Blocks.objects.filter(society_id=society_id).order_by('block_name')
    data = [{'id': b.block_id, 'name': b.block_name} for b in blocks]
    return Response(data, status=status.HTTP_200_OK)