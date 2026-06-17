import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/networks/operational_api_service.dart'; // 🔄 Redirected to split Operational worker layer

class AssetRegistryPage extends StatefulWidget {
  const AssetRegistryPage({super.key});

  @override
  State<AssetRegistryPage> createState() => _AssetRegistryPageState();
}

class _AssetRegistryPageState extends State<AssetRegistryPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);
  static const Color lightBg = Color(0xFFF8F9FA);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedStatus = 'Operational';

  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";

  List<dynamic> _societyAssets = [];
  bool _pageLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLiveAssetsRegistry();
  }

  /// Fetches the dynamic hardware asset inventory straight from your database
  Future<void> _loadLiveAssetsRegistry() async {
    try {
      final data = await OperationalApiService.fetchSocietyAssets(
        _sessionToken,
      );
      if (mounted) {
        setState(() {
          _societyAssets = data;
          _pageLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _pageLoading = false);
    }
  }

  /// Cycles status parameters dynamically down to your operational service endpoints
  Future<void> _cycleAssetStatus(int index, dynamic assetId) async {
    const statuses = ['Operational', 'Maintenance', 'In Repair'];
    final currentIndex = statuses.indexOf(
      _societyAssets[index]['status'] ?? 'Operational',
    );
    final nextIndex = (currentIndex + 1) % statuses.length;
    final String targetStatus = statuses[nextIndex];

    // Optimistically update the UI state locally first for a snappy user experience
    setState(() {
      _societyAssets[index]['status'] = targetStatus;
    });

    bool success = await OperationalApiService.changeAssetStatus(
      _sessionToken,
      assetId,
      targetStatus,
    );
    if (!success) {
      _loadLiveAssetsRegistry(); // Rollback if server sync pipeline drops out
    }
  }

  /// Submits and registers a brand new validated asset node entry
  Future<void> _submitNewAssetEntry() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _pageLoading = true);

    bool success = await OperationalApiService.addSocietyAsset(_sessionToken, {
      'name': _nameController.text.trim(),
      'location': _locationController.text.trim(),
      'status': _selectedStatus,
    });

    if (success) {
      _nameController.clear();
      _locationController.clear();
      _loadLiveAssetsRegistry();
      _showSnack('Asset successfully logged into community registry.');
    } else {
      setState(() => _pageLoading = false);
      _showSnack('Failed to register hardware asset entry.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.lexend(fontSize: 12.5))),
    );
  }

  Color _getStatusThemeColor(String status) {
    switch (status) {
      case 'Operational':
        return Colors.green;
      case 'Maintenance':
        return Colors.orange;
      case 'In Repair':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        title: Text(
          'Society Asset Registry',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _pageLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadLiveAssetsRegistry,
              color: primaryBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Register New Hardware Asset',
                      style: GoogleFonts.lexend(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              style: GoogleFonts.inter(fontSize: 13.5),
                              decoration: InputDecoration(
                                labelText:
                                    'Asset Name / Equipment Specification',
                                labelStyle: GoogleFonts.inter(fontSize: 12.5),
                                prefixIcon: const Icon(
                                  Icons.construction_rounded,
                                  size: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Provide asset name parameter'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _locationController,
                              style: GoogleFonts.inter(fontSize: 13.5),
                              decoration: InputDecoration(
                                labelText: 'Installation Location Room / Wing',
                                labelStyle: GoogleFonts.inter(fontSize: 12.5),
                                prefixIcon: const Icon(
                                  Icons.pin_drop_outlined,
                                  size: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Installation target area needed'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedStatus,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                color: darkText,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Initial Functional Health Status',
                                labelStyle: GoogleFonts.inter(fontSize: 12.5),
                                prefixIcon: const Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              items: ['Operational', 'Maintenance', 'In Repair']
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedStatus = v!),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _submitNewAssetEntry,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.add_task_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: Text(
                                  'Save Asset Entry',
                                  style: GoogleFonts.lexend(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Active Asset Inventory (${_societyAssets.length})',
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        Text(
                          'Swipe left to purge',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.black38,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _societyAssets.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40.0),
                            child: Center(
                              child: Text(
                                'No hardware entries managed in inventory.',
                                style: GoogleFonts.inter(color: Colors.black38),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _societyAssets.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _societyAssets[index];
                              final String statusStr =
                                  item['status'] ?? 'Operational';
                              final statusColor = _getStatusThemeColor(
                                statusStr,
                              );
                              final dynamic assetId =
                                  item['id'] ?? item['asset_id'] ?? index;

                              return Dismissible(
                                key: Key(assetId.toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade700,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.delete_forever_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                onDismissed: (_) async {
                                  setState(
                                    () => _societyAssets.removeAt(index),
                                  );
                                  bool completed =
                                      await OperationalApiService.purgeAssetRecord(
                                        _sessionToken,
                                        assetId,
                                      );
                                  if (completed) {
                                    _showSnack(
                                      '${item['name'] ?? 'Asset'} permanently unlinked from registry.',
                                    );
                                  } else {
                                    _loadLiveAssetsRegistry(); // Restores state row if synchronization drops
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.withValues(
                                        alpha: 0.08,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['name'] ??
                                                  'Hardware Equipment',
                                              style: GoogleFonts.lexend(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.bold,
                                                color: darkText,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on_outlined,
                                                  size: 13,
                                                  color: Colors.black38,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'ID: $assetId • Loc: ${item['location'] ?? 'N/A'}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11.5,
                                                      color: Colors.black45,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () =>
                                            _cycleAssetStatus(index, assetId),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: statusColor.withValues(
                                                alpha: 0.2,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 3.5,
                                                backgroundColor: statusColor,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                statusStr,
                                                style: GoogleFonts.lexend(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      statusColor ==
                                                          Colors.green
                                                      ? Colors.green.shade900
                                                      : statusColor ==
                                                            Colors.orange
                                                      ? Colors.orange.shade900
                                                      : Colors.red.shade900,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.sync_rounded,
                                                size: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
