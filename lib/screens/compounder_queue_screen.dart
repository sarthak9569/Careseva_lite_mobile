import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/clinic.dart';
import '../models/doctor.dart';
import '../models/token_model.dart';
import '../services/queue_store.dart';

class CompounderQueueScreen extends StatefulWidget {
  final Clinic clinic;
  final Doctor doctor;

  const CompounderQueueScreen({
    super.key,
    required this.clinic,
    required this.doctor,
  });

  @override
  State<CompounderQueueScreen> createState() => _CompounderQueueScreenState();
}

class _CompounderQueueScreenState extends State<CompounderQueueScreen> {
  bool _isActionProcessing = false;

  void _handleCallNext() async {
    setState(() => _isActionProcessing = true);
    final queueStore = Provider.of<QueueStore>(context, listen: false);
    final today = DateFormat('yyyy-MM-DD').format(DateTime.now());

    await queueStore.callNextToken(
      widget.clinic.clinicId,
      widget.doctor.doctorId,
      today,
    );

    setState(() => _isActionProcessing = false);
  }

  void _handleSkipToken(String tokenId) async {
    setState(() => _isActionProcessing = true);
    final queueStore = Provider.of<QueueStore>(context, listen: false);
    await queueStore.skipToken(tokenId);
    setState(() => _isActionProcessing = false);
  }

  void _handleCallAgain(String tokenId) async {
    setState(() => _isActionProcessing = true);
    final queueStore = Provider.of<QueueStore>(context, listen: false);
    await queueStore.callAgainToken(tokenId);
    setState(() => _isActionProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final queueStore = Provider.of<QueueStore>(context);
    final today = DateFormat('yyyy-MM-DD').format(DateTime.now());

    final queueState = queueStore.getQueueState(
      widget.clinic.clinicId,
      widget.doctor.doctorId,
      today,
    );

    final queueTokens = queueStore.getTokensForQueue(
      widget.clinic.clinicId,
      widget.doctor.doctorId,
      today,
    );

    final calledTokens = queueTokens.where((t) => t.status == TokenStatus.called).toList();
    final TokenModel? currentServing = calledTokens.isNotEmpty ? calledTokens.first : null;

    final waitingTokens = queueTokens.where((t) => t.status == TokenStatus.waiting).toList();
    final skippedTokens = queueTokens.where((t) => t.status == TokenStatus.skipped).toList();
    final completedTokens = queueTokens.where((t) => t.status == TokenStatus.completed).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${widget.clinic.name} • ${widget.doctor.name}'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // NOW SERVING CARD (Matching Screenshot layout & colors)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E), // Emerald Green
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'NOW SERVING',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentServing != null ? '#${currentServing.tokenNumber}' : '#${queueState.currentToken}',
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentServing != null
                        ? '${currentServing.patientName} (${currentServing.patientPhone})'
                        : 'No patient currently called',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ACTION BUTTONS: SKIP & CALL NEXT (Matching Screenshot Layout)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade900,
                        side: BorderSide(color: Colors.orange.shade800, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      onPressed: (currentServing != null && !_isActionProcessing)
                          ? () => _handleSkipToken(currentServing.tokenId)
                          : null,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.undo_rounded, size: 20),
                          SizedBox(width: 6),
                          Text('SKIP', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      onPressed: _isActionProcessing ? null : _handleCallNext,
                      child: _isActionProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chevron_right_rounded, size: 28, color: Colors.white),
                                SizedBox(width: 4),
                                Text('CALL NEXT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // WAITING QUEUE SECTION
            Row(
              children: [
                Text(
                  'WAITING QUEUE',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${waitingTokens.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7), fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            waitingTokens.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        'No patients waiting in queue.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ),
                  )
                : Column(
                    children: waitingTokens.map((t) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.1),
                            child: Text(
                              '#${t.tokenNumber}',
                              style: GoogleFonts.sourceCodePro(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F766E),
                              ),
                            ),
                          ),
                          title: Text(t.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(t.patientPhone),
                          trailing: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange.shade900,
                              side: BorderSide(color: Colors.orange.shade300),
                            ),
                            onPressed: () => _handleSkipToken(t.tokenId),
                            child: const Text('SKIP'),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

            const SizedBox(height: 28),

            // SKIPPED TOKENS LIST (If any)
            if (skippedTokens.isNotEmpty) ...[
              Text(
                'SKIPPED TOKENS (${skippedTokens.length})',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
              ),
              const SizedBox(height: 10),
              ...skippedTokens.map((t) {
                return Card(
                  color: Colors.orange.shade50,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Text(
                      '#${t.tokenNumber}',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                    title: Text(t.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Status: SKIPPED'),
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
                      onPressed: () => _handleCallAgain(t.tokenId),
                      icon: const Icon(Icons.replay_rounded, size: 16),
                      label: const Text('CALL AGAIN'),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // COMPLETED TODAY SECTION
            Text(
              'COMPLETED TODAY (${completedTokens.length})',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),

            completedTokens.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'No completed tokens yet today.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  )
                : Column(
                    children: completedTokens.map((t) {
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                        title: Text('#${t.tokenNumber} - ${t.patientName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Completed at: ${DateFormat('hh:mm a').format(t.completedAt ?? DateTime.now())}'),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
