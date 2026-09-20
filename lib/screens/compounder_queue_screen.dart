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
      appBar: AppBar(
        title: Text('${widget.clinic.name} • ${widget.doctor.name}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Token Banner (NOW SERVING)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'NOW SERVING',
                    style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentServing != null ? '#${currentServing.tokenNumber}' : '#${queueState.currentToken}',
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (currentServing != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      currentServing.patientName,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      currentServing.patientPhone,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    const Text('No patient currently called', style: TextStyle(color: Colors.white70)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Operator Primary Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade900,
                      side: BorderSide(color: Colors.orange.shade800, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: (currentServing != null && !_isActionProcessing)
                        ? () => _handleSkipToken(currentServing.tokenId)
                        : null,
                    icon: const Icon(Icons.redo_rounded),
                    label: const Text('SKIP'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isActionProcessing ? null : _handleCallNext,
                    icon: _isActionProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.navigate_next_rounded, size: 28),
                    label: const Text('CALL NEXT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // WAITING QUEUE LIST
            Row(
              children: [
                Text(
                  'WAITING QUEUE',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${waitingTokens.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            waitingTokens.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text('No patients waiting in queue.')),
                  )
                : Column(
                    children: waitingTokens.map((t) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
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
                              foregroundColor: Colors.orange.shade800,
                              side: BorderSide(color: Colors.orange.shade300),
                            ),
                            onPressed: () => _handleSkipToken(t.tokenId),
                            child: const Text('SKIP'),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 24),

            // SKIPPED TOKENS LIST
            if (skippedTokens.isNotEmpty) ...[
              Text(
                'SKIPPED TOKENS (${skippedTokens.length})',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
              ),
              const SizedBox(height: 8),
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

            // COMPLETED HISTORY
            Text(
              'COMPLETED TODAY (${completedTokens.length})',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            completedTokens.isEmpty
                ? const Text('No completed tokens yet today.', style: TextStyle(color: Colors.grey, fontSize: 12))
                : Column(
                    children: completedTokens.map((t) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                        title: Text('#${t.tokenNumber} - ${t.patientName}'),
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
