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

  String _selectedOccupancyType = 'Owner';
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
      final rawFlatNumber = _flatController.text.trim();
      final cleanFlatNumber = rawFlatNumber.contains('-')
          ? rawFlatNumber.split('-').last.trim()
          : rawFlatNumber;

      final payload = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'societyId': _selectedSocietyId,
        'blockId': _selectedBlockId,
        'flatNumber': cleanFlatNumber,
        'flatId': cleanFlatNumber,
        'occupancyType': _selectedOccupancyType,
      };
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
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');

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
                _buildFieldLabel('Full Name', isRequired: true),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  maxLength: 100,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Enter full name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Please enter your full name';
                    if (val.length < 2) {
                      return 'Name must be at least 2 characters';
                    }
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
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    hintText: '10-digit mobile number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Please enter phone number';
                    if (!phoneRegex.hasMatch(val)) {
                      return 'Enter valid 10-digit mobile (starts with 6-9)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _buildFieldLabel('Email Address', isRequired: true),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'yourname@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Please enter email';
                    if (!emailRegex.hasMatch(val)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _buildFieldLabel('Select Society', isRequired: true),
                const SizedBox(height: 6),
                _isLoadingSocieties
                    ? const Center(child: LinearProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: _selectedSocietyId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.location_city_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _societies
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  s.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                const SizedBox(height: 14),

                _buildFieldLabel('Select Block', isRequired: true),
                const SizedBox(height: 6),
                _isLoadingBlocks
                    ? const Center(child: LinearProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: _selectedBlockId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.domain_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _blocks
                            .map(
                              (b) => DropdownMenuItem(
                                value: b.id,
                                child: Text(
                                  b.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _selectedSocietyId == null
                            ? null
                            : (val) => setState(() => _selectedBlockId = val),
                        validator: (v) =>
                            v == null ? 'Please select a block' : null,
                      ),
                const SizedBox(height: 14),

                _buildFieldLabel('Flat Number', isRequired: true),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _flatController,
                  textInputAction: TextInputAction.next,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 101, 204',
                    prefixIcon: Icon(Icons.home_outlined),
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter flat number'
                      : null,
                ),
                const SizedBox(height: 14),

                _buildFieldLabel('Occupancy Type', isRequired: true),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedOccupancyType,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_pin_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Owner', child: Text('Owner')),
                    DropdownMenuItem(value: 'Tenant', child: Text('Tenant')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedOccupancyType = val);
                    }
                  },
                ),
                const SizedBox(height: 14),

                _buildFieldLabel('Password', isRequired: true),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'At least 6 characters',
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
                const SizedBox(height: 14),

                _buildFieldLabel('Confirm Password', isRequired: true),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Re-enter password',
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
                      : const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      ),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
