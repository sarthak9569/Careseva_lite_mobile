class Doctor {
  final String doctorId;
  final String clinicId;
  final String name;
  final String phone;
  final String speciality;
  final String qualification;
  final int avgConsultationMinutes;

  Doctor({
    required this.doctorId,
    required this.clinicId,
    required this.name,
    required this.phone,
    required this.speciality,
    required this.qualification,
    this.avgConsultationMinutes = 10,
  });

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'clinicId': clinicId,
      'name': name,
      'phone': phone,
      'speciality': speciality,
      'qualification': qualification,
      'avgConsultationMinutes': avgConsultationMinutes,
    };
  }

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      doctorId: json['doctorId'],
      clinicId: json['clinicId'],
      name: json['name'],
      phone: json['phone'],
      speciality: json['speciality'],
      qualification: json['qualification'],
      avgConsultationMinutes: json['avgConsultationMinutes'] ?? 10,
    );
  }
}
