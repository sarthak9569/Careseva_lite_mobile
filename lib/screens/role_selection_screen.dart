import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/queue_store.dart';
import 'auth_screen.dart';
import 'compounder_dashboard_screen.dart';
import 'patient_home_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queueStore = Provider.of<QueueStore>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    size: 64,
                    color: Color(0xFF0F766E),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'CareSeva 2',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Real-Time Clinic Queue & Token Booking',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF64748B),
                ),
              ),
              const Spacer(),

              // Patient Option
              _buildRoleCard(
                context,
                title: 'Patient App',
                subtitle: 'Enter Clinic ID, book token & track live doctor queue in real-time',
                icon: Icons.person_pin_rounded,
                color: const Color(0xFF0F766E),
                onTap: () {
                  if (queueStore.currentUser == null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AuthScreen(targetRole: UserRole.patient),
                      ),
                    );
                  } else {
                    queueStore.switchRole(UserRole.patient);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),

              // Compounder Option
              _buildRoleCard(
                context,
                title: 'Compounder Dashboard',
                subtitle: 'Activate queue, call next patient, skip, and manage clinic operations',
                icon: Icons.assignment_ind_rounded,
                color: const Color(0xFF0284C7),
                onTap: () {
                  if (queueStore.currentUser == null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AuthScreen(targetRole: UserRole.compounder),
                      ),
                    );
                  } else {
                    queueStore.switchRole(UserRole.compounder);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CompounderDashboardScreen()),
                    );
                  }
                },
              ),
              const Spacer(),
              Center(
                child: Text(
                  'Powered by CareSeva Ecosystem',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
