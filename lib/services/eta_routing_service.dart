import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class ETARoutingService {
  /// Check and request location permission safely
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('Location service error: $e');
      return null;
    }
  }

  /// Calculates estimated queue wait time in minutes
  static int calculateQueueWaitMinutes({
    required int patientTokenNumber,
    required int currentServingToken,
    required int avgConsultationMinutes,
  }) {
    if (patientTokenNumber <= currentServingToken) return 0;
    final patientsAhead = patientTokenNumber - currentServingToken - 1;
    final waitMinutes = (patientsAhead + 1) * avgConsultationMinutes;
    return waitMinutes < 0 ? 0 : waitMinutes;
  }

  /// Calculates estimated traffic-aware travel time in minutes based on distance
  static int estimateTravelMinutes({
    required double startLat,
    required double startLng,
    required double destLat,
    required double destLng,
  }) {
    // Distance in meters
    final distanceMeters = Geolocator.distanceBetween(
      startLat,
      startLng,
      destLat,
      destLng,
    );

    // Assume average city traffic speed ~ 25 km/h (approx 416 meters per minute) + 5 min buffer
    final distanceKm = distanceMeters / 1000.0;
    final estimatedMinutes = ((distanceKm / 25.0) * 60.0).round() + 5;
    return estimatedMinutes < 5 ? 5 : estimatedMinutes;
  }

  /// Checks if the patient should be alerted to leave now
  static bool shouldAlertToLeave({
    required int queueWaitMinutes,
    required int travelMinutes,
    int safetyBufferMinutes = 10,
  }) {
    if (queueWaitMinutes == 0) return true;
    return queueWaitMinutes <= (travelMinutes + safetyBufferMinutes);
  }
}
