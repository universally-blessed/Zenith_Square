import 'package:flutter/material.dart';
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
    _billingCycle = s['billing_cycle'] ?? 'MONTHLY';
    _societyStatus = s['society_status'] ?? 'active';
  }

  void _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

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
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Society Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
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
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _pincodeController,
                      decoration: const InputDecoration(
                        labelText: 'Pincode',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Billing & Maintenance Settings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _maintenanceRateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Maintenance Rate (₹)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lateFeeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Late Fee (%)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _billingCycle,
                      decoration: const InputDecoration(
                        labelText: 'Billing Cycle',
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
                        DropdownMenuItem(
                          value: 'YEARLY',
                          child: Text('Yearly'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _billingCycle = v ?? 'MONTHLY'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
