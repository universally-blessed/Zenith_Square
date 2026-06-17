import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/networks/operational_api_service.dart';

class ManageMeetingsPage extends StatefulWidget {
  const ManageMeetingsPage({super.key});

  @override
  State<ManageMeetingsPage> createState() => _ManageMeetingsPageState();
}

class _ManageMeetingsPageState extends State<ManageMeetingsPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color emeraldGreen = Color(0xFF2E7D32);

  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";
  List<dynamic> _meetingsList = [];
  bool _pageLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeetingRecords();
  }

  Future<void> _loadMeetingRecords() async {
    final dataset = await OperationalApiService.fetchMeetings(_sessionToken);
    if (mounted) {
      setState(() {
        _meetingsList = dataset;
        _pageLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: Text(
          'Meeting Assembly',
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
      body: _pageLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadMeetingRecords,
              color: primaryBlue,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Discussion Schedules',
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showMeetingFormModal(context),
                        icon: const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Schedule',
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
                  _meetingsList.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 80.0),
                            child: Text(
                              'No society board meetings scheduled.',
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
                          itemCount: _meetingsList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final meeting = _meetingsList[index];
                            return _buildMeetingCard(meeting, index);
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildMeetingCard(dynamic meeting, int index) {
    String rawDate = meeting['meeting_date'] ?? meeting['date'] ?? '';
    bool isUpcoming = true;
    try {
      if (DateTime.parse(rawDate).isBefore(DateTime.now())) {
        isUpcoming = false;
      }
    } catch (_) {}

    final Color statusColor = isUpcoming ? Colors.blue.shade700 : emeraldGreen;
    String meetingId = meeting['meeting_id'] ?? meeting['id'] ?? 'MTG-ID';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                meetingId,
                style: GoogleFonts.lexend(
                  fontSize: 11,
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
                  isUpcoming ? 'UPCOMING' : 'CONCLUDED',
                  style: GoogleFonts.lexend(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            meeting['title'] ?? 'Committee Assembly',
            style: GoogleFonts.lexend(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            meeting['agenda'] ?? meeting['description'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: lightBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 14,
                  color: primaryBlue.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  rawDate,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: primaryBlue.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  meeting['start_time'] ?? meeting['time'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: primaryBlue.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          meeting['location'] ?? 'Main Hall',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (meeting['minutes_doc'] != null &&
              meeting['minutes_doc'].toString().isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1, thickness: 0.5),
            ),
            Text(
              'Minutes of Meeting (MOM):',
              style: GoogleFonts.lexend(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              meeting['minutes_doc'],
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: emeraldGreen,
                height: 1.4,
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1, thickness: 0.5),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showMomEditorModal(context, meetingId),
                icon: Icon(
                  meeting['minutes_doc'] == null
                      ? Icons.add_task
                      : Icons.history_edu,
                  size: 14,
                  color: Colors.white,
                ),
                label: Text(
                  meeting['minutes_doc'] == null ? 'Record MOM' : 'Update MOM',
                  style: GoogleFonts.lexend(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: meeting['minutes_doc'] == null
                      ? Colors.grey.shade800
                      : emeraldGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMeetingFormModal(BuildContext context) {
    final titleController = TextEditingController();
    final agendaController = TextEditingController();
    final locationController = TextEditingController(
      text: 'Clubhouse Main Hall',
    );
    String chosenDate = "2026-06-18";
    String chosenTime = "07:00 PM";

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
                    'Schedule Assembly Notice',
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const Divider(height: 24),
                  TextFormField(
                    controller: titleController,
                    decoration: _inputDecoration(
                      'Meeting Title Topic',
                      Icons.title,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: agendaController,
                    maxLines: 2,
                    decoration: _inputDecoration(
                      'Meeting Agenda Details',
                      Icons.description_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: locationController,
                    decoration: _inputDecoration(
                      'Target Venue Room',
                      Icons.pin_drop_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            DateTime? d = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(
                                const Duration(days: 1),
                              ),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 60),
                              ),
                            );
                            if (d != null) {
                              setModalState(
                                () => chosenDate =
                                    "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}",
                              );
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 14),
                          label: Text(
                            chosenDate,
                            style: GoogleFonts.inter(fontSize: 12.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            TimeOfDay? t = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 19, minute: 0),
                            );
                            if (t != null) {
                              setModalState(
                                () => chosenTime = t.format(context),
                              );
                            }
                          },
                          icon: const Icon(Icons.access_time, size: 14),
                          label: Text(
                            chosenTime,
                            style: GoogleFonts.inter(fontSize: 12.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        if (titleController.text.isNotEmpty &&
                            agendaController.text.isNotEmpty) {
                          bool success =
                              await OperationalApiService.createSocietyMeeting(
                                _sessionToken,
                                {
                                  'title': titleController.text.trim(),
                                  'agenda': agendaController.text.trim(),
                                  'location': locationController.text.trim(),
                                  'meeting_date': chosenDate,
                                  'start_time': chosenTime,
                                },
                              );
                          if (success) {
                            _loadMeetingRecords();
                            if (context.mounted) Navigator.pop(context);
                            _showSnack("New meeting broadcasted successfully.");
                          }
                        }
                      },
                      child: Text(
                        'Confirm Notification Data',
                        style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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

  void _showMomEditorModal(BuildContext context, String meetingId) {
    final momController = TextEditingController();

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
                'Record Minutes of Meeting (MOM)',
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Provide resolutions finalized during this block.',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: momController,
                maxLines: 4,
                style: GoogleFonts.inter(fontSize: 13.5, color: darkText),
                decoration: InputDecoration(
                  hintText: 'Add minutes transcript point log...',
                  filled: true,
                  fillColor: const Color(0xFFFBFBFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emeraldGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (momController.text.isNotEmpty) {
                      bool success =
                          await OperationalApiService.updateMeetingMinutes(
                            _sessionToken,
                            meetingId,
                            momController.text.trim(),
                          );
                      if (success) {
                        _loadMeetingRecords();
                        if (context.mounted) Navigator.pop(context);
                        _showSnack("MOM logs published successfully.");
                      }
                    }
                  },
                  child: Text(
                    'Publish MOM Logs',
                    style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryBlue, size: 18),
      labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.black45),
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
