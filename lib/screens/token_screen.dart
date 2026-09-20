import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/clinic.dart';
import '../models/doctor.dart';
import '../models/token_model.dart';
import '../services/eta_routing_service.dart';
import '../services/queue_store.dart';

class TokenScreen extends StatefulWidget {
  final TokenModel token;
  final Clinic clinic;
  final Doctor doctor;

  const TokenScreen({
    super.key,
    required this.token,
    required this.clinic,
    required this.doctor,
  });

  @override
  State<TokenScreen> createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen> {
  int _estimatedTravelMinutes = 15;
  bool _isCheckingLocation = false;
  bool _shouldLeaveNow = false;

  @override
  void initState() {
    super.initState();
    _checkLocationAndETA();
  }

  Future<void> _checkLocationAndETA() async {
    setState(() => _isCheckingLocation = true);

    final pos = await ETARoutingService.getCurrentLocation();
    if (pos != null) {
      final travelMins = ETARoutingService.estimateTravelMinutes(
        startLat: pos.latitude,
        startLng: pos.longitude,
        destLat: widget.clinic.latitude,
        destLng: widget.clinic.longitude,
      );
      if (mounted) {
        setState(() {
          _estimatedTravelMinutes = travelMins;
          _isCheckingLocation = false;
        });
      }
    } else {
      if (mounted) setState(() => _isCheckingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final queueStore = Provider.of<QueueStore>(context);

    // Get live updated token & queue state
    final liveTokens = queueStore.tokens.where((t) => t.tokenId == widget.token.tokenId);
    final currentTokenState = liveTokens.isNotEmpty ? liveTokens.first : widget.token;

    final today = DateFormat('yyyy-MM-DD').format(DateTime.now());
    final queueState = queueStore.getQueueState(
      widget.clinic.clinicId,
      widget.doctor.doctorId,
      today,
    );

    final nowServing = queueState.currentToken;
    final yourTokenNum = currentTokenState.tokenNumber;

    final patientsAhead = (yourTokenNum - nowServing - 1) < 0 ? 0 : (yourTokenNum - nowServing - 1);
    final waitMinutes = ETARoutingService.calculateQueueWaitMinutes(
      patientTokenNumber: yourTokenNum,
      currentServingToken: nowServing,
      avgConsultationMinutes: widget.doctor.avgConsultationMinutes,
    );

    _shouldLeaveNow = ETARoutingService.shouldAlertToLeave(
      queueWaitMinutes: waitMinutes,
      travelMinutes: _estimatedTravelMinutes,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clinic.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Leave Now Alert Banner if approaching!
            if (_shouldLeaveNow && currentTokenState.status == TokenStatus.waiting) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade800, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: Colors.amber, size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "🔔 It's almost time to leave!",
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your token #$yourTokenNum is approaching. Now serving #$nowServing. Estimated travel time: $_estimatedTravelMinutes mins.',
                            style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Main Token Display Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    widget.clinic.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    widget.doctor.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'YOUR TOKEN NUMBER',
                    style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '#$yourTokenNum',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Chip(
                    avatar: Icon(
                      _getStatusIcon(currentTokenState.status),
                      color: Colors.white,
                      size: 16,
                    ),
                    label: Text(
                      'STATUS: ${currentTokenState.status.name.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Live Queue Dashboard Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'NOW SERVING',
                    value: '#$nowServing',
                    icon: Icons.record_voice_over_rounded,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'PATIENTS AHEAD',
                    value: '$patientsAhead',
                    icon: Icons.people_outline_rounded,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'EST. WAIT TIME',
                    value: '~${waitMinutes}m',
                    icon: Icons.timer_outlined,
                    color: const Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'TRAVEL ETA',
                    value: _isCheckingLocation ? '...' : '~${_estimatedTravelMinutes}m',
                    icon: Icons.directions_car_outlined,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.sync_rounded, color: Color(0xFF0F766E)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Live Queue Sync: This screen automatically updates when the compounder calls next patient. No refresh required.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.sourceCodePro(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(TokenStatus status) {
    switch (status) {
      case TokenStatus.waiting:
        return Icons.hourglass_empty_rounded;
      case TokenStatus.called:
        return Icons.campaign_rounded;
      case TokenStatus.completed:
        return Icons.task_alt_rounded;
      case TokenStatus.skipped:
        return Icons.redo_rounded;
      case TokenStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}
