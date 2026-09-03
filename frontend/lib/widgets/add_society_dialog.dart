import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddSocietyDialog extends StatefulWidget {
  final VoidCallback onSocietyAdded;
  const AddSocietyDialog({super.key, required this.onSocietyAdded});

  @override
  State<AddSocietyDialog> createState() => _AddSocietyDialogState();
}

class _AddSocietyDialogState extends State<AddSocietyDialog> {
  final _formKey = GlobalKey<FormState>();

  // Society Details Controllers
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _maintenanceRateController = TextEditingController(text: '2500.00');
  final _lateFeeController = TextEditingController(text: '5.00');
  String _billingCycle = 'MONTHLY';

  // Feature Flag States
  bool _hasBlockSecretary = false;
  bool _hasNominee = true;
  bool _hasSecurity = true;
  bool _isLoading = false;

  // Blocks & Flats Structure
  // Format: [ { "block_name": "A", "flats": [ {"flat_number": "101", "floor_number": 1}, ... ] } ]
  final List<Map<String, dynamic>> _blocks = [];

  // Generator inputs for block & flats
  final _genBlockNameCtrl = TextEditingController();
  final _genFloorsCtrl = TextEditingController(text: '3');
  final _genFlatsPerFloorCtrl = TextEditingController(text: '2');

  void _generateBlockAndFlats() {
    final blockName = _genBlockNameCtrl.text.trim().toUpperCase();
    final floors = int.tryParse(_genFloorsCtrl.text.trim()) ?? 0;
    final flatsPerFloor = int.tryParse(_genFlatsPerFloorCtrl.text.trim()) ?? 0;

    if (blockName.isEmpty || floors <= 0 || flatsPerFloor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter valid Block Name, Floors, and Flats per floor.',
          ),
        ),
      );
      return;
    }

    // Generate flats list (e.g. 101, 102, 201, 202)
    final List<Map<String, dynamic>> generatedFlats = [];
    for (int floor = 1; floor <= floors; floor++) {
      for (int unit = 1; unit <= flatsPerFloor; unit++) {
        final flatNum = '$floor${unit.toString().padLeft(2, '0')}';
        generatedFlats.add({'flat_number': flatNum, 'floor_number': floor});
      }
    }

    setState(() {
      _blocks.add({'block_name': blockName, 'flats': generatedFlats});
      _genBlockNameCtrl.clear();
    });
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add at least one block with flats before submitting.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final payload = {
      'society_id': _idController.text.trim().toUpperCase(),
      'society_name': _nameController.text.trim(),
      'society_address': _addressController.text.trim(),
      'society_city': _cityController.text.trim(),
      'society_pincode': _pincodeController.text.trim(),
      'society_phone': _phoneController.text.trim(),
      'society_email': _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      'standard_rate':
          double.tryParse(_maintenanceRateController.text.trim()) ?? 0.0,
      'late_fee_percent':
          double.tryParse(_lateFeeController.text.trim()) ?? 0.0,
      'billing_cycle': _billingCycle,
      'society_status': 'active',
      'has_block_secretary': _hasBlockSecretary,
      'has_nominee': _hasNominee,
      'has_security': _hasSecurity,
      'blocks': _blocks,
    };

    try {
      final success = await ApiService.createSociety(payload);
      if (success && mounted) {
        Navigator.pop(context);
        widget.onSocietyAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Society, blocks, and flats created successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 880,
        height: 670,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Onboard New Society & Structure',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Main Two-Column Layout
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Basic Details & Features
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    controller: _idController,
                                    maxLength: 5,
                                    decoration: const InputDecoration(
                                      labelText: 'Society ID (max 5)',
                                      border: OutlineInputBorder(),
                                      counterText: '',
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Society Name',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Address',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _cityController,
                                    decoration: const InputDecoration(
                                      labelText: 'City',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _pincodeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Pincode',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Phone',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _maintenanceRateController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Rate (₹)',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lateFeeController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Late Fee %',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _billingCycle,
                                    decoration: const InputDecoration(
                                      labelText: 'Billing',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'MONTHLY',
                                        child: Text('Monthly'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'QUARTERLY',
                                        child: Text('Quarterly'),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _billingCycle = v!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Feature Toggles
                            const Text(
                              'Feature Flags',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  CheckboxListTile(
                                    dense: true,
                                    title: const Text(
                                      'Block Secretary Hierarchy',
                                    ),
                                    value: _hasBlockSecretary,
                                    onChanged: (v) => setState(
                                      () => _hasBlockSecretary = v ?? false,
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  CheckboxListTile(
                                    dense: true,
                                    title: const Text('Nominee Management'),
                                    value: _hasNominee,
                                    onChanged: (v) =>
                                        setState(() => _hasNominee = v ?? true),
                                  ),
                                  const Divider(height: 1),
                                  CheckboxListTile(
                                    dense: true,
                                    title: const Text('Security & Gatekeeper'),
                                    value: _hasSecurity,
                                    onChanged: (v) => setState(
                                      () => _hasSecurity = v ?? true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const VerticalDivider(width: 1),

                    // Right Column: Blocks & Flats Generator
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Blocks & Flats Configuration',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Generator Input Box
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                          controller: _genBlockNameCtrl,
                                          decoration: const InputDecoration(
                                            labelText: 'Block Name (e.g. A)',
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _genFloorsCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Floors',
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _genFlatsPerFloorCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Flats/Flr',
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF2563EB,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      onPressed: _generateBlockAndFlats,
                                      icon: const Icon(
                                        Icons.add,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      label: const Text(
                                        'Add Block',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Configured Blocks List
                            Expanded(
                              child: _blocks.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No blocks added yet.\nUse the generator above to add building blocks.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _blocks.length,
                                      itemBuilder: (context, idx) {
                                        final b = _blocks[idx];
                                        final flats = b['flats'] as List;
                                        return Card(
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: ListTile(
                                            dense: true,
                                            title: Text(
                                              'Block ${b['block_name']} (${flats.length} Flats)',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Text(
                                              'Flats: ${flats.map((f) => f['flat_number']).take(6).join(', ')}${flats.length > 6 ? '...' : ''}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.redAccent,
                                                size: 18,
                                              ),
                                              onPressed: () => setState(
                                                () => _blocks.removeAt(idx),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Register Society & Structure',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
