import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyVehiclesPage extends StatefulWidget {
  const MyVehiclesPage({super.key});

  @override
  State<MyVehiclesPage> createState() => _MyVehiclesPageState();
}

class _MyVehiclesPageState extends State<MyVehiclesPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

  // Initializing mock operational data arrays based on your Vehicle Data Dictionary structure
  final List<Map<String, String>> _myVehicles = [
    {'id': 'VH001', 'number': 'GJ01AB1234', 'type': 'Car', 'spot': 'P-101'},
    {'id': 'VH002', 'number': 'GJ01XYZ9876', 'type': 'Bike', 'spot': 'P-101-B'},
  ];

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
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  onPressed: () =>
                      _showVehicleFormModal(context), // CREATE Trigger
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

            _myVehicles.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Text(
                        'No vehicles registered to your unit allocation.',
                        style: GoogleFonts.inter(
                          color: Colors.black38,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _myVehicles.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final vehicle = _myVehicles[index];
                      return _buildVehicleCrudCard(context, vehicle, index);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCrudCard(
    BuildContext context,
    Map<String, String> vehicle,
    int index,
  ) {
    IconData vehicleIcon = vehicle['type'] == 'Car'
        ? Icons.directions_car_filled_outlined
        : Icons.two_wheeler_outlined;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(vehicleIcon, color: primaryBlue, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle['number']!,
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${vehicle['type']}  • Slot: ${vehicle['spot']}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Contextual Actions Menu (UPDATE & DELETE Trigger Hooks)
          PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'edit') {
                _showVehicleFormModal(
                  context,
                  vehicle: vehicle,
                  index: index,
                ); // UPDATE execution
              } else if (action == 'delete') {
                _executeDeleteConfirmation(index); // DELETE execution
              }
            },
            icon: const Icon(Icons.more_vert_rounded, color: Colors.black38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Edit Details',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Remove',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Modern UI/UX Bottom Sheet Overlay handling both CREATE and UPDATE modes
  void _showVehicleFormModal(
    BuildContext context, {
    Map<String, String>? vehicle,
    int? index,
  }) {
    final bool isEditMode = vehicle != null;

    final TextEditingController numberController = TextEditingController(
      text: isEditMode ? vehicle['number'] : '',
    );
    final TextEditingController spotController = TextEditingController(
      text: isEditMode ? vehicle['spot'] : '',
    );
    String selectedType = isEditMode ? vehicle['type']! : 'Car';

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
                isEditMode ? 'Modify Vehicle Details' : 'Register New Vehicle',
                style: GoogleFonts.lexend(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: numberController,
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDecoration(
                  'Vehicle Plate Number',
                  Icons.subtitles_outlined,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: spotController,
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDecoration(
                  'Assigned Parking Spot ID',
                  Icons.local_parking_rounded,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: _inputDecoration(
                  'Vehicle Segment',
                  Icons.category_outlined,
                ),
                items: ['Car', 'Bike', 'Scooter']
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) selectedType = val;
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (numberController.text.isNotEmpty &&
                        spotController.text.isNotEmpty) {
                      setState(() {
                        if (isEditMode) {
                          // UPDATE Operation State Manipulation
                          _myVehicles[index!] = {
                            'id': vehicle['id']!,
                            'number': numberController.text.trim(),
                            'type': selectedType,
                            'spot': spotController.text.trim(),
                          };
                        } else {
                          // CREATE Operation State Manipulation
                          _myVehicles.add({
                            'id': 'VH00${_myVehicles.length + 1}',
                            'number': numberController.text.trim(),
                            'type': selectedType,
                            'spot': spotController.text.trim(),
                          });
                        }
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isEditMode ? 'Save Changes' : 'Confirm Registration',
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
        );
      },
    );
  }

  void _executeDeleteConfirmation(int index) {
    // REMOVE Operation State Manipulation with explicit UX notification loops
    setState(() {
      _myVehicles.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Vehicle record systematically unlinked.',
          style: GoogleFonts.lexend(fontSize: 13),
        ),
        backgroundColor: darkText,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryBlue, size: 20),
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
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
    );
  }
}
