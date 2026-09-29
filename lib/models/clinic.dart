enum ClinicStatus { pending, approved, rejected, suspended }

class Clinic {
  final String clinicId; // e.g. CS-7K82P
  final String clinicRefNum; // e.g. REF-78291
  final String name;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final String speciality;
  final String operatingHours;
  final ClinicStatus status;
  bool isBookingActive;
  bool isOpdActive;

  Clinic({
    required this.clinicId,
    required this.clinicRefNum,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.speciality,
    required this.operatingHours,
    this.status = ClinicStatus.approved,
    this.isBookingActive = false,
    this.isOpdActive = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'clinicId': clinicId,
      'clinicRefNum': clinicRefNum,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'speciality': speciality,
      'operatingHours': operatingHours,
      'status': status.name,
      'isBookingActive': isBookingActive,
      'isOpdActive': isOpdActive,
    };
  }

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      clinicId: json['clinicId'] ?? '',
      clinicRefNum: json['clinicRefNum'] ?? json['clinicId'] ?? '',
      name: json['name'] ?? 'Clinic',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      speciality: json['speciality'] ?? '',
      operatingHours: json['operatingHours'] ?? '',
      status: ClinicStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ClinicStatus.approved,
      ),
      isBookingActive: json['isBookingActive'] ?? false,
      isOpdActive: json['isOpdActive'] ?? false,
    );
  }
}
