import 'package:flutter/material.dart';
import '../../data/datasource/facilities_api_service.dart';

class AmenitiesScreen extends StatefulWidget {
  const AmenitiesScreen({super.key});

  @override
  State<AmenitiesScreen> createState() => _AmenitiesScreenState();
}

class _AmenitiesScreenState extends State<AmenitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Amenities & Booking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pushReplacementNamed(context, "/home"),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Explore & Book'),
            Tab(text: 'My Bookings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_AmenitiesListTab(), _MyBookingsTab()],
      ),
    );
  }
}

class _AmenitiesListTab extends StatefulWidget {
  const _AmenitiesListTab();

  @override
  State<_AmenitiesListTab> createState() => _AmenitiesListTabState();
}

class _AmenitiesListTabState extends State<_AmenitiesListTab> {
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
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
          return const Center(child: Text('No amenities registered.'));
        }

        return RefreshIndicator(
          onRefresh: () async => _loadAmenities(),
          child: ListView.separated(
            padding: const EdgeInsets.all(12.0),
            itemCount: amenities.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final a = amenities[i];
              final isAvailable = a['amenity_status'] == 'available';

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
                          Container(
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
                            child: Text(
                              (a['amenity_status'] ?? '')
                                  .toString()
                                  .toUpperCase(),
                              style: TextStyle(
                                color: isAvailable
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
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
    );
  }
}

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

      // Overlap: (SelectedStart < ExistingEnd) AND (SelectedEnd > ExistingStart)
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

class _MyBookingsTab extends StatefulWidget {
  const _MyBookingsTab();

  @override
  State<_MyBookingsTab> createState() => _MyBookingsTabState();
}

class _MyBookingsTabState extends State<_MyBookingsTab> {
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
          return const Center(
            child: Text('You have no amenity booking requests.'),
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
              final rawStatus = (b['status'] ?? 'pending')
                  .toString()
                  .toLowerCase();
              final isExpired = b['is_payment_expired'] ?? false;

              Color badgeColor;
              String displayStatus;

              if (rawStatus == 'confirmed') {
                badgeColor = Colors.green;
                displayStatus = 'CONFIRMED';
              } else if (rawStatus == 'pending_payment' && !isExpired) {
                badgeColor = Colors.orange.shade800;
                displayStatus = 'TEMPORARY HOLD';
              } else if (rawStatus == 'expired' || isExpired) {
                badgeColor = Colors.red.shade700;
                displayStatus = 'EXPIRED (UNPAID)';
              } else {
                badgeColor = Colors.grey;
                displayStatus = rawStatus.toUpperCase();
              }

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
                        'Booking ID: #${b['booking_id']}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Date: ${b['booking_date']}  |  Time: ${b['start_time']} - ${b['end_time']}',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 13,
                        ),
                      ),
                      if (rawStatus == 'pending_payment' && !isExpired) ...[
                        const Divider(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Payment deadline: ${b['payment_deadline'] != null ? b['payment_deadline'].toString().substring(11, 16) : '--'}',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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
    );
  }
}
