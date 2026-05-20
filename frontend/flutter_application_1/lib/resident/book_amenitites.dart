import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async'; // Required for high-accuracy frontend countdown stream loops

class BookAmenitiesPage extends StatefulWidget {
  const BookAmenitiesPage({super.key});

  @override
  State<BookAmenitiesPage> createState() => _BookAmenitiesPageState();
}

class _BookAmenitiesPageState extends State<BookAmenitiesPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

  // High-fidelity active mock tracker mirroring your database state rows (Page 59-60)
  final List<Map<String, dynamic>> _myBookings = [
    {
      'booking_id': 'AB001', // amenity_booking.booking_id
      'amenity_name': 'Clubhouse Hall', // amenity.amenity_name
      'booking_date': '2026-05-28',
      'slots': '04:00 PM - 07:00 PM',
      'status':
          'approved_awaiting_payment', // The critical dynamic conditional flag
      // Simulating a backend timestamp set exactly 45 minutes and 12 seconds from expiration
      'payment_deadline': DateTime.now().add(
        const Duration(minutes: 45, seconds: 12),
      ),
      'cost': '₹ 1,500.00',
    },
    {
      'booking_id': 'AB002',
      'amenity_name': 'Amphitheatre',
      'booking_date': '2026-06-02',
      'slots': '07:00 PM - 09:00 PM',
      'status': 'pending', // Awaiting Secretary evaluation signature loops
      'payment_deadline': null,
      'cost': '₹ 500.00',
    },
  ];

  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Senior Developer Pattern: Start a 1-second interval stream ticker loop to rebuild active clocks
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer
        ?.cancel(); // Always clean system stream allocations to avoid memory leaks
    super.dispose();
  }

  // UTILITY HELPER: Computes time differential leftovers down to text strings natively
  String _calculateTimeRemaining(DateTime deadline) {
    final difference = deadline.difference(DateTime.now());
    if (difference.isNegative) {
      return "00:00"; // Window systematically run down
    }
    String minutes = difference.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    String seconds = difference.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return "$minutes:$seconds remaining";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Amenity Reservations',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        physics: const BouncingScrollPhysics(),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Reservation Statuses',
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showNewRequestDialog(context),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: Text(
                  'New Request',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _myBookings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final booking = _myBookings[index];
              return _buildStateAwareBookingCard(context, booking);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStateAwareBookingCard(
    BuildContext context,
    Map<String, dynamic> booking,
  ) {
    final String status = booking['status'];
    final bool isAwaitingPayment = status == 'approved_awaiting_payment';

    // Check if the timer has theoretically expired locally on device runtime configurations
    bool isExpired = false;
    if (isAwaitingPayment && booking['payment_deadline'] != null) {
      isExpired = booking['payment_deadline']
          .difference(DateTime.now())
          .isNegative;
    }

    Color statusColor = Colors.orange;
    String statusLabel = 'PENDING APPROVAL';

    if (isAwaitingPayment) {
      statusColor = isExpired ? Colors.red : Colors.blue.shade700;
      statusLabel = isExpired ? 'EXPIRED' : 'APPROVED - AWAITING PAYMENT';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAwaitingPayment && !isExpired
              ? Colors.blue.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.06),
          width: isAwaitingPayment && !isExpired ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                booking['booking_id'],
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.lexend(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            booking['amenity_name'],
            style: GoogleFonts.lexend(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${booking['booking_date']}  •  ${booking['slots']}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.black45,
              fontWeight: FontWeight.w500,
            ),
          ),

          // CONTEXTUAL CONDITIONAL UX TILES: Rendered strictly during active countdown windows
          if (isAwaitingPayment && !isExpired) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1, thickness: 0.6),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.hourglass_top_rounded,
                      size: 16,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _calculateTimeRemaining(booking['payment_deadline']),
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/maintenance',
                  ), // Direct connection down to payment route maps
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Pay ${booking['cost']}',
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showNewRequestDialog(BuildContext context) {
    String selectedAmenity = 'Clubhouse Hall';
    DateTime chosenDate = DateTime.now().add(const Duration(days: 1));
    String?
    selectedTimeSlot; // Keep nullable initially to force selecting an available one

    // Master array of all possible operational time blocks in Zenith Square
    final List<String> masterTimeSlots = [
      '09:00 AM - 12:00 PM',
      '01:00 PM - 04:00 PM',
      '05:00 PM - 08:00 PM',
      '08:00 PM - 11:00 PM',
    ];

    // SIMULATED BACKEND API RESPONSE: Slots already booked in the database for the selected criteria
    // In a real app, this map would update via an API call whenever the user changes the date or amenity.
    final List<String> databaseBookedSlots = [
      '01:00 PM - 04:00 PM',
      '08:00 PM - 11:00 PM',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Senior Developer Pattern: Dynamically compute available slots by filtering out databaseBookedSlots
            final List<String> availableSlots = masterTimeSlots
                .where((slot) => !databaseBookedSlots.contains(slot))
                .toList();

            // Auto-select the first available slot if nothing is selected yet to prevent errors
            if (selectedTimeSlot == null && availableSlots.isNotEmpty) {
              selectedTimeSlot = availableSlots.first;
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book an Amenity',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Only available time slots are visible below. Already reserved windows have been automatically filtered out.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.black45,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 1. Amenity Selector
                  DropdownButtonFormField<String>(
                    initialValue: selectedAmenity,
                    decoration: _modalInputDecoration(
                      'Select Asset Facility',
                      Icons.sports_tennis_outlined,
                    ),
                    items: ['Clubhouse Hall', 'Amphitheatre', 'Gymnasium']
                        .map(
                          (name) =>
                              DropdownMenuItem(value: name, child: Text(name)),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedAmenity = val;
                          // In production, trigger an API fetch here to update databaseBookedSlots for this amenity
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. Date Picker
                  InkWell(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: chosenDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setModalState(() {
                          chosenDate = picked;
                          selectedTimeSlot =
                              null; // Clear selected slot to force recalculation on new date
                          // In production, trigger an API fetch here to update databaseBookedSlots for this date
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
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
                            Icons.calendar_today_outlined,
                            color: primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reservation Date',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.black38,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${chosenDate.year}-${chosenDate.month.toString().padLeft(2, '0')}-${chosenDate.day.toString().padLeft(2, '0')}",
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: darkText,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Colors.black38,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Dynamic Filtered Time Slot Dropdown
                  availableSlots.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'All slots are fully booked for this date. Please select an alternate date.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: Colors.red.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          initialValue: selectedTimeSlot,
                          decoration: _modalInputDecoration(
                            'Available Time Allocation Window',
                            Icons.access_time_rounded,
                          ),
                          // Maps ONLY the filtered slots array to the UI dropdown items
                          items: availableSlots
                              .map(
                                (slot) => DropdownMenuItem(
                                  value: slot,
                                  child: Text(slot),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedTimeSlot = val);
                            }
                          },
                        ),
                  const SizedBox(height: 30),

                  // 4. Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: availableSlots.isEmpty
                          ? null
                          : () {
                              setState(() {
                                _myBookings.add({
                                  'booking_id': 'AB00${_myBookings.length + 1}',
                                  'amenity_name': selectedAmenity,
                                  'booking_date':
                                      "${chosenDate.year}-${chosenDate.month.toString().padLeft(2, '0')}-${chosenDate.day.toString().padLeft(2, '0')}",
                                  'slots': selectedTimeSlot,
                                  'status': 'pending',
                                  'payment_deadline': null,
                                  'cost': selectedAmenity == 'Clubhouse Hall'
                                      ? '₹ 1,500.00'
                                      : '₹ 500.00',
                                });
                              });
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Reservation request logged. Awaiting Secretary confirmation.',
                                    style: GoogleFonts.lexend(fontSize: 13),
                                  ),
                                  backgroundColor: primaryBlue,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        disabledBackgroundColor: Colors.grey.shade200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Submit Booking Request',
                        style: GoogleFonts.lexend(
                          color: availableSlots.isEmpty
                              ? Colors.black38
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Global modal textfield visual framework generator
  InputDecoration _modalInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1A237E), size: 20),
      labelStyle: GoogleFonts.inter(fontSize: 13.5, color: Colors.black45),
      filled: true,
      fillColor: const Color(0xFFFBFBFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
      ),
    );
  }
}
