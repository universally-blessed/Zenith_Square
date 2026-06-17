from .models import Societies, Blocks, Amenity

def get_blocks_for_society(society_id):
    """Encapsulates the lookup logic."""
    return Blocks.objects.filter(society_id=society_id).order_by('block_name')

def get_active_amenities(society_id):
    """Returns only amenities that are operational."""
    return Amenity.objects.filter(society_id=society_id, amenity_status='active')