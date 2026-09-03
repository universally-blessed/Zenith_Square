import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SocietyOccupancyDialog extends StatefulWidget {
  final Map<String, dynamic> society;
  const SocietyOccupancyDialog({super.key, required this.society});

  @override
  State<SocietyOccupancyDialog> createState() => _SocietyOccupancyDialogState();
}

class _SocietyOccupancyDialogState extends State<SocietyOccupancyDialog> {
  List<dynamic> _records = [];
  bool _loading = true;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOccupancy();
  }

  void _loadOccupancy() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getOccupancies(
        societyId: widget.society['society_id'],
      );
      setState(() {
        _records = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _records.where((item) {
      final flat = (item['flat_number'] ?? '').toString().toLowerCase();
      final block = (item['block_name'] ?? '').toString().toLowerCase();
      final name = (item['resident_name'] ?? '').toString().toLowerCase();
      final type = (item['occupancy_type'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return flat.contains(q) ||
          block.contains(q) ||
          name.contains(q) ||
          type.contains(q);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 820,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Occupancy & Resident Directory',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.society['society_name'] ??
                          widget.society['society_id'],
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // Search Bar & Summary
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by flat number, block, resident...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    '${_records.length} Total Registered Units',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No occupancy entries registered for this society.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          headingRowColor: WidgetStatePropertyAll(
                            Colors.grey.shade100,
                          ),
                          columns: const [
                            DataColumn(label: Text('Flat')),
                            DataColumn(label: Text('Block')),
                            DataColumn(label: Text('Resident Name')),
                            DataColumn(label: Text('Occupancy Type')),
                            DataColumn(label: Text('Primary')),
                          ],
                          rows: filtered.map<DataRow>((item) {
                            final isOwner =
                                (item['occupancy_type'] ?? '')
                                    .toString()
                                    .toLowerCase() ==
                                'owner';
                            final bool isPrimary = item['is_primary'] ?? false;

                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    item['flat_number'] ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(Text(item['block_name'] ?? '-')),
                                DataCell(Text(item['resident_name'] ?? '-')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isOwner
                                          ? Colors.blue.withValues(alpha: 0.1)
                                          : Colors.teal.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item['occupancy_type'] ?? '-',
                                      style: TextStyle(
                                        color: isOwner
                                            ? Colors.blue.shade800
                                            : Colors.teal.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Icon(
                                    isPrimary
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: isPrimary
                                        ? Colors.green
                                        : Colors.grey.shade400,
                                    size: 16,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close Directory'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
