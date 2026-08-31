import 'package:flutter/material.dart';
import '../../data/datasource/facilities_api_service.dart';

class ChairmanVehiclesScreen extends StatefulWidget {
  const ChairmanVehiclesScreen({super.key});

  @override
  State<ChairmanVehiclesScreen> createState() => _ChairmanVehiclesScreenState();
}

class _ChairmanVehiclesScreenState extends State<ChairmanVehiclesScreen>
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
        title: const Text('Vehicle & Parking Directory'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/chairman-home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Society Directory'),
            Tab(text: 'My Vehicles'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SocietyVehiclesDirectoryTab(),
          _ChairmanPersonalVehiclesTab(),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 1: SOCIETY-WIDE VEHICLE DIRECTORY (GET /vehicles/?all=true)
// -------------------------------------------------------------
class _SocietyVehiclesDirectoryTab extends StatefulWidget {
  const _SocietyVehiclesDirectoryTab();

  @override
  State<_SocietyVehiclesDirectoryTab> createState() =>
      _SocietyVehiclesDirectoryTabState();
}

class _SocietyVehiclesDirectoryTabState
    extends State<_SocietyVehiclesDirectoryTab> {
  late Future<List<dynamic>> _vehiclesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  void _loadDirectory() {
    setState(() {
      _vehiclesFuture = FacilitiesApiService.fetchVehicles(allSociety: true);
    });
  }

  Future<void> _handleDelete(String vehicleId, String vehicleNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deregister Vehicle'),
        content: Text(
          'Deregister vehicle "$vehicleNumber" from the society database?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Deregister',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final res = await FacilitiesApiService.deleteVehicle(vehicleId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Vehicle deregistered.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _loadDirectory();
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Input Bar
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by Plate No., Resident, or Slot...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (val) =>
                setState(() => _searchQuery = val.trim().toLowerCase()),
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _vehiclesFuture,
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
                        onPressed: _loadDirectory,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final allVehicles = snapshot.data ?? [];
              final filtered = allVehicles.where((v) {
                if (_searchQuery.isEmpty) return true;
                final number = (v['vehicle_number'] ?? '')
                    .toString()
                    .toLowerCase();
                final resident = (v['resident_name'] ?? '')
                    .toString()
                    .toLowerCase();
                final slot = (v['vehicle_allotment_number'] ?? '')
                    .toString()
                    .toLowerCase();
                final flat = (v['flat_number'] ?? '').toString().toLowerCase();
                return number.contains(_searchQuery) ||
                    resident.contains(_searchQuery) ||
                    slot.contains(_searchQuery) ||
                    flat.contains(_searchQuery);
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No vehicles found.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _loadDirectory(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final v = filtered[i];
                    final isTwoWheeler = (v['vehicle_type'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains('2');
                    final resident = v['resident_name'] ?? 'Resident';
                    final flat = v['flat_number'] ?? '--';

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueGrey.shade50,
                          child: Icon(
                            isTwoWheeler
                                ? Icons.two_wheeler
                                : Icons.directions_car,
                            color: Colors.blueGrey.shade800,
                          ),
                        ),
                        title: Text(
                          v['vehicle_number'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              'Owner: $resident (Flat $flat)',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Type: ${v['vehicle_type']} • Slot: ${v['vehicle_allotment_number']}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Deregister Vehicle',
                          onPressed: () => _handleDelete(
                            v['vehicle_id'],
                            v['vehicle_number'],
                          ),
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
}

// -------------------------------------------------------------
// TAB 2: CHAIRMAN PERSONAL UNIT VEHICLES (GET /vehicles/)
// -------------------------------------------------------------
class _ChairmanPersonalVehiclesTab extends StatefulWidget {
  const _ChairmanPersonalVehiclesTab();

  @override
  State<_ChairmanPersonalVehiclesTab> createState() =>
      _ChairmanPersonalVehiclesTabState();
}

class _ChairmanPersonalVehiclesTabState
    extends State<_ChairmanPersonalVehiclesTab> {
  late Future<List<dynamic>> _vehiclesFuture;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  void _loadVehicles() {
    setState(() {
      _vehiclesFuture = FacilitiesApiService.fetchVehicles(allSociety: false);
    });
  }

  void _openAddVehicleSheet() {
    final formKey = GlobalKey<FormState>();
    final numberController = TextEditingController();
    final allotmentController = TextEditingController();
    String selectedType = '4-Wheeler';
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Register Unit Vehicle',
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
                  controller: numberController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Plate Number',
                    hintText: 'e.g. GJ01AB1234',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter plate number'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: '2-Wheeler',
                      child: Text('2-Wheeler (Bike/Scooter)'),
                    ),
                    DropdownMenuItem(
                      value: '4-Wheeler',
                      child: Text('4-Wheeler (Car/SUV)'),
                    ),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: allotmentController,
                  decoration: const InputDecoration(
                    labelText: 'Parking Slot / Sticker Tag',
                    hintText: 'e.g. P-101',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter parking slot'
                      : null,
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
                                await FacilitiesApiService.registerVehicle(
                                  vehicleNumber: numberController.text
                                      .trim()
                                      .toUpperCase(),
                                  vehicleType: selectedType,
                                  allotmentNumber: allotmentController.text
                                      .trim(),
                                );
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    res['message'] ?? 'Vehicle registered!',
                                  ),
                                  backgroundColor: Colors.green.shade700,
                                ),
                              );
                              _loadVehicles();
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
                    backgroundColor: Colors.blueGrey,
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
                          'Add Vehicle',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ],
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
        onPressed: _openAddVehicleSheet,
        backgroundColor: Colors.blueGrey,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Vehicle', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _vehiclesFuture,
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
                    onPressed: _loadVehicles,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final vehicles = snapshot.data ?? [];
          if (vehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_filled_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No personal vehicles registered.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadVehicles(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12.0),
              itemCount: vehicles.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final v = vehicles[i];
                final isTwoWheeler = (v['vehicle_type'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains('2');

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueGrey.shade50,
                      child: Icon(
                        isTwoWheeler ? Icons.two_wheeler : Icons.directions_car,
                        color: Colors.blueGrey.shade800,
                      ),
                    ),
                    title: Text(
                      v['vehicle_number'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      'Type: ${v['vehicle_type']}\nParking Slot: ${v['vehicle_allotment_number']}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Remove',
                      onPressed: () async {
                        await FacilitiesApiService.deleteVehicle(
                          v['vehicle_id'],
                        );
                        _loadVehicles();
                      },
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
