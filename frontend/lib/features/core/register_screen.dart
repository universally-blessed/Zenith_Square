import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/datasource/api_service.dart';
import './verify_otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _flatController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  List<Society> _societies = [];
  List<Block> _blocks = [];

  String? _selectedSocietyId;
  String? _selectedBlockId;

  bool _isLoadingSocieties = false;
  bool _isLoadingBlocks = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadSocieties();
  }

  Future<void> _loadSocieties() async {
    setState(() => _isLoadingSocieties = true);
    try {
      final list = await ApiService.fetchSocieties();
      setState(() => _societies = list);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoadingSocieties = false);
    }
  }

  Future<void> _loadBlocks(String societyId) async {
    setState(() {
      _isLoadingBlocks = true;
      _blocks = [];
      _selectedBlockId = null;
    });
    try {
      final list = await ApiService.fetchBlocks(societyId);
      setState(() => _blocks = list);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoadingBlocks = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // 1. Get the selected block name or block ID (e.g., 'A')
      final selectedBlock = _blocks.firstWhere(
        (b) => b.id == _selectedBlockId,
        orElse: () => Block(id: '', name: ''),
      );

      final rawFlatNumber = _flatController.text.trim();

      // 2. Format Flat Identifier:
      // If user typed '101' and selected block 'A', combine them into 'A-101'.
      // If user already typed 'A-101', use it as-is.
      final String formattedFlatId;
      if (selectedBlock.name.isNotEmpty && !rawFlatNumber.contains('-')) {
        formattedFlatId = '${selectedBlock.name.substring(6)}-$rawFlatNumber';
      } else {
        formattedFlatId = rawFlatNumber;
      }

      final payload = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'societyId': _selectedSocietyId,
        'flatId': formattedFlatId, // Sends "A-101"
      };

      // Debug print to verify the payload before sending
      debugPrint('Registration Payload: $payload');

      final response = await ApiService.registerResident(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Registration successful'),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VerifyOtpScreen(email: _emailController.text.trim()),
          ),
        );
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _flatController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    return Scaffold(
      appBar: AppBar(title: const Text('Resident Registration')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Full Name
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter your full name'
                      : null,
                ),
                const SizedBox(height: 16),

                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please enter phone number';
                    }
                    if (v.length != 10) {
                      return 'Phone number must be exactly 10 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email Address
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter email';
                    }
                    if (!emailRegex.hasMatch(v.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Society Dropdown
                _isLoadingSocieties
                    ? const Center(child: LinearProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: _selectedSocietyId,
                        decoration: const InputDecoration(
                          labelText: 'Select Society',
                          prefixIcon: Icon(Icons.location_city_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _societies
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null && val != _selectedSocietyId) {
                            setState(() => _selectedSocietyId = val);
                            _loadBlocks(val);
                          }
                        },
                        validator: (v) =>
                            v == null ? 'Please select a society' : null,
                      ),
                const SizedBox(height: 16),

                // Block Dropdown
                _isLoadingBlocks
                    ? const Center(child: LinearProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: _selectedBlockId,
                        decoration: const InputDecoration(
                          labelText: 'Select Block',
                          prefixIcon: Icon(Icons.domain_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _blocks
                            .map(
                              (b) => DropdownMenuItem(
                                value: b.id,
                                child: Text(b.name),
                              ),
                            )
                            .toList(),
                        onChanged: _selectedSocietyId == null
                            ? null
                            : (val) => setState(() => _selectedBlockId = val),
                        validator: (v) =>
                            v == null ? 'Please select a block' : null,
                      ),
                const SizedBox(height: 16),

                // Flat Number / ID
                TextFormField(
                  controller: _flatController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Flat Number',
                    hintText: '101',
                    prefixIcon: const Icon(Icons.home_outlined),
                    prefixText: (_selectedBlockId != null && _blocks.isNotEmpty)
                        ? '${_blocks.firstWhere(
                            (b) => b.id == _selectedBlockId,
                            orElse: () => Block(id: "", name: ""),
                          ).name}-'
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter flat number'
                      : null,
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
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
                    if (v == null || v.isEmpty) return 'Please enter password';
                    if (v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please confirm password';
                    }
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Register', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
