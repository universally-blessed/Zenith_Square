import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? _dialogError;

  // Blocks & Flats Structure
  final List<Map<String, dynamic>> _blocks = [];

  // Generator inputs for block & flats
  final _genBlockNameCtrl = TextEditingController();
  final _genFloorsCtrl = TextEditingController(text: '3');
  final _genFlatsPerFloorCtrl = TextEditingController(text: '2');

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _maintenanceRateController.dispose();
    _lateFeeController.dispose();
    _genBlockNameCtrl.dispose();
    _genFloorsCtrl.dispose();
    _genFlatsPerFloorCtrl.dispose();
    super.dispose();
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        children: isRequired
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ]
            : const [],
      ),
    );
  }

  void _generateBlockAndFlats() {
    final blockName = _genBlockNameCtrl.text.trim().toUpperCase();
    final floors = int.tryParse(_genFloorsCtrl.text.trim()) ?? 0;
    final flatsPerFloor = int.tryParse(_genFlatsPerFloorCtrl.text.trim()) ?? 0;

    if (blockName.isEmpty || floors <= 0 || flatsPerFloor <= 0) {
      setState(() {
        _dialogError =
            'Please enter valid Block Name, Floors (>0), and Flats per floor (>0).';
      });
      return;
    }

    if (_blocks.any((b) => b['block_name'] == blockName)) {
      setState(() {
        _dialogError = 'Block "$blockName" already exists in the list.';
      });
      return;
    }

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
      _dialogError = null;
    });
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_blocks.isEmpty) {
      setState(() {
        _dialogError =
            'Please add at least one block with flats before submitting.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _dialogError = null;
    });

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
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dialogError = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    final pincodeRegex = RegExp(r'^[1-9][0-9]{5}$');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 880,
        height: 680,
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
                            // 1. Society ID & Name
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel(
                                        'Society ID',
                                        isRequired: true,
                                      ),
                                      const SizedBox(height: 4),
                                      TextFormField(
                                        controller: _idController,
                                        maxLength: 5,
                                        decoration: const InputDecoration(
                                          hintText: 'S0001',
                                          border: OutlineInputBorder(),
                                          counterText: '',
                                          isDense: true,
                                        ),
                                        validator: (v) {
                                          final val = v?.trim() ?? '';
                                          if (val.isEmpty) return 'Required';
                                          if (val.length < 2) return 'Min 2';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel(
                                        'Society Name',
                                        isRequired: true,
                                      ),
                                      const SizedBox(height: 4),
                                      TextFormField(
                                        controller: _nameController,
                                        maxLength: 100,
                                        decoration: const InputDecoration(
                                          hintText: 'Zenith Square',
                                          border: OutlineInputBorder(),
                                          counterText: '',
                                          isDense: true,
                                        ),
                                        validator: (v) {
                                          final val = v?.trim() ?? '';
                                          if (val.isEmpty) return 'Required';
                                          if (val.length < 3)
                                            return 'Min 3 chars';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 2. Full Address
                            _buildFieldLabel('Full Address', isRequired: true),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _addressController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText: 'Street, Landmark, Area...',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Address is required'
                                  : null,
                            ),
                            const SizedBox(height: 12),

                            // 3. City & Pincode (Own row for clear visibility)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel(
                                        'City',
                                        isRequired: true,
                                      ),
                                      const SizedBox(height: 4),
                                      TextFormField(
                                        controller: _cityController,
                                        maxLength: 50,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'[a-zA-Z\s]'),
                                          ),
                                        ],
                                        decoration: const InputDecoration(
                                          hintText: 'Ahmedabad',
                                          border: OutlineInputBorder(),
                                          counterText: '',
                                          isDense: true,
                                        ),
                                        validator: (v) {
                                          final val = v?.trim() ?? '';
                                          if (val.isEmpty)
                                            return 'City is required';
                                          if (val.length < 2)
                                            return 'Min 2 characters';
                                          if (!RegExp(
                                            r'^[a-zA-Z\s]+$',
                                          ).hasMatch(val)) {
                                            return 'Only letters and spaces allowed (no numbers or symbols)';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel(
                                        'Pincode',
                                        isRequired: true,
                                      ),
                                      const SizedBox(height: 4),
                                      TextFormField(
                                        controller: _pincodeController,
                                        maxLength: 6,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        decoration: const InputDecoration(
                                          hintText: '380001',
                                          border: OutlineInputBorder(),
                                          counterText: '',
                                          isDense: true,
                                        ),
                                        validator: (v) {
                                          final val = v?.trim() ?? '';
                                          if (val.isEmpty)
                                            return 'Pincode required';
                                          if (!pincodeRegex.hasMatch(val))
                                            return '6 digits';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 4. Phone & Email
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel(
                                        'Phone',
                                        isRequired: true,
                                      ),
                                      const SizedBox(height: 4),
                                      TextFormField(
                                        controller: _phoneController,
                                        maxLength: 10,
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        decoration: const InputDecoration(
                                          hintText: '10-digit phone',
                                          border: OutlineInputBorder(),
                                          counterText: '',
                                          isDense: true,
                                        ),
                                        validator: (v) {
                                          final val = v?.trim() ?? '';
                                          if (val.isEmpty)
                                            return 'Phone required';
                                          if (!phoneRegex.hasMatch(val))
                                            return 'Starts 6-9';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel('Email (Optional)'),
                                      const SizedBox(height: 4),
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: const InputDecoration(
                                          hintText: 'society@example.com',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        validator: (v) {
                                          final val = v?.trim() ?? '';
                                          if (val.isNotEmpty &&
                                              !emailRegex.hasMatch(val)) {
                                            return 'Invalid email';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 5. Rate, Late Fee & Billing Cycle
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel(
                                        'Rate (₹)',
                                        isRequired: true,
                                      ),
                                      const SizedBox(height: 4),
                                      TextFormField(
                                        controller: _maintenanceRateController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d+\.?\d{0,2}'),
                                          ),
                                        ],
                                        decoration: const InputDecoration(
                                          prefixText: '₹ ',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        validator: (v) {
                                          final val = v?.trim() ?? '';
                                          if (val.isEmpty) return 'Required';
                                          final parsed = double.tryParse(val);
                                          if (parsed == null || parsed < 0)
                                            return 'Invalid';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel('Late Fee %'),
                                      const SizedBox(height: 4),
                                      TextFormField(
                                        controller: _lateFeeController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d+\.?\d{0,2}'),
                                          ),
                                        ],
                                        decoration: const InputDecoration(
                                          suffixText: '%',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        validator: (v) {
                                          final val = v?.trim() ?? '';
                                          if (val.isNotEmpty) {
                                            final parsed = double.tryParse(val);
                                            if (parsed == null ||
                                                parsed < 0 ||
                                                parsed > 100) {
                                              return '0-100%';
                                            }
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel(
                                        'Billing',
                                        isRequired: true,
                                      ),
                                      const SizedBox(height: 4),
                                      DropdownButtonFormField<String>(
                                        value: _billingCycle,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          isDense: true,
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
                                          DropdownMenuItem(
                                            value: 'YEARLY',
                                            child: Text('Yearly'),
                                          ),
                                        ],
                                        onChanged: (v) =>
                                            setState(() => _billingCycle = v!),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Feature Toggles
                            const Text(
                              'Modular Feature Flags',
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

                            // Generator Box
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
                                          maxLength: 5,
                                          decoration: const InputDecoration(
                                            labelText: 'Block Name (e.g. A)',
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                            counterText: '',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _genFloorsCtrl,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
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
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
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
                                        'No blocks added yet.\nUse the generator above to configure blocks.',
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

              if (_dialogError != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red.shade800,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _dialogError!,
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: 16),

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
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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
