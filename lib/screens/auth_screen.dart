import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/clinic.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../services/queue_store.dart';
import 'clinic_view_screen.dart';
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
  final _clinicRefController = TextEditingController(text: 'REF-78291');
  final _ageController = TextEditingController(text: '28');
  String _selectedGender = 'Male';

  bool _isOtpSent = false;
  final _otpController = TextEditingController(text: '123456');
  bool _isLoading = false;

  void _handleSendOtp() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isOtpSent = true;
    });
  }

  void _handleVerifyAndLogin() async {
    if (_otpController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

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

    if (widget.targetRole == UserRole.patient) {
      final refNum = _clinicRefController.text.trim();
      Clinic? clinic = queueStore.findClinicById(refNum);

      if (clinic == null && refNum.isNotEmpty) {
        final res = await ApiService.getClinicByIdentifier(refNum);
        if (res != null && res['clinic'] != null) {
          clinic = Clinic.fromJson(res['clinic']);
        }
      }

      setState(() => _isLoading = false);

      if (mounted) {
        if (clinic != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ClinicViewScreen(clinic: clinic!)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
          );
        }
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CompounderDashboardScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleName = widget.targetRole == UserRole.patient ? 'Patient Portal' : 'Compounder Verification';

    return Scaffold(
      appBar: AppBar(
        title: Text(roleName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isOtpSent ? 'Verify Phone OTP' : 'Enter Details & Clinic Reference',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                _isOtpSent
                    ? 'Enter 6-digit OTP sent to ${_phoneController.text}'
                    : 'Provide your name, phone, and Clinic Reference Number to enter clinic dashboard',
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

                if (widget.targetRole == UserRole.patient) ...[
                  TextFormField(
                    controller: _clinicRefController,
                    decoration: const InputDecoration(
                      labelText: 'Clinic Reference Number * (e.g. REF-78291)',
                      hintText: 'Enter clinic ref number or ID',
                      prefixIcon: Icon(Icons.qr_code_rounded),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Enter Clinic Reference Number' : null,
                  ),
                  const SizedBox(height: 16),
                ],

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
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                    onPressed: _handleSendOtp,
                    icon: const Icon(Icons.sms_outlined),
                    label: const Text('SEND PHONE OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ] else ...[
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Enter OTP (Default: 123456)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                    onPressed: _isLoading ? null : _handleVerifyAndLogin,
                    icon: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.arrow_forward_rounded),
                    label: const Text('VERIFY & ENTER CLINIC DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _isOtpSent = false),
                  child: const Text('Edit Details / Clinic Ref Number'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
