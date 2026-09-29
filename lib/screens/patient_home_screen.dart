import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/queue_store.dart';
import 'clinic_view_screen.dart';
import 'role_selection_screen.dart';
import 'token_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final _clinicIdController = TextEditingController();
  String? _errorMessage;

  void _handleFindClinic() {
    final input = _clinicIdController.text.trim();
    if (input.isEmpty) {
      setState(() => _errorMessage = 'Please enter a Clinic Reference Number or Clinic ID');
      return;
    }

    setState(() => _errorMessage = null);

    final queueStore = Provider.of<QueueStore>(context, listen: false);
    final clinic = queueStore.findClinicById(input);

    if (clinic == null) {
      setState(() {
        _errorMessage = 'Clinic not found.\n\nPlease check the Clinic Reference Number and try again.';
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClinicViewScreen(clinic: clinic),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final queueStore = Provider.of<QueueStore>(context);
    final user = queueStore.currentUser;

    // Find active patient tokens
    final activeTokens = queueStore.tokens
        .where((t) => t.userId == user?.userId && (t.status.name == 'waiting' || t.status.name == 'called'))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('CareSeva 2', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Logout / Switch Role',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Greeting Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF0F766E),
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'P',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user?.name ?? 'Patient'}',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${user?.phone} • ${user?.age} yrs, ${user?.gender}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Active Tokens Banner if any
            if (activeTokens.isNotEmpty) ...[
              Text(
                'YOUR ACTIVE TOKENS',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              ...activeTokens.map((token) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: const Color(0xFF0F766E),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      'TOKEN #${token.tokenNumber}',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      'Status: ${token.status.name.toUpperCase()}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: const ElevatedButton(
                      onPressed: null,
                      child: Text('VIEW TOKEN', style: TextStyle(color: Color(0xFF0F766E))),
                    ),
                    onTap: () {
                      final clinic = queueStore.clinics.firstWhere((c) => c.clinicId == token.clinicId);
                      final doctor = queueStore.doctors.firstWhere((d) => d.doctorId == token.doctorId);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TokenScreen(
                            token: token,
                            clinic: clinic,
                            doctor: doctor,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            // Clinic Search Card
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Join Clinic Queue',
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Enter the 7-character Clinic ID provided by your clinic/doctor (e.g. CS-7K82P)',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _clinicIdController,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        color: const Color(0xFF0F766E),
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. CS-7K82P',
                        prefixIcon: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF0F766E)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _handleFindClinic,
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('FIND CLINIC'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Demo Helper Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: Colors.blue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Demo Tip: Enter "CS-7K82P" or "CS-9X42M" to connect instantly to sample clinic queues.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
