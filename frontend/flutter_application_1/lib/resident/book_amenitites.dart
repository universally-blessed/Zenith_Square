import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../api_services.dart';

class BookAmenitiesPage extends StatefulWidget {
  const BookAmenitiesPage({super.key});

  @override
  State<BookAmenitiesPage> createState() => _BookAmenitiesPageState();
}

class _BookAmenitiesPageState extends State<BookAmenitiesPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

  // Active secure user token session context variable matching Django backend constraints
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
    _countdownTimer
        ?.cancel(); // Always clean system stream allocations to avoid memory leaks
    super.dispose();
  }

  Future<void> _loadLiveReservations() async {
    try {
      final dataset = await ApiService.fetchAmenityBookings(_sessionToken);
      setState(() {
        _myBookings = dataset;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("Failed to update reservation listings feed.");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.lexend(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // UTILITY HELPER: Computes time differential leftovers down to text strings natively
  String _calculateTimeRemaining(dynamic deadlineInput) {
    if (deadlineInput == null) return "00:00";
    try {
      DateTime deadline = DateTime.parse(deadlineInput.toString());
      final difference = deadline.difference(DateTime.now());
      if (difference.isNegative) {
        return "00:00";
      } // Window systematically run down

      String minutes = difference.inMinutes
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      String seconds = difference.inSeconds
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      return "$minutes:$seconds remaining";
    } catch (_) {
      return "00:00";
    }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadLiveReservations,
              color: primaryBlue,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
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
                        icon: const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.white,
                        ),
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

                  _myBookings.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 80.0),
                            child: Text(
                              'No asset facility reservations logged.',
                              style: GoogleFonts.inter(
                                color: Colors.black38,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _myBookings.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final booking = _myBookings[index];
                            return _buildStateAwareBookingCard(
                              context,
                              booking,
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildStateAwareBookingCard(BuildContext context, dynamic booking) {
    final String status = booking['status'] ?? 'pending';
    final bool isAwaitingPayment = status == 'approved_awaiting_payment';

    // Check if the timer has theoretically expired locally on device runtime configurations
    bool isExpired = false;
    if (isAwaitingPayment && booking['payment_deadline'] != null) {
      isExpired = DateTime.parse(
        booking['payment_deadline'].toString(),
      ).difference(DateTime.now()).isNegative;
    }

    Color statusColor = Colors.orange.shade800;
    String statusLabel = 'PENDING APPROVAL';

    if (status == 'approved') {
      statusColor = Colors.green;
      statusLabel = 'CONFIRMED';
    } else if (isAwaitingPayment) {
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
                booking['booking_id'] ?? '',
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
            booking['amenity_name'] ?? 'Facility Asset',
            style: GoogleFonts.lexend(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "${booking['booking_date']}  •  ${booking['slots']}",
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
                  ), // Direct connection to payment route maps
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
                    "Pay ${booking['cost']}",
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
    String? selectedTimeSlot;

    // Master array of all possible operational time blocks in Zenith Square
    final List<String> masterTimeSlots = [
      '09:00 AM - 12:00 PM',
      '01:00 PM - 04:00 PM',
      '05:00 PM - 08:00 PM',
      '08:00 PM - 11:00 PM',
    ];

    // In production, you would fetch these dynamically from the server for the chosen day/amenity context
    final List<String> databaseBookedSlots = ['01:00 PM - 04:00 PM'];

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

            // Auto-select the first available slot if nothing is selected yet to prevent selection errors
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
                        setModalState(() => selectedAmenity = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. Date Picker Trigger Card Configuration
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
                              null; // Clear selected slot to force recalculation on new date choice
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
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
                          Text(
                            "${chosenDate.year}-${chosenDate.month.toString().padLeft(2, '0')}-${chosenDate.day.toString().padLeft(2, '0')}",
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: darkText,
                            ),
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
                            'Available Window Slot',
                            Icons.access_time_rounded,
                          ),
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

                  // 4. Submit Request Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: availableSlots.isEmpty
                          ? null
                          : () async {
                              Navigator.pop(context);
                              setState(() => _isLoading = true);

                              bool
                              success = await ApiService.submitBookingRequest(
                                _sessionToken,
                                {
                                  'amenity_name': selectedAmenity,
                                  'booking_date':
                                      "${chosenDate.year}-${chosenDate.month.toString().padLeft(2, '0')}-${chosenDate.day.toString().padLeft(2, '0')}",
                                  'slots': selectedTimeSlot,
                                },
                              );

                              if (success) {
                                _showSnack(
                                  "Reservation requested successfully!",
                                );
                                _loadLiveReservations();
                              } else {
                                setState(() => _isLoading = false);
                                _showSnack("Failed to submit booking request.");
                              }
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
