import 'package:flutter/material.dart';
import '../../data/datasource/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _moveInDateController = TextEditingController();

  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _pickMoveInDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _moveInDateController.text.isNotEmpty
          ? DateTime.tryParse(_moveInDateController.text) ?? DateTime.now()
          : DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _moveInDateController.text =
            "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.fetchUserProfile();
      setState(() {
        _profile = data;
        _nameController.text = data['user_name'] ?? '';
        _emailController.text = data['user_email'] ?? '';
        _moveInDateController.text = data['move_in_date'] ?? '';
      });
    } catch (e) {
      _showToast(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final res = await ApiService.updateUserProfile({
        'user_name': _nameController.text.trim(),
        'user_email': _emailController.text.trim(),
        'move_in_date': _moveInDateController.text.trim(),
      });
      _showToast(res['message'] ?? 'Profile updated!');
    } catch (e) {
      _showToast(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _moveInDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final roleName = (_profile?['role_name'] ?? '').toString();
    final isGuard =
        roleName.toLowerCase().contains('guard') ||
        roleName.toLowerCase().contains('security');

    return Scaffold(
      appBar: AppBar(
        title: Text(isGuard ? 'Security Guard Profile' : 'My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Badge Card
              Card(
                elevation: 0,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isGuard ? Icons.shield_outlined : Icons.verified_user,
                          color: Colors.blue.shade900,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'ID: ${_profile?['user_id'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isGuard
                                        ? Colors.green.shade100
                                        : Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isGuard
                                        ? 'Security Guard'
                                        : (_profile?['role_name'] ??
                                              'Resident'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isGuard
                                          ? Colors.green.shade900
                                          : Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isGuard
                                  ? '${_profile?['society_name'] ?? 'Serene Heights'} • Main Entrance Gate'
                                  : '${_profile?['society_name']} | ${_profile?['flat_number']}',
                              style: TextStyle(
                                color: Colors.blueGrey.shade800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Non-editable Phone
              TextFormField(
                initialValue: _profile?['user_phone'] ?? '',
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Fixed)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name required' : null,
              ),
              const SizedBox(height: 12),

              // Email Address
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email address is required';
                  }
                  if (v.contains(' ')) {
                    return 'Email address must not contain spaces';
                  }
                  final emailRegex = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  if (!emailRegex.hasMatch(v.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Role specific detail
              if (isGuard) ...[
                TextFormField(
                  initialValue: 'Main Entrance Gate (Live Duty)',
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Security Post',
                    prefixIcon: Icon(Icons.security_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                // Move-in Date Picker for Residents
                TextFormField(
                  controller: _moveInDateController,
                  readOnly: true,
                  onTap: _pickMoveInDate,
                  decoration: const InputDecoration(
                    labelText: 'Move-in Date',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    suffixIcon: Icon(Icons.edit_calendar_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              ElevatedButton(
                onPressed: _isSaving ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Profile Changes'),
              ),
              const SizedBox(height: 24),

              const Divider(),
              const SizedBox(height: 8),

              // Quick Actions
              if (!isGuard && _profile?['has_nominee'] == true) ...[
                ListTile(
                  leading: const Icon(Icons.badge_outlined, color: Colors.blue),
                  title: const Text('Nominee Management'),
                  subtitle: const Text('View and update nominee details'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => Navigator.pushNamed(context, '/nominee'),
                ),
              ],

              ListTile(
                leading: const Icon(Icons.lock_reset, color: Colors.orange),
                title: const Text('Change Password'),
                subtitle: const Text('Update your login password'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => Navigator.pushNamed(context, '/change-password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
