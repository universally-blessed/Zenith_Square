import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/networks/operational_api_service.dart';

class MyVehiclesPage extends StatefulWidget {
  const MyVehiclesPage({super.key});

  @override
  State<MyVehiclesPage> createState() => _MyVehiclesPageState();
}

class _MyVehiclesPageState extends State<MyVehiclesPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";

  List<dynamic> _vehiclesList = [];
  bool _pageLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFleetData();
  }

  Future<void> _loadFleetData() async {
    try {
      final dataset = await OperationalApiService.fetchVehicles(_sessionToken);
      if (mounted) {
        setState(() {
          _vehiclesList = dataset;
          _pageLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _pageLoading = false);
        _showSnack("Error fetching registered database parameters.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'My Vehicles',
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
              onRefresh: _loadFleetData,
              color: primaryBlue,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Registered Fleet',
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showVehicleFormModal(context),
                        icon: const Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: primaryBlue,
                        ),
                        label: Text(
                          'Add New',
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _vehiclesList.isEmpty
                      ? _buildEmptyStatePlaceholder()
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _vehiclesList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final vehicle = _vehiclesList[index];
                            return _buildVehicleCard(context, vehicle);
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyStatePlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60.0),
        child: Text(
          'No vehicles registered to your unit allocation.',
          style: GoogleFonts.inter(color: Colors.black38, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, dynamic vehicle) {
    // Falls back to direct array index value evaluation if the table row structure changes
    final int databaseId = vehicle['id'] ?? 0;
    final String type = vehicle['vehicle_type'] ?? 'Car';
    IconData vehicleIcon = type == 'Car'
        ? Icons.directions_car_filled_outlined
        : Icons.two_wheeler_outlined;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(vehicleIcon, color: primaryBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle['vehicle_number'] ?? '',
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$type  • Slot: ${vehicle['vehicle_allotment_number'] ?? 'N/A'}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
              size: 20,
            ),
            onPressed: () async {
              setState(() => _pageLoading = true);
              bool deleted = await OperationalApiService.deleteVehicle(
                _sessionToken,
                databaseId,
              );
              if (deleted) {
                _showSnack("Vehicle deployment mapping unlinked.");
                _loadFleetData();
              } else {
                setState(() => _pageLoading = false);
                _showSnack("Failed to execute deletion schema routine.");
              }
            },
          ),
        ],
      ),
    );
  }

  void _showVehicleFormModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final numberController = TextEditingController();
    final spotController = TextEditingController();
    String selectedType = 'Car';

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
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Register New Vehicle',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const Divider(height: 24),
                    TextFormField(
                      controller: numberController,
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: darkText,
                        fontWeight: FontWeight.w600,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Plate number required"
                          : null,
                      decoration: _inputDecoration(
                        'Vehicle Plate Number',
                        Icons.subtitles_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: spotController,
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: darkText,
                        fontWeight: FontWeight.w600,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Parking spot location ID required"
                          : null,
                      decoration: _inputDecoration(
                        'Assigned Parking Spot ID',
                        Icons.local_parking_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: darkText,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _inputDecoration(
                        'Vehicle Segment',
                        Icons.category_outlined,
                      ),
                      items: ['Car', 'Bike', 'Scooter']
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(context);
                            setState(() => _pageLoading = true);

                            bool saved = await OperationalApiService.addVehicle(
                              _sessionToken,
                              {
                                'number': numberController.text
                                    .trim()
                                    .toUpperCase(),
                                'type': selectedType,
                                'spot': spotController.text
                                    .trim()
                                    .toUpperCase(),
                              },
                            );

                            if (saved) {
                              _loadFleetData();
                            } else {
                              setState(() => _pageLoading = false);
                              _showSnack("Failed to add vehicle to server.");
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Confirm Registration',
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

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.lexend(fontSize: 12.5)),
        behavior: SnackBarBehavior.floating,
      ),
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
