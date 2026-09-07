import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadFlats();
  }

  Future<void> _loadFlats() async {
    try {
      final flats = await CommunityApiService.fetchFlatsDropdown();
      setState(() {
        _flats = flats;
        _loadingFlats = false;
      });
    } catch (e) {
      setState(() => _loadingFlats = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load flats: $e')));
    }
  }

  Future<void> _submitTenant() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFlatId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a flat')));
      return;
    }

    setState(() => _isLoading = true);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Tenant')),
      body: _loadingFlats
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tenant Full Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: 'Phone (10 digits)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.length != 10
                          ? 'Enter valid 10-digit number'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedFlatId,
                      items: _flats.map<DropdownMenuItem<String>>((f) {
                        return DropdownMenuItem<String>(
                          value: f['flat_id'].toString(),
                          child: Text(f['display_label'] ?? f['flat_number']),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedFlatId = val),
                      decoration: const InputDecoration(
                        labelText: 'Select Flat',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null ? 'Please select a flat' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _maintenanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Custom Maintenance Fee (Optional)',
                        border: OutlineInputBorder(),
                        prefixText: '₹ ',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      title: Text(
                        "Move-In Date: ${_moveInDate.day}/${_moveInDate.month}/${_moveInDate.year}",
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _moveInDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null)
                          setState(() => _moveInDate = picked);
                      },
                    ),
                    const SizedBox(height: 24),
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
                                'Add Tenant',
                                style: TextStyle(fontSize: 16),
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
