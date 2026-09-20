enum TokenStatus { waiting, called, completed, skipped, cancelled }

class TokenModel {
  final String tokenId;
  final String clinicId;
  final String doctorId;
  final String userId;
  final String patientName;
  final String patientPhone;
  final String date; // YYYY-MM-DD
  final int tokenNumber;
  TokenStatus status;
  final DateTime createdAt;
  DateTime? calledAt;
  DateTime? completedAt;
  DateTime? skippedAt;

  TokenModel({
    required this.tokenId,
    required this.clinicId,
    required this.doctorId,
    required this.userId,
    required this.patientName,
    required this.patientPhone,
    required this.date,
    required this.tokenNumber,
    this.status = TokenStatus.waiting,
    required this.createdAt,
    this.calledAt,
    this.completedAt,
    this.skippedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'tokenId': tokenId,
      'clinicId': clinicId,
      'doctorId': doctorId,
      'userId': userId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'date': date,
      'tokenNumber': tokenNumber,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'calledAt': calledAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'skippedAt': skippedAt?.toIso8601String(),
    };
  }

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      tokenId: json['tokenId'],
      clinicId: json['clinicId'],
      doctorId: json['doctorId'],
      userId: json['userId'],
      patientName: json['patientName'] ?? 'Patient',
      patientPhone: json['patientPhone'] ?? '',
      date: json['date'],
      tokenNumber: json['tokenNumber'],
      status: TokenStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TokenStatus.waiting,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      calledAt: json['calledAt'] != null ? DateTime.parse(json['calledAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      skippedAt: json['skippedAt'] != null ? DateTime.parse(json['skippedAt']) : null,
    );
  }
}
