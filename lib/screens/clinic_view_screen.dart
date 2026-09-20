import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/clinic.dart';
import '../models/doctor.dart';
import '../services/queue_store.dart';
import 'token_screen.dart';

class ClinicViewScreen extends StatefulWidget {
  final Clinic clinic;

  const ClinicViewScreen({super.key, required this.clinic});

  @override
  State<ClinicViewScreen> createState() => _ClinicViewScreenState();
}

class _ClinicViewScreenState extends State<ClinicViewScreen> {
  bool _isBooking = false;

  void _handleJoinQueue(Doctor doctor) async {
    final queueStore = Provider.of<QueueStore>(context, listen: false);
    final user = queueStore.currentUser;
    if (user == null) return;

    final date = DateFormat('yyyy-MM-DD').format(DateTime.now());

    // Check duplicate active token before booking
    final existing = queueStore.getActiveTokenForUser(
      userId: user.userId,
      clinicId: widget.clinic.clinicId,
      doctorId: doctor.doctorId,
      date: date,
    );

    if (existing != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You already have an active token: #${existing.tokenNumber}'),
          backgroundColor: Colors.orange.shade800,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TokenScreen(
            token: existing,
            clinic: widget.clinic,
            doctor: doctor,
          ),
        ),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      final newToken = await queueStore.joinQueue(
        clinicId: widget.clinic.clinicId,
        doctorId: doctor.doctorId,
        date: date,
      );

      setState(() => _isBooking = false);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TokenScreen(
              token: newToken,
              clinic: widget.clinic,
              doctor: doctor,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isBooking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final queueStore = Provider.of<QueueStore>(context);
    final doctors = queueStore.getDoctorsForClinic(widget.clinic.clinicId);
    final today = DateFormat('yyyy-MM-DD').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clinic.name),
      ),
      body: _isBooking
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clinic Header Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF0F766E), size: 28),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.clinic.name,
                                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      widget.clinic.speciality,
                                      style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(Icons.location_on_outlined, '${widget.clinic.address}, ${widget.clinic.city}'),
                          _buildDetailRow(Icons.access_time_outlined, widget.clinic.operatingHours),
                          _buildDetailRow(Icons.phone_outlined, widget.clinic.phone),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Doctors & Live Queue Status
                  Text(
                    'Available Doctors & Live Queues',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  doctors.isEmpty
                      ? const Center(child: Text('No doctors assigned to this clinic yet.'))
                      : Column(
                          children: doctors.map((doc) {
                            final queueState = queueStore.getQueueState(
                              widget.clinic.clinicId,
                              doc.doctorId,
                              today,
                            );

                            final isActive = queueState.isActive;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isActive ? Colors.green.shade300 : Colors.grey.shade300,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.1),
                                          child: const Icon(Icons.medical_services_rounded, color: Color(0xFF0F766E)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                doc.name,
                                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                '${doc.speciality} • ${doc.qualification}',
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // Real-Time Queue Status Bar
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isActive ? Icons.circle : Icons.stop_circle_outlined,
                                            color: isActive ? Colors.green : Colors.red,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isActive ? '🟢 Queue Active' : '🔴 Queue Currently Closed',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isActive ? Colors.green.shade900 : Colors.red.shade900,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (isActive)
                                            Text(
                                              'Serving: #${queueState.currentToken}',
                                              style: GoogleFonts.sourceCodePro(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade900,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    // Action Button
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isActive ? const Color(0xFF0F766E) : Colors.grey.shade400,
                                        ),
                                        onPressed: isActive ? () => _handleJoinQueue(doc) : null,
                                        icon: const Icon(Icons.confirmation_number_rounded),
                                        label: Text(
                                          isActive ? 'JOIN QUEUE' : 'DOCTOR UNAVAILABLE',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)))),
        ],
      ),
    );
  }
}
