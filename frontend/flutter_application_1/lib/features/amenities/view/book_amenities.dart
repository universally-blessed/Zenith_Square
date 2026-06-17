import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../../core/networks/operational_api_service.dart';

class BookAmenitiesPage extends StatefulWidget {
  const BookAmenitiesPage({super.key});

  @override
  State<BookAmenitiesPage> createState() => _BookAmenitiesPageState();
}

class _BookAmenitiesPageState extends State<BookAmenitiesPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);
  static const Color lightBg = Color(0xFFF8F9FA);

  // Active secure token simulation context
  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";

  List<dynamic> _myBookings = [];
  bool _isLoading = true;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadLiveReservations();

    // Start a 1-second interval ticker stream loop to rebuild active countdown clocks dynamically
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel(); // Clean up system stream variables safely
    super.dispose();
  }

  Future<void> _loadLiveReservations() async {
    final data = await OperationalApiService.fetchLiveReservations(
      _sessionToken,
    );
    if (mounted) {
      setState(() {
        _myBookings = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: Text(
          'Amenity Bookings',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 17,
          ),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : _myBookings.isEmpty
          ? _buildEmptyPlaceholder()
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              itemCount: _myBookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final booking = _myBookings[index];
                return _buildBookingTicketCard(booking);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryBlue,
        icon: const Icon(
          Icons.add_circle_outline_rounded,
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          'New Reservation',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 13,
          ),
        ),
        onPressed: () => _openBookingFormSheet(context),
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_seat_outlined,
                color: primaryBlue,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Bookings',
              style: GoogleFonts.lexend(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You have no active shared space reservations. Tap the button below to reserve a facility slot.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: Colors.black38,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingTicketCard(Map<String, dynamic> booking) {
    String amenity = booking['amenity_name'] ?? 'Facility';
    String dateStr = booking['booking_date'] ?? '';
    String slot = booking['slot'] ?? '';
    String status = booking['status'] ?? 'CONFIRMED';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                amenity.toUpperCase(),
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.lexend(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 0.5),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Colors.black38,
              ),
              const SizedBox(width: 8),
              Text(
                'Date: $dateStr',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: Colors.black38,
              ),
              const SizedBox(width: 8),
              Text(
                'Slot: $slot',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCountdownBanner(dateStr, slot),
        ],
      ),
    );
  }

  Widget _buildCountdownBanner(String targetDate, String slotTime) {
    try {
      String startTimeString = slotTime
          .split('-')[0]
          .trim(); // e.g., parses "10:00 AM"

      // Clean cross-platform date parsing configuration logic
      List<String> dateParts = targetDate.split('-');
      int year = int.parse(dateParts[0]);
      int month = int.parse(dateParts[1]);
      int day = int.parse(dateParts[2]);

      List<String> timeParts = startTimeString.split(' ')[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      if (startTimeString.toLowerCase().contains('pm') && hour != 12) {
        hour += 12;
      }
      if (startTimeString.toLowerCase().contains('am') && hour == 12) hour = 0;

      final targetDateTime = DateTime(year, month, day, hour, minute);
      final remainingTime = targetDateTime.difference(DateTime.now());

      if (remainingTime.isNegative) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              'Reservation Period Concluded',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: Colors.black38,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }

      int hours = remainingTime.inHours;
      int mins = remainingTime.inMinutes.remainder(60);
      int secs = remainingTime.inSeconds.remainder(60);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_bottom_rounded,
              size: 14,
              color: Colors.amber.shade900,
            ),
            const SizedBox(width: 6),
            Text(
              'Starts In: ${hours.toString().padLeft(2, '0')}h ${mins.toString().padLeft(2, '0')}m ${secs.toString().padLeft(2, '0')}s',
              style: GoogleFonts.lexend(
                fontSize: 11.5,
                color: Colors.amber.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  void _openBookingFormSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String selectedAmenity = 'Clubhouse';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedSlot = '10:00 AM - 12:00 PM';
    bool isSubmittingForm = false;

    final List<String> amenities = [
      'Clubhouse',
      'Gymnasium',
      'Community Hall',
      'Swimming Pool',
    ];
    final List<String> availableSlots = [
      '08:00 AM - 10:00 AM',
      '10:00 AM - 12:00 PM',
      '04:00 PM - 06:00 PM',
      '06:00 PM - 08:00 PM',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reserve Shared Space',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const Divider(height: 20),

                    // Dropdown Amenity Field
                    DropdownButtonFormField<String>(
                      initialValue: selectedAmenity,
                      items: amenities
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setModalState(() => selectedAmenity = v!),
                      decoration: _modalInputDecoration(
                        'Select Facility',
                        Icons.gite_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Date Selection Form Block
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 30),
                          ),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBFBFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: primaryBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Date: ${selectedDate.toIso8601String().split('T')[0]}',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: darkText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Dropdown Slot Field
                    DropdownButtonFormField<String>(
                      initialValue: selectedSlot,
                      items: availableSlots
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => setModalState(() => selectedSlot = v!),
                      decoration: _modalInputDecoration(
                        'Select Time Slot',
                        Icons.access_time_filled_rounded,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Request Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSubmittingForm
                            ? null
                            : () async {
                                setModalState(() => isSubmittingForm = true);

                                final result =
                                    await OperationalApiService.submitBookingRequest(
                                      token: _sessionToken,
                                      amenityName: selectedAmenity,
                                      bookingDate: selectedDate
                                          .toIso8601String()
                                          .split('T')[0],
                                      slotTime: selectedSlot,
                                    );

                                if (result['success'] == true) {
                                  _loadLiveReservations();
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result['message']),
                                        backgroundColor: Colors.green.shade800,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } else {
                                  setModalState(() => isSubmittingForm = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result['error']),
                                      backgroundColor: Colors.red.shade800,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                        child: isSubmittingForm
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Confirm Booking Request',
                                style: GoogleFonts.lexend(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _modalInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryBlue, size: 20),
      labelStyle: GoogleFonts.inter(fontSize: 13.5, color: Colors.black45),
      filled: true,
      fillColor: const Color(0xFFFBFBFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
    );
  }
}
