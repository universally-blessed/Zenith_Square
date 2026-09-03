import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SocietyFeaturesDialog extends StatefulWidget {
  final Map<String, dynamic> society;
  const SocietyFeaturesDialog({super.key, required this.society});

  @override
  State<SocietyFeaturesDialog> createState() => _SocietyFeaturesDialogState();
}

class _SocietyFeaturesDialogState extends State<SocietyFeaturesDialog> {
  bool _loading = true;
  bool _saving = false;
  String? _configId;
  bool _hasBlockSecretary = false;
  bool _hasNominee = true;
  bool _hasSecurity = true;

  @override
  void initState() {
    super.initState();
    _loadFeatures();
  }

  void _loadFeatures() async {
    final societyId = widget.society['society_id'];
    try {
      final features = await ApiService.getSocietyFeatures(societyId);
      if (features != null) {
        setState(() {
          _configId = features['config_id'];
          _hasBlockSecretary = features['has_block_secretary'] ?? false;
          _hasNominee = features['has_nominee'] ?? true;
          _hasSecurity = features['has_security'] ?? true;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _saveFeatures() async {
    setState(() => _saving = true);
    final societyId = widget.society['society_id'];

    // Auto-generate CFG ID if new (config_id max length is 5)
    final configId =
        _configId ??
        'C${societyId.toString().replaceAll('SOC', '')}'.padRight(5, '0');

    final payload = {
      'config_id': configId,
      'society': societyId,
      'has_block_secretary': _hasBlockSecretary,
      'has_nominee': _hasNominee,
      'has_security': _hasSecurity,
    };

    try {
      final success = await ApiService.saveSocietyFeatures(
        payload,
        configId: _configId,
      );
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Features updated for ${widget.society['society_name']}!',
            ),
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Features: ${widget.society['society_name']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Toggle modular platform features available to this society:',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Block Secretary Hierarchy'),
                    subtitle: const Text(
                      'Enable sub-level secretary management per building block',
                    ),
                    value: _hasBlockSecretary,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: (val) =>
                        setState(() => _hasBlockSecretary = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Nominee Management'),
                    subtitle: const Text(
                      'Allow residents to register emergency nominees and family heirs',
                    ),
                    value: _hasNominee,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: (val) => setState(() => _hasNominee = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Security & Gatekeeper Module'),
                    subtitle: const Text(
                      'Enable visitor logs, gate passes, and emergency security alerts',
                    ),
                    value: _hasSecurity,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: (val) => setState(() => _hasSecurity = val),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _saving ? null : _saveFeatures,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
