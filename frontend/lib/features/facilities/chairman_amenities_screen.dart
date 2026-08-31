import 'package:flutter/material.dart';
import '../../data/datasource/facilities_api_service.dart';

class ChairmanAmenitiesScreen extends StatefulWidget {
  const ChairmanAmenitiesScreen({super.key});

  @override
  State<ChairmanAmenitiesScreen> createState() =>
      _ChairmanAmenitiesScreenState();
}

class _ChairmanAmenitiesScreenState extends State<ChairmanAmenitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amenities & Asset Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/chairman-home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Booking Approvals'),
            Tab(text: 'Amenities Catalog'),
            Tab(text: 'Assets & Maintenance'),
            Tab(text: 'My Reservations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _ChairmanBookingApprovalsTab(),
          const _ChairmanAmenitiesCatalogTab(),
          const _ChairmanAssetsTab(),
          _ChairmanMyBookingsTab(
            onNavigateToCatalog: () => _tabController.animateTo(1),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 1: BOOKING APPROVALS & STATUS OVERVIEW (SOCIETY-WIDE)
// -------------------------------------------------------------
class _ChairmanBookingApprovalsTab extends StatefulWidget {
  const _ChairmanBookingApprovalsTab();

  @override
  State<_ChairmanBookingApprovalsTab> createState() =>
      _ChairmanBookingApprovalsTabState();
}

class _ChairmanBookingApprovalsTabState
    extends State<_ChairmanBookingApprovalsTab> {
  late Future<List<dynamic>> _bookingsFuture;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    setState(() {
      _bookingsFuture = FacilitiesApiService.fetchSocietyBookings();
    });
  }

  Future<void> _handleConfirmPayment(String bookingId) async {
    final refController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Booking Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm that the resident has paid the booking deposit/charge:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: refController,
              decoration: const InputDecoration(
                labelText: 'Payment Ref / Receipt No. (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Confirm & Lock Slot',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await FacilitiesApiService.confirmBookingPayment(
        bookingId,
        paymentId: refController.text.trim().isNotEmpty
            ? refController.text.trim()
            : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Booking confirmed successfully!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _loadBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _handleCancelBooking(String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking and release the reserved time slot?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Cancel Slot',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await FacilitiesApiService.cancelBooking(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message'] ?? 'Booking cancelled and slot released.',
            ),
            backgroundColor: Colors.orange.shade800,
          ),
        );
        _loadBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              _buildFilterChip('all', 'All Bookings'),
              const SizedBox(width: 8),
              _buildFilterChip('pending_payment', 'Pending Payment (Hold)'),
              const SizedBox(width: 8),
              _buildFilterChip('confirmed', 'Confirmed'),
              const SizedBox(width: 8),
              _buildFilterChip('expired', 'Expired / Unpaid'),
              const SizedBox(width: 8),
              _buildFilterChip('cancelled', 'Cancelled'),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _bookingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        snapshot.error.toString().replaceAll('Exception: ', ''),
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadBookings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final all = snapshot.data ?? [];
              final filtered = all.where((b) {
                if (_selectedFilter == 'all') return true;
                final status = (b['status'] ?? '').toString().toLowerCase();
                final isExpired = b['is_payment_expired'] == true;
                if (_selectedFilter == 'expired') {
                  return status == 'expired' || isExpired;
                }
                if (_selectedFilter == 'pending_payment') {
                  return status == 'pending_payment' && !isExpired;
                }
                return status == _selectedFilter;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No bookings match the selected criteria.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _loadBookings(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final b = filtered[i];
                    final rawStatus = (b['status'] ?? 'pending')
                        .toString()
                        .toLowerCase();
                    final isExpired = b['is_payment_expired'] ?? false;
                    final residentName = b['resident_name'] ?? 'Resident';
                    final flatNumber = b['flat_number'] ?? '--';

                    Color badgeColor;
                    String displayStatus;

                    if (rawStatus == 'confirmed') {
                      badgeColor = Colors.green;
                      displayStatus = 'CONFIRMED';
                    } else if (rawStatus == 'pending_payment' && !isExpired) {
                      badgeColor = Colors.orange.shade800;
                      displayStatus = 'PENDING PAYMENT (HOLD)';
                    } else if (rawStatus == 'expired' || isExpired) {
                      badgeColor = Colors.red.shade700;
                      displayStatus = 'EXPIRED';
                    } else {
                      badgeColor = Colors.grey;
                      displayStatus = rawStatus.toUpperCase();
                    }

                    final canConfirm =
                        rawStatus == 'pending_payment' && !isExpired;
                    final canCancel = rawStatus == 'confirmed' || canConfirm;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  b['amenity_name'] ?? 'Amenity',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: badgeColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    displayStatus,
                                    style: TextStyle(
                                      color: badgeColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Reserved By: $residentName (Flat $flatNumber)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Date: ${b['booking_date']}  |  Time: ${b['start_time']} - ${b['end_time']}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                            if (b['payment_id'] != null &&
                                b['payment_id'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Payment Ref: ${b['payment_id']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            if (canConfirm || canCancel) ...[
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (canCancel)
                                    OutlinedButton(
                                      onPressed: () =>
                                          _handleCancelBooking(b['booking_id']),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(
                                          color: Colors.red,
                                        ),
                                      ),
                                      child: const Text('Cancel Slot'),
                                    ),
                                  if (canConfirm) ...[
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => _handleConfirmPayment(
                                        b['booking_id'],
                                      ),
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                        size: 16,
                                      ),
                                      label: const Text('Confirm Payment'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilter = value);
        }
      },
    );
  }
}

// -------------------------------------------------------------
// TAB 2: AMENITIES CATALOG & STATUS CHANGE & BOOKING MODAL
// -------------------------------------------------------------
class _ChairmanAmenitiesCatalogTab extends StatefulWidget {
  const _ChairmanAmenitiesCatalogTab();

  @override
  State<_ChairmanAmenitiesCatalogTab> createState() =>
      _ChairmanAmenitiesCatalogTabState();
}

class _ChairmanAmenitiesCatalogTabState
    extends State<_ChairmanAmenitiesCatalogTab> {
  late Future<List<dynamic>> _amenitiesFuture;

  @override
  void initState() {
    super.initState();
    _loadAmenities();
  }

  void _loadAmenities() {
    setState(() {
      _amenitiesFuture = FacilitiesApiService.fetchAmenities();
    });
  }

  void _showChangeStatusDialog(String amenityId, String currentStatus) {
    String newStatus = currentStatus.toLowerCase();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Update Operational Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Set the status for this amenity:'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value:
                    [
                      'available',
                      'maintenance',
                      'unavailable',
                    ].contains(newStatus)
                    ? newStatus
                    : 'available',
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(
                    value: 'available',
                    child: Text('Available'),
                  ),
                  DropdownMenuItem(
                    value: 'maintenance',
                    child: Text('Under Maintenance'),
                  ),
                  DropdownMenuItem(
                    value: 'unavailable',
                    child: Text('Unavailable'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => newStatus = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final res = await FacilitiesApiService.updateAmenityStatus(
                    amenityId,
                    newStatus,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res['message'] ?? 'Status updated!'),
                        backgroundColor: Colors.green.shade700,
                      ),
                    );
                    _loadAmenities();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                        ),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateAmenityModal() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final capacityController = TextEditingController();
    String statusValue = 'available';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Register New Amenity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Amenity Name',
                      hintText: 'e.g. Swimming Pool, Community Hall',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter amenity name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location / Floor',
                      hintText: 'e.g. Ground Floor, Clubhouse Building',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter location'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: capacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Maximum Capacity (Persons)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Enter capacity';
                      if (int.tryParse(v.trim()) == null) {
                        return 'Enter valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: statusValue,
                    decoration: const InputDecoration(
                      labelText: 'Operational Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'available',
                        child: Text('Available'),
                      ),
                      DropdownMenuItem(
                        value: 'maintenance',
                        child: Text('Under Maintenance'),
                      ),
                      DropdownMenuItem(
                        value: 'unavailable',
                        child: Text('Unavailable'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => statusValue = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => isSubmitting = true);
                            try {
                              final res =
                                  await FacilitiesApiService.createAmenity(
                                    name: nameController.text.trim(),
                                    location: locationController.text.trim(),
                                    capacity: int.parse(
                                      capacityController.text.trim(),
                                    ),
                                    status: statusValue,
                                  );
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      res['message'] ?? 'Amenity registered!',
                                    ),
                                    backgroundColor: Colors.green.shade700,
                                  ),
                                );
                                _loadAmenities();
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceAll('Exception: ', ''),
                                  ),
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.cyan.shade700,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Amenity',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateAmenityModal,
        backgroundColor: Colors.cyan.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Amenity', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _amenitiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    snapshot.error.toString().replaceAll('Exception: ', ''),
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadAmenities,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final amenities = snapshot.data ?? [];
          if (amenities.isEmpty) {
            return const Center(child: Text('No amenities registered yet.'));
          }

          return RefreshIndicator(
            onRefresh: () async => _loadAmenities(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12.0),
              itemCount: amenities.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final a = amenities[i];
                final status = (a['amenity_status'] ?? 'available').toString();
                final isAvailable = status == 'available';

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              a['amenity_name'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            InkWell(
                              onTap: () => _showChangeStatusDialog(
                                a['amenity_id'],
                                status,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isAvailable
                                        ? Colors.green.shade200
                                        : Colors.red.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: isAvailable
                                            ? Colors.green.shade800
                                            : Colors.red.shade800,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.edit,
                                      size: 11,
                                      color: isAvailable
                                          ? Colors.green.shade800
                                          : Colors.red.shade800,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Location: ${a['amenity_location']} • Capacity: ${a['amenity_capacity']} persons',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: isAvailable
                                ? () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.white,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                      builder: (ctx) =>
                                          _AmenityBookingModal(amenity: a),
                                    );
                                  }
                                : null,
                            icon: const Icon(
                              Icons.calendar_month_outlined,
                              size: 18,
                            ),
                            label: const Text('Check Slots & Book'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 3: ASSETS & MAINTENANCE LOGS (WITH SOFT DELETE)
// -------------------------------------------------------------
class _ChairmanAssetsTab extends StatefulWidget {
  const _ChairmanAssetsTab();

  @override
  State<_ChairmanAssetsTab> createState() => _ChairmanAssetsTabState();
}

class _ChairmanAssetsTabState extends State<_ChairmanAssetsTab> {
  late Future<List<dynamic>> _assetsFuture;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  void _loadAssets() {
    setState(() {
      _assetsFuture = FacilitiesApiService.fetchAssets();
    });
  }

  Future<void> _handleDeleteAsset(String assetId, String assetName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Asset'),
        content: Text('Are you sure you want to remove "$assetName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await FacilitiesApiService.deleteAsset(assetId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Asset removed successfully!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _loadAssets();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _openCreateAssetModal() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final typeController = TextEditingController();
    final locationController = TextEditingController();
    DateTime purchaseDate = DateTime.now();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Register Society Asset',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Asset Name',
                      hintText: 'e.g. Diesel Generator, CCTV Camera System',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter asset name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: typeController,
                    decoration: const InputDecoration(
                      labelText: 'Category / Type',
                      hintText: 'e.g. Electrical, Security, Plumbing',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter asset type'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Asset Location',
                      hintText: 'e.g. Basement Parking, Main Gate',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter location'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: Text(
                      'Purchase Date: ${purchaseDate.toIso8601String().substring(0, 10)}',
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: purchaseDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() => purchaseDate = picked);
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => isSubmitting = true);
                            try {
                              final res =
                                  await FacilitiesApiService.createAsset(
                                    name: nameController.text.trim(),
                                    type: typeController.text.trim(),
                                    location: locationController.text.trim(),
                                    purchaseDate: purchaseDate
                                        .toIso8601String()
                                        .substring(0, 10),
                                  );
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      res['message'] ?? 'Asset added!',
                                    ),
                                    backgroundColor: Colors.green.shade700,
                                  ),
                                );
                                _loadAssets();
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceAll('Exception: ', ''),
                                  ),
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.indigo,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Asset',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMaintenanceHistory(Map<String, dynamic> asset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AssetMaintenanceSheet(asset: asset),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateAssetModal,
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add_box_outlined, color: Colors.white),
        label: const Text('Add Asset', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _assetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    snapshot.error.toString().replaceAll('Exception: ', ''),
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadAssets,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final assets = snapshot.data ?? [];
          if (assets.isEmpty) {
            return const Center(
              child: Text('No assets registered in the society.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadAssets(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12.0),
              itemCount: assets.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final asset = assets[i];

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14.0),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8EAF6),
                      child: Icon(
                        Icons.build_circle_outlined,
                        color: Colors.indigo,
                      ),
                    ),
                    title: Text(
                      asset['asset_name'] ?? 'Asset',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Type: ${asset['asset_type']} • Location: ${asset['asset_location']}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Purchased: ${asset['purchase_date'] ?? '--'}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: () => _showMaintenanceHistory(asset),
                          child: const Text('Logs'),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Remove Asset',
                          onPressed: () => _handleDeleteAsset(
                            asset['asset_id'],
                            asset['asset_name'] ?? 'Asset',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AssetMaintenanceSheet extends StatefulWidget {
  final Map<String, dynamic> asset;

  const _AssetMaintenanceSheet({required this.asset});

  @override
  State<_AssetMaintenanceSheet> createState() => _AssetMaintenanceSheetState();
}

class _AssetMaintenanceSheetState extends State<_AssetMaintenanceSheet> {
  late Future<List<dynamic>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    setState(() {
      _logsFuture = FacilitiesApiService.fetchAssetMaintenance(
        widget.asset['asset_id'],
      );
    });
  }

  void _openAddLogModal() {
    final formKey = GlobalKey<FormState>();
    final descController = TextEditingController();
    final costController = TextEditingController();
    DateTime date = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Record Maintenance for ${widget.asset['asset_name']}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Service / Work Details',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter description'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: costController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Maintenance Cost (₹)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter cost';
                    if (double.tryParse(v.trim()) == null) {
                      return 'Enter valid amount';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                try {
                  await FacilitiesApiService.recordAssetMaintenance(
                    assetId: widget.asset['asset_id'],
                    description: descController.text.trim(),
                    maintenanceDate: date.toIso8601String().substring(0, 10),
                    cost: double.parse(costController.text.trim()),
                  );
                  _loadLogs();
                } catch (_) {}
              },
              child: const Text('Save Log'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.asset['asset_name']} Logs',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _openAddLogModal,
            icon: const Icon(Icons.add),
            label: const Text('Record Maintenance Log'),
          ),
          const Divider(height: 20),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final logs = snapshot.data ?? [];
                if (logs.isEmpty) {
                  return const Center(
                    child: Text('No maintenance logs recorded.'),
                  );
                }

                return ListView.separated(
                  itemCount: logs.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final log = logs[i];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: Text(log['description'] ?? ''),
                        subtitle: Text('Date: ${log['maintenance_date']}'),
                        trailing: Text(
                          '₹${log['maintenance_cost']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 4: CHAIRMAN'S PERSONAL UNIT BOOKINGS
// -------------------------------------------------------------
class _ChairmanMyBookingsTab extends StatefulWidget {
  final VoidCallback onNavigateToCatalog;

  const _ChairmanMyBookingsTab({required this.onNavigateToCatalog});

  @override
  State<_ChairmanMyBookingsTab> createState() => _ChairmanMyBookingsTabState();
}

class _ChairmanMyBookingsTabState extends State<_ChairmanMyBookingsTab> {
  late Future<List<dynamic>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    setState(() {
      _bookingsFuture = FacilitiesApiService.fetchMyBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _bookingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text(
                  'You have no personal amenity bookings.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: widget.onNavigateToCatalog,
                  icon: const Icon(Icons.add),
                  label: const Text('Book an Amenity'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _loadBookings(),
          child: ListView.separated(
            padding: const EdgeInsets.all(12.0),
            itemCount: bookings.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final b = bookings[i];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b['amenity_name'] ?? 'Amenity',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${b['booking_date']} (${b['start_time']} - ${b['end_time']})',
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                      Text(
                        'Status: ${(b['status'] ?? '').toString().toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------
// REUSABLE AMENITY BOOKING MODAL (FOR CATALOG DIRECT BOOKINGS)
// -------------------------------------------------------------
class _AmenityBookingModal extends StatefulWidget {
  final Map<String, dynamic> amenity;

  const _AmenityBookingModal({required this.amenity});

  @override
  State<_AmenityBookingModal> createState() => _AmenityBookingModalState();
}

class _AmenityBookingModalState extends State<_AmenityBookingModal> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);

  List<dynamic> _existingBookings = [];
  bool _isLoadingSlots = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() => _isLoadingSlots = true);
    try {
      final list = await FacilitiesApiService.fetchAmenityBookings(
        widget.amenity['amenity_id'],
      );
      setState(() => _existingBookings = list);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingSlots = false);
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  int _timeToMinutes(String timeStr) {
    try {
      final clean = timeStr.trim().split(' ')[0];
      final parts = clean.split(':');
      return (int.parse(parts[0]) * 60) + int.parse(parts[1]);
    } catch (_) {
      return 0;
    }
  }

  List<dynamic> _getSlotsForSelectedDate() {
    final dateStr = _formatDate(_selectedDate);
    return _existingBookings
        .where((b) => b['booking_date'].toString().startsWith(dateStr))
        .toList();
  }

  bool _checkOverlap() {
    final slots = _getSlotsForSelectedDate();
    if (slots.isEmpty) return false;

    final selectedStartMinutes = _startTime.hour * 60 + _startTime.minute;
    final selectedEndMinutes = _endTime.hour * 60 + _endTime.minute;

    for (var b in slots) {
      final bStart = _timeToMinutes(b['start_time'].toString());
      final bEnd = _timeToMinutes(b['end_time'].toString());

      if (selectedStartMinutes < bEnd && selectedEndMinutes > bStart) {
        return true;
      }
    }
    return false;
  }

  Future<void> _submitBooking() async {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (startMinutes >= endMinutes) {
      setState(() => _errorMessage = 'End time must be after start time.');
      return;
    }

    if (_checkOverlap()) {
      setState(() => _errorMessage = 'This slot is already booked or held.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final res = await FacilitiesApiService.bookAmenity(
        amenityId: widget.amenity['amenity_id'],
        bookingDate: _formatDate(_selectedDate),
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message'] ??
                  'Slot reserved! Please complete payment within 1 hour.',
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slotsToday = _getSlotsForSelectedDate();
    final hasConflict = _checkOverlap();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Book ${widget.amenity['amenity_name']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              leading: const Icon(Icons.calendar_month, color: Colors.cyan),
              title: const Text(
                'Selected Date',
                style: TextStyle(fontSize: 12),
              ),
              subtitle: Text(
                _formatDate(_selectedDate),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Occupied Slots for this Date:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (_isLoadingSlots)
                        const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (slotsToday.isEmpty)
                    const Text(
                      '🟢 All hours available on this date.',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: slotsToday.map((b) {
                        final isConfirmed = b['status'] == 'confirmed';
                        return Chip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: isConfirmed
                              ? Colors.red.shade50
                              : Colors.orange.shade50,
                          side: BorderSide(
                            color: isConfirmed
                                ? Colors.red.shade200
                                : Colors.orange.shade200,
                          ),
                          label: Text(
                            '${b['start_time'].toString().substring(0, 5)} - ${b['end_time'].toString().substring(0, 5)} (${isConfirmed ? 'Booked' : 'Held'})',
                            style: TextStyle(
                              fontSize: 11,
                              color: isConfirmed
                                  ? Colors.red.shade900
                                  : Colors.orange.shade900,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    title: const Text(
                      'Start Time',
                      style: TextStyle(fontSize: 11),
                    ),
                    subtitle: Text(
                      _startTime.format(context),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _startTime,
                      );
                      if (picked != null) setState(() => _startTime = picked);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    title: const Text(
                      'End Time',
                      style: TextStyle(fontSize: 11),
                    ),
                    subtitle: Text(
                      _endTime.format(context),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _endTime,
                      );
                      if (picked != null) setState(() => _endTime = picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasConflict)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 18,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selected time overlaps with an existing reservation.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_errorMessage != null && !hasConflict) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (_isSubmitting || hasConflict) ? null : _submitBooking,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.cyan.shade700,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Reserve Slot (1 Hr Hold)',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
