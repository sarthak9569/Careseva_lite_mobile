import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../services/queue_store.dart';
import 'compounder_dashboard_screen.dart';
import 'patient_home_screen.dart';

class AuthScreen extends StatefulWidget {
  final UserRole targetRole;

  const AuthScreen({super.key, required this.targetRole});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(text: 'Sarthak Verma');
  final _phoneController = TextEditingController(text: '+91 98765 00001');
  final _ageController = TextEditingController(text: '28');
  String _selectedGender = 'Male';

  bool _isOtpSent = false;
  final _otpController = TextEditingController(text: '123456');
  bool _isLoading = false;

  void _handleSendOtp() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isOtpSent = true);
  }

  void _handleVerifyAndLogin() async {
    if (_otpController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final queueStore = Provider.of<QueueStore>(context, listen: false);

    final profile = UserProfile(
      userId: 'USER-${const Uuid().v4().substring(0, 8)}',
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 25,
      gender: _selectedGender,
      role: widget.targetRole,
      createdAt: DateTime.now(),
    );

    await queueStore.setUserProfile(profile);

    setState(() => _isLoading = false);

    if (mounted) {
      if (widget.targetRole == UserRole.patient) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CompounderDashboardScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleName = widget.targetRole == UserRole.patient ? 'Patient Login' : 'Compounder Login';

    return Scaffold(
      appBar: AppBar(
        title: Text(roleName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isOtpSent ? 'Verify Phone Number' : 'Create Profile & Login',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                _isOtpSent
                    ? 'Enter the 6-digit OTP sent to ${_phoneController.text}'
                    : 'Provide your basic details to access CareSeva 2',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              if (!_isOtpSent) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Enter full name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (for OTP) *',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Enter phone number' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Age *',
                          prefixIcon: Icon(Icons.cake_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Enter age' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Male', 'Female', 'Other'].map((g) {
                          return DropdownMenuItem(value: g, child: Text(g));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedGender = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _handleSendOtp,
                  child: const Text('Send Phone OTP'),
                ),
              ] else ...[
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Enter OTP (Default: 123456)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerifyAndLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Verify & Enter App'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _isOtpSent = false),
                  child: const Text('Edit Phone / Details'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
