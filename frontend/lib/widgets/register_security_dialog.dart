import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class RegisterSecurityDialog extends StatefulWidget {
  final List<dynamic> societies;
  final VoidCallback onSecurityRegistered;

  const RegisterSecurityDialog({
    super.key,
    required this.societies,
    required this.onSecurityRegistered,
  });

  @override
  State<RegisterSecurityDialog> createState() => _RegisterSecurityDialogState();
}

class _RegisterSecurityDialogState extends State<RegisterSecurityDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedSocietyId;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _dialogError;

  @override
  void initState() {
    super.initState();
    if (widget.societies.isNotEmpty) {
      _selectedSocietyId = widget.societies.first['society_id'].toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  void _submitSecurityForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSocietyId == null) {
      setState(() => _dialogError = 'Please select a target society.');
      return;
    }

    setState(() {
      _isLoading = true;
      _dialogError = null;
    });

    final payload = {
      'society_id': _selectedSocietyId,
      'user_name': _nameController.text.trim(),
      'user_phone': _phoneController.text.trim(),
      'user_email': _emailController.text.trim(),
      'password': _passwordController.text.trim(),
    };

    try {
      final success = await ApiService.registerSecurity(payload);
      if (success && mounted) {
        Navigator.pop(context);
        widget.onSecurityRegistered();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Security guard registered successfully!'),
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
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Register Security Personnel',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),

              if (_dialogError != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
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
                const SizedBox(height: 12),
              ],

              _buildFieldLabel('Assigned Society', isRequired: true),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _selectedSocietyId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: widget.societies.map<DropdownMenuItem<String>>((s) {
                  return DropdownMenuItem(
                    value: s['society_id'].toString(),
                    child: Text(s['society_name'] ?? s['society_id']),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedSocietyId = v),
              ),
              const SizedBox(height: 12),

              _buildFieldLabel('Full Name', isRequired: true),
              const SizedBox(height: 4),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Guard Name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return 'Name is required';
                  if (val.length < 2) return 'Min 2 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _buildFieldLabel('Mobile Phone (10 digits)', isRequired: true),
              const SizedBox(height: 4),
              TextFormField(
                controller: _phoneController,
                maxLength: 10,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: '9876543210',
                  border: OutlineInputBorder(),
                  counterText: '',
                  isDense: true,
                ),
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return 'Phone number is required';
                  if (val.length != 10) return 'Must be exactly 10 digits';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _buildFieldLabel(
                'Email (Required for OTP Recovery)',
                isRequired: true,
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'security@society.com',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) {
                  final val = v ?? '';
                  if (val.contains(' ')) return 'Email cannot contain spaces';
                  final trimmed = val.trim();
                  if (trimmed.isEmpty) return 'Email is required';
                  if (!emailRegex.hasMatch(trimmed)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _buildFieldLabel('Initial Password', isRequired: true),
              const SizedBox(height: 4),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Min 6 characters',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return 'Password is required';
                  if (val.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
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
                    onPressed: _isLoading ? null : _submitSecurityForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Register Security',
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
