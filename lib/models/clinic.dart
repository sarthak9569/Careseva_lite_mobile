enum ClinicStatus { pending, approved, rejected, suspended }

class Clinic {
  final String clinicId; // Unique alpha-numeric ID e.g. CS-7K82P
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

  Clinic({
    required this.clinicId,
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
  });

  Map<String, dynamic> toJson() {
    return {
      'clinicId': clinicId,
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
    };
  }

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      clinicId: json['clinicId'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'] ?? '',
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speciality: json['speciality'],
      operatingHours: json['operatingHours'],
      status: ClinicStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ClinicStatus.approved,
      ),
    );
  }
}
