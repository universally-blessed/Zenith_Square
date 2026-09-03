import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/add_society_dialog.dart';
import '../widgets/society_features_dialog.dart';
import '../widgets/edit_society_dialog.dart';
import '../widgets/society_occupancy_dialog.dart';

class SocietiesScreen extends StatefulWidget {
  const SocietiesScreen({super.key});

  @override
  State<SocietiesScreen> createState() => _SocietiesScreenState();
}

class _SocietiesScreenState extends State<SocietiesScreen> {
  List<dynamic> _societies = [];
  bool _loading = true;

  // Search & Pagination States
  final TextEditingController _societySearchController =
      TextEditingController();
  String _societySearchQuery = '';
  int _societyCurrentPage = 0;
  final int _rowsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _loadSocieties();
  }

  void _loadSocieties() async {
    setState(() => _loading = true);
    try {
      final societies = await ApiService.getSocieties();
      setState(() {
        _societies = societies;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _toggleSociety(String societyId) async {
    final success = await ApiService.toggleSocietyStatus(societyId);
    if (success) {
      _loadSocieties();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredSocieties = _societies.where((soc) {
      final id = (soc['society_id'] ?? '').toString().toLowerCase();
      final name = (soc['society_name'] ?? '').toString().toLowerCase();
      final city = (soc['society_city'] ?? '').toString().toLowerCase();
      final query = _societySearchQuery.toLowerCase();
      return id.contains(query) || name.contains(query) || city.contains(query);
    }).toList();

    final int totalPages = (filteredSocieties.length / _rowsPerPage).ceil();
    final int startIndex = _societyCurrentPage * _rowsPerPage;
    final int endIndex = (startIndex + _rowsPerPage > filteredSocieties.length)
        ? filteredSocieties.length
        : startIndex + _rowsPerPage;
    final paginatedSocieties = (startIndex < filteredSocieties.length)
        ? filteredSocieties.sublist(startIndex, endIndex)
        : [];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Registered Societies',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Society',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) =>
                      AddSocietyDialog(onSocietyAdded: _loadSocieties),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: 350,
          margin: const EdgeInsets.only(bottom: 16),
          child: TextField(
            controller: _societySearchController,
            decoration: InputDecoration(
              hintText: 'Search by Society ID, Name, or City...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _societySearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _societySearchController.clear();
                          _societySearchQuery = '';
                          _societyCurrentPage = 0;
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (val) {
              setState(() {
                _societySearchQuery = val;
                _societyCurrentPage = 0;
              });
            },
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
              ),
            ],
          ),
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(Colors.grey.shade100),
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Society Name')),
              DataColumn(label: Text('City')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Maintenance')),
              DataColumn(label: Text('Configure')),
              DataColumn(label: Text('Actions')),
            ],
            rows: paginatedSocieties.map<DataRow>((soc) {
              final bool isActive =
                  (soc['society_status'] ?? 'active')
                      .toString()
                      .toLowerCase() ==
                  'active';

              return DataRow(
                cells: [
                  DataCell(Text(soc['society_id'] ?? '')),
                  DataCell(Text(soc['society_name'] ?? '')),
                  DataCell(Text(soc['society_city'] ?? '')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text('₹${soc['standard_rate'] ?? 0}')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.tune,
                            color: Color(0xFF2563EB),
                            size: 20,
                          ),
                          tooltip: 'Configure Feature Flags',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  SocietyFeaturesDialog(society: soc),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.holiday_village_outlined,
                            color: Colors.teal,
                            size: 20,
                          ),
                          tooltip: 'View Occupancy & Residents',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  SocietyOccupancyDialog(society: soc),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                          tooltip: 'Edit Society Details',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => EditSocietyDialog(
                                society: soc,
                                onSocietyUpdated: _loadSocieties,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            isActive ? Icons.delete_outline : Icons.restore,
                            color: isActive ? Colors.redAccent : Colors.green,
                            size: 20,
                          ),
                          tooltip: isActive
                              ? 'Deactivate Society'
                              : 'Restore Society',
                          onPressed: () => _toggleSociety(soc['society_id']),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing ${filteredSocieties.isEmpty ? 0 : startIndex + 1} to $endIndex of ${filteredSocieties.length} societies',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _societyCurrentPage > 0
                      ? () => setState(() => _societyCurrentPage--)
                      : null,
                ),
                Text(
                  'Page ${_societyCurrentPage + 1} of ${totalPages == 0 ? 1 : totalPages}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: (_societyCurrentPage + 1 < totalPages)
                      ? () => setState(() => _societyCurrentPage++)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
