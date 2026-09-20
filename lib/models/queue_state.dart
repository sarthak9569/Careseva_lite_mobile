class QueueState {
  final String queueId;
  final String clinicId;
  final String doctorId;
  final String date; // YYYY-MM-DD
  int currentToken;
  int lastToken;
  bool isActive; // ACTIVE vs INACTIVE state controlled by compounder
  DateTime updatedAt;

  QueueState({
    required this.queueId,
    required this.clinicId,
    required this.doctorId,
    required this.date,
    this.currentToken = 0,
    this.lastToken = 0,
    this.isActive = false,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'queueId': queueId,
      'clinicId': clinicId,
      'doctorId': doctorId,
      'date': date,
      'currentToken': currentToken,
      'lastToken': lastToken,
      'isActive': isActive,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory QueueState.fromJson(Map<String, dynamic> json) {
    return QueueState(
      queueId: json['queueId'],
      clinicId: json['clinicId'],
      doctorId: json['doctorId'],
      date: json['date'],
      currentToken: json['currentToken'] ?? 0,
      lastToken: json['lastToken'] ?? 0,
      isActive: json['isActive'] ?? false,
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
