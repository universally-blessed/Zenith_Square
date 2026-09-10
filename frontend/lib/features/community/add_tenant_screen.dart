import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/datasource/community_api_service.dart';

class AddTenantScreen extends StatefulWidget {
  const AddTenantScreen({Key? key}) : super(key: key);

  @override
  State<AddTenantScreen> createState() => _AddTenantScreenState();
}

class _AddTenantScreenState extends State<AddTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _maintenanceController = TextEditingController();

  List<dynamic> _flats = [];
  String? _selectedFlatId;
  DateTime _moveInDate = DateTime.now();
  bool _isLoading = false;
  bool _loadingFlats = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFlats();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _maintenanceController.dispose();
    super.dispose();
  }

  Future<void> _loadFlats() async {
    try {
      final flats = await CommunityApiService.fetchFlatsDropdown();
      if (mounted) {
        setState(() {
          _flats = flats;
          _loadingFlats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingFlats = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load flats: $e')));
      }
    }
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 13,
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
                    fontSize: 14,
                  ),
                ),
              ]
            : const [],
      ),
    );
  }

  Future<void> _submitTenant() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFlatId == null) {
      setState(() => _errorMessage = 'Please select a flat');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dateStr =
          "${_moveInDate.year}-${_moveInDate.month.toString().padLeft(2, '0')}-${_moveInDate.day.toString().padLeft(2, '0')}";

      await CommunityApiService.addTenant(
        tenantName: _nameController.text.trim(),
        tenantPhone: _phoneController.text.trim(),
        tenantEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        flatId: _selectedFlatId!,
        customMaintenance: _maintenanceController.text.isNotEmpty
            ? double.tryParse(_maintenanceController.text.trim())
            : null,
        moveInDate: dateStr,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tenant added successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Tenant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loadingFlats
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Tenant Full Name', isRequired: true),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter full name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final val = v?.trim() ?? '';
                        if (val.isEmpty) return 'Tenant name is required';
                        if (val.length < 2) return 'Enter a valid name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Phone Number', isRequired: true),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        hintText: '10-digit mobile number',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      validator: (v) {
                        final val = v?.trim() ?? '';
                        if (val.isEmpty) return 'Contact number is required';
                        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(val)) {
                          return 'Enter valid 10-digit mobile (starts with 6-9)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Email Address (Optional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'tenant@example.com',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final val = v?.trim() ?? '';
                        if (val.isNotEmpty &&
                            !RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(val)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Select Flat', isRequired: true),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value:
                          _selectedFlatId, // Changed from initialValue to value
                      isExpanded: true,
                      items: _flats.map<DropdownMenuItem<String>>((f) {
                        return DropdownMenuItem<String>(
                          value: f['flat_id'].toString(),
                          child: Text(
                            f['display_label'] ?? f['flat_number'].toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedFlatId = val;
                          if (_errorMessage == 'Please select a flat') {
                            _errorMessage = null;
                          }
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null ? 'Please select a flat' : null,
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Custom Maintenance Fee (Optional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _maintenanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'Standard society rate applies if empty',
                        border: OutlineInputBorder(),
                        prefixText: '₹ ',
                      ),
                      validator: (v) {
                        final val = v?.trim() ?? '';
                        if (val.isNotEmpty) {
                          final parsed = double.tryParse(val);
                          if (parsed == null || parsed < 0) {
                            return 'Enter a valid positive amount';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Move-In Date', isRequired: true),
                    const SizedBox(height: 6),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      title: Text(
                        "${_moveInDate.day}/${_moveInDate.month}/${_moveInDate.year}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: const Icon(Icons.calendar_today, size: 20),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _moveInDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => _moveInDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // INLINE ERROR BANNER
                    if (_errorMessage != null) ...[
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
                              size: 18,
                              color: Colors.red.shade800,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitTenant,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Register Tenant',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
