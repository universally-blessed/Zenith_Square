import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class EditSocietyDialog extends StatefulWidget {
  final Map<String, dynamic> society;
  final VoidCallback onSocietyUpdated;

  const EditSocietyDialog({
    super.key,
    required this.society,
    required this.onSocietyUpdated,
  });

  @override
  State<EditSocietyDialog> createState() => _EditSocietyDialogState();
}

class _EditSocietyDialogState extends State<EditSocietyDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _maintenanceRateController;
  late TextEditingController _lateFeeController;
  late String _billingCycle;
  late String _societyStatus;
  bool _isLoading = false;
  String? _dialogError;

  @override
  void initState() {
    super.initState();
    final s = widget.society;
    _nameController = TextEditingController(text: s['society_name'] ?? '');
    _addressController = TextEditingController(
      text: s['society_address'] ?? '',
    );
    _cityController = TextEditingController(text: s['society_city'] ?? '');
    _pincodeController = TextEditingController(
      text: s['society_pincode'] ?? '',
    );
    _phoneController = TextEditingController(text: s['society_phone'] ?? '');
    _emailController = TextEditingController(text: s['society_email'] ?? '');
    _maintenanceRateController = TextEditingController(
      text: (s['standard_rate'] ?? 2500.0).toString(),
    );
    _lateFeeController = TextEditingController(
      text: (s['late_fee_percent'] ?? 5.0).toString(),
    );
    _billingCycle = (s['billing_cycle'] ?? 'MONTHLY').toString().toUpperCase();
    _societyStatus = s['society_status'] ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _maintenanceRateController.dispose();
    _lateFeeController.dispose();
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

  void _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _dialogError = null;
    });

    final payload = {
      'society_id': widget.society['society_id'],
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
      'society_status': _societyStatus,
    };

    try {
      final success = await ApiService.updateSociety(
        widget.society['society_id'],
        payload,
      );
      if (success && mounted) {
        Navigator.pop(context);
        widget.onSocietyUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nameController.text} updated successfully!'),
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
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Society (${widget.society['society_id']})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              _buildFieldLabel('Society Name', isRequired: true),
              const SizedBox(height: 4),
              TextFormField(
                controller: _nameController,
                maxLength: 100,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  counterText: '',
                  isDense: true,
                ),
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return 'Society name is required';
                  if (val.length < 3)
                    return 'Name must be at least 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _buildFieldLabel('Address', isRequired: true),
              const SizedBox(height: 4),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Address is required'
                    : null,
              ),
              const SizedBox(height: 12),

              // Row 1: City & Pincode
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('City', isRequired: true),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _cityController,
                          maxLength: 50,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r"[a-zA-Z\s]"),
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
                            if (val.isEmpty) return 'City is required';
                            if (val.length < 2) return 'Min 2 characters';
                            if (RegExp(r'[0-9]').hasMatch(val)) {
                              return 'No numbers allowed';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Pincode', isRequired: true),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _pincodeController,
                          maxLength: 6,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            hintText: '380001',
                            border: OutlineInputBorder(),
                            counterText: '',
                            isDense: true,
                          ),
                          validator: (v) {
                            final val = v?.trim() ?? '';
                            if (val.isEmpty) return 'Pincode required';
                            if (!pincodeRegex.hasMatch(val))
                              return 'Invalid 6-digit PIN';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 2: Phone & Email
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Phone', isRequired: true),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _phoneController,
                          maxLength: 10,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            hintText: '10 digits',
                            border: OutlineInputBorder(),
                            counterText: '',
                            isDense: true,
                          ),
                          validator: (v) {
                            final val = v?.trim() ?? '';
                            if (val.isEmpty) return 'Phone required';
                            if (!phoneRegex.hasMatch(val))
                              return 'Must start 6-9';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Email Address (Optional)'),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'society@example.com',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator: (v) {
                            final val = v?.trim() ?? '';
                            if (val.isNotEmpty && !emailRegex.hasMatch(val)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Billing & Maintenance Settings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Rate (₹)', isRequired: true),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _maintenanceRateController,
                          keyboardType: const TextInputType.numberWithOptions(
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
                            if (val.isEmpty) return 'Rate required';
                            final parsed = double.tryParse(val);
                            if (parsed == null || parsed < 0)
                              return 'Invalid rate';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Late Fee %'),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _lateFeeController,
                          keyboardType: const TextInputType.numberWithOptions(
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Billing Cycle', isRequired: true),
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
                              setState(() => _billingCycle = v ?? 'MONTHLY'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (_dialogError != null) ...[
                const SizedBox(height: 12),
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

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitUpdate,
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
                            'Save Updates',
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
