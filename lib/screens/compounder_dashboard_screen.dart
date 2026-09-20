import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/clinic.dart';
import '../models/doctor.dart';
import '../services/queue_store.dart';
import 'compounder_queue_screen.dart';
import 'role_selection_screen.dart';

class CompounderDashboardScreen extends StatefulWidget {
  const CompounderDashboardScreen({super.key});

  @override
  State<CompounderDashboardScreen> createState() => _CompounderDashboardScreenState();
}

class _CompounderDashboardScreenState extends State<CompounderDashboardScreen> {
  Clinic? _selectedClinic;
  Doctor? _selectedDoctor;

  @override
  Widget build(BuildContext context) {
    final queueStore = Provider.of<QueueStore>(context);
    final clinics = queueStore.clinics;
    final today = DateFormat('yyyy-MM-DD').format(DateTime.now());

    if (_selectedClinic == null && clinics.isNotEmpty) {
      _selectedClinic = clinics.first;
    }

    final doctors = _selectedClinic != null
        ? queueStore.getDoctorsForClinic(_selectedClinic!.clinicId)
        : <Doctor>[];

    if (_selectedDoctor == null && doctors.isNotEmpty) {
      _selectedDoctor = doctors.first;
    }

    final queueState = (_selectedClinic != null && _selectedDoctor != null)
        ? queueStore.getQueueState(_selectedClinic!.clinicId, _selectedDoctor!.doctorId, today)
        : null;

    final isActive = queueState?.isActive ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text('Compounder Panel', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Switch Mode',
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Clinic Selector
            Text(
              'AUTHORIZED CLINIC',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<Clinic>(
              initialValue: _selectedClinic,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_hospital_outlined),
              ),
              items: clinics.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text('${c.name} (${c.clinicId})'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedClinic = val;
                  _selectedDoctor = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // Doctor Selector
            Text(
              'DOCTOR QUEUE',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<Doctor>(
              initialValue: _selectedDoctor,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services_outlined),
              ),
              items: doctors.map((d) {
                return DropdownMenuItem(
                  value: d,
                  child: Text('${d.name} (${d.speciality})'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedDoctor = val);
              },
            ),
            const SizedBox(height: 24),

            if (_selectedClinic != null && _selectedDoctor != null && queueState != null) ...[
              // Queue Status Control Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        _selectedClinic!.name,
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _selectedDoctor!.name,
                        style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),

                      // Status Indicator Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive ? Colors.green : Colors.red,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isActive ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded,
                              color: isActive ? Colors.green : Colors.red,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isActive ? 'QUEUE STATUS: ACTIVE' : 'QUEUE STATUS: INACTIVE',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.green.shade900 : Colors.red.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        isActive
                            ? '🟢 QUEUE ACTIVE: Patients can now search Clinic ID "${_selectedClinic!.clinicId}" and join queue in real time.'
                            : '🔴 QUEUE INACTIVE: Doctor is unavailable or clinic is closed. Patients cannot join.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
                      ),
                      const SizedBox(height: 24),

                      // Activate / Deactivate Toggle Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isActive ? Colors.red.shade700 : Colors.green.shade700,
                          ),
                          onPressed: () async {
                            await queueStore.toggleQueueActive(
                              _selectedClinic!.clinicId,
                              _selectedDoctor!.doctorId,
                              today,
                              !isActive,
                            );
                          },
                          icon: Icon(
                            isActive ? Icons.power_settings_new_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                          label: Text(
                            isActive ? 'DEACTIVATE QUEUE' : 'ACTIVATE QUEUE (DOCTOR ARRIVED)',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Open Queue Operator Screen Button
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CompounderQueueScreen(
                          clinic: _selectedClinic!,
                          doctor: _selectedDoctor!,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.dashboard_customize_rounded),
                  label: const Text('OPEN LIVE OPERATOR CONSOLE'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
