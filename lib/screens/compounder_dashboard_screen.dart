import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/clinic.dart';
import '../models/doctor.dart';
import '../services/api_service.dart';
import '../services/queue_store.dart';
import 'compounder_queue_screen.dart';
import 'role_selection_screen.dart';

class CompounderDashboardScreen extends StatefulWidget {
  const CompounderDashboardScreen({super.key});

  @override
  State<CompounderDashboardScreen> createState() => _CompounderDashboardScreenState();
}

class _CompounderDashboardScreenState extends State<CompounderDashboardScreen> {
  final TextEditingController _clinicIdController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isOtpSent = false;
  bool _isVerified = false;
  bool _isLoading = false;
  String? _maskedPhone;
  String? _errorMessage;

  Clinic? _activeClinic;
  Doctor? _activeDoctor;
  bool _isBookingActive = false;
  bool _isOpdActive = false;

  @override
  void dispose() {
    _clinicIdController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _handleSendOtp() async {
    final clinicIdInput = _clinicIdController.text.trim();
    if (clinicIdInput.isEmpty) {
      setState(() => _errorMessage = 'Please enter Clinic ID or Reference Number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final queueStore = Provider.of<QueueStore>(context, listen: false);
    Clinic? clinic = queueStore.findClinicById(clinicIdInput);

    if (clinic == null) {
      final res = await ApiService.getClinicByIdentifier(clinicIdInput);
      if (res != null && res['clinic'] != null) {
        clinic = Clinic.fromJson(res['clinic']);
      }
    }

    if (clinic == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Clinic with ID "$clinicIdInput" not found';
      });
      return;
    }

    final doctors = queueStore.getDoctorsForClinic(clinic.clinicId);
    final Doctor doctor = doctors.isNotEmpty
        ? doctors.first
        : Doctor(
            doctorId: 'DOC-101',
            clinicId: clinic.clinicId,
            name: 'Dr. Rajesh Sharma',
            phone: clinic.phone,
            speciality: clinic.speciality,
            qualification: 'MBBS, MD',
          );

    final phone = clinic.phone;
    final masked = phone.length >= 4 ? '******${phone.substring(phone.length - 4)}' : phone;

    setState(() {
      _isLoading = false;
      _activeClinic = clinic;
      _activeDoctor = doctor;
      _maskedPhone = masked;
      _isBookingActive = clinic!.isBookingActive;
      _isOpdActive = clinic.isOpdActive;
      _isOtpSent = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to Clinic registered phone ($masked). Demo OTP: 123456'),
          backgroundColor: const Color(0xFF0F766E),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleVerifyOtp() async {
    final otpInput = _otpController.text.trim();
    if (otpInput != '123456' && otpInput.length < 4) {
      setState(() => _errorMessage = 'Invalid OTP code. Try 123456');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
      _isVerified = true;
    });
  }

  void _handleToggleActiveClinic(bool val) async {
    if (_activeClinic == null) return;
    setState(() => _isBookingActive = val);
    _activeClinic!.isBookingActive = val;

    await ApiService.toggleClinicBooking(_activeClinic!.clinicId, val);
    if (!mounted) return;

    final queueStore = Provider.of<QueueStore>(context, listen: false);
    final today = DateFormat('yyyy-MM-DD').format(DateTime.now());
    await queueStore.toggleQueueActive(
      _activeClinic!.clinicId,
      _activeDoctor?.doctorId ?? 'default',
      today,
      val,
    );
  }

  void _handleToggleStartOpd(bool val) async {
    if (_activeClinic == null) return;
    setState(() => _isOpdActive = val);
    _activeClinic!.isOpdActive = val;

    await ApiService.toggleClinicOpd(_activeClinic!.clinicId, val);

    if (val && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompounderQueueScreen(
            clinic: _activeClinic!,
            doctor: _activeDoctor ??
                Doctor(
                  doctorId: 'DOC-101',
                  clinicId: _activeClinic!.clinicId,
                  name: 'Dr. Rajesh Sharma',
                  phone: _activeClinic!.phone,
                  speciality: _activeClinic!.speciality,
                  qualification: 'MBBS',
                ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compounder Portal', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Logout / Switch Role',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final queueStore = Provider.of<QueueStore>(context, listen: false);
              await queueStore.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: !_isVerified ? _buildVerificationView() : _buildClinicPortalView(),
      ),
    );
  }

  Widget _buildVerificationView() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_outlined, color: Color(0xFF0F766E), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clinic Authorization',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Enter Clinic ID to verify via registered clinic phone',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade900, fontSize: 13)),
              ),
              const SizedBox(height: 16),
            ],

            Text('CLINIC ID (e.g. CS-7K82P)', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 6),
            TextField(
              controller: _clinicIdController,
              enabled: !_isOtpSent,
              decoration: const InputDecoration(
                hintText: 'Enter Clinic ID',
                prefixIcon: Icon(Icons.local_hospital_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            if (!_isOtpSent)
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                  onPressed: _isLoading ? null : _handleSendOtp,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                  label: const Text('SEND OTP TO CLINIC PHONE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),

            if (_isOtpSent) ...[
              Text('ENTER OTP SENT TO $_maskedPhone', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Enter 6-digit OTP (Demo: 123456)',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                  onPressed: _isLoading ? null : _handleVerifyOtp,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('VERIFY & ENTER PORTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClinicPortalView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Clinic Header Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _activeClinic!.name,
                        style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ID: ${_activeClinic!.clinicId}',
                        style: GoogleFonts.sourceCodePro(fontWeight: FontWeight.bold, color: const Color(0xFF0F766E), fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Ref #: ${_activeClinic!.clinicRefNum}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                Text('${_activeClinic!.address}, ${_activeClinic!.city}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const Divider(height: 24),

                if (_activeDoctor != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.medical_services_outlined, color: Color(0xFF0F766E), size: 20),
                      const SizedBox(width: 8),
                      Text('${_activeDoctor!.name} (${_activeDoctor!.speciality})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Management Toggles Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CLINICAL MANAGEMENT CONTROLS', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 16),

                // Toggle 1: Active Clinic
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isBookingActive ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _isBookingActive ? Colors.green.shade400 : Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isBookingActive ? Icons.check_circle_rounded : Icons.power_settings_new_rounded,
                        color: _isBookingActive ? Colors.green.shade800 : Colors.grey.shade600,
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active Clinic (Enable Booking)',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _isBookingActive
                                  ? '🟢 Patients can now book appointments in Patient App'
                                  : '🔴 Booking disabled in Patient App',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isBookingActive,
                        activeThumbColor: const Color(0xFF0F766E),
                        onChanged: _handleToggleActiveClinic,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Toggle 2: Start OPD
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isOpdActive ? const Color(0xFF0284C7).withValues(alpha: 0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _isOpdActive ? const Color(0xFF0284C7) : Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.play_circle_fill_rounded,
                        color: _isOpdActive ? const Color(0xFF0284C7) : Colors.grey.shade600,
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start OPD (Operator Console)',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _isOpdActive ? '🟢 Live Operator Console Open' : 'Tap switch to open Queue Console UI',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isOpdActive,
                        activeThumbColor: const Color(0xFF0284C7),
                        onChanged: _handleToggleStartOpd,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Open Operator Console Button
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompounderQueueScreen(
                    clinic: _activeClinic!,
                    doctor: _activeDoctor ??
                        Doctor(
                          doctorId: 'DOC-101',
                          clinicId: _activeClinic!.clinicId,
                          name: 'Dr. Rajesh Sharma',
                          phone: _activeClinic!.phone,
                          speciality: _activeClinic!.speciality,
                          qualification: 'MBBS',
                        ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.dashboard_customize_rounded),
            label: const Text('OPEN LIVE OPERATOR CONSOLE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
