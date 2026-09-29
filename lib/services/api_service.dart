import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Update this to your deployed Railway backend URL or use local testing host
  static const String baseUrl = kIsWeb
      ? 'http://localhost:8000/api'
      : 'http://10.0.2.2:8000/api'; // Android emulator localhost alias

  static String get wsBaseUrl => kIsWeb
      ? 'ws://localhost:8000'
      : 'ws://10.0.2.2:8000';

  static String getQueueWebSocketUrl(String clinicId, String date) =>
      '$wsBaseUrl/ws/queue/$clinicId/$date';

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Health check
  static Future<bool> checkBackendHealth() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Auth Routes
  static Future<Map<String, dynamic>?> loginOrRegister(Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: headers,
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('[ApiService Login Error] $e');
    }
    return null;
  }

  // Clinics & Doctors
  static Future<List<dynamic>> getClinics({String? search, String? city}) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (city != null && city.isNotEmpty) queryParams['city'] = city;

      final uri = Uri.parse('$baseUrl/clinics').replace(queryParameters: queryParams);
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['clinics'] ?? [];
      }
    } catch (e) {
      debugPrint('[ApiService Get Clinics Error] $e');
    }
    return [];
  }

  static Future<List<dynamic>> getDoctors(String clinicId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/clinics/$clinicId/doctors'), headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['doctors'] ?? [];
      }
    } catch (e) {
      debugPrint('[ApiService Get Doctors Error] $e');
    }
    return [];
  }

  // Applications
  static Future<Map<String, dynamic>?> submitApplication(Map<String, dynamic> appData) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/applications'),
        headers: headers,
        body: jsonEncode(appData),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('[ApiService Submit Application Error] $e');
    }
    return null;
  }

  static Future<List<dynamic>> getApplications({String? status}) async {
    try {
      final uri = Uri.parse('$baseUrl/applications').replace(
        queryParameters: status != null ? {'status': status} : null,
      );
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['applications'] ?? [];
      }
    } catch (e) {
      debugPrint('[ApiService Get Applications Error] $e');
    }
    return [];
  }

  static Future<bool> approveApplication(String appId) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/applications/$appId/approve'), headers: headers);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService Approve Application Error] $e');
      return false;
    }
  }

  static Future<bool> rejectApplication(String appId, String reason) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/applications/$appId/reject'),
        headers: headers,
        body: jsonEncode({'rejectionReason': reason}),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService Reject Application Error] $e');
      return false;
    }
  }

  // Queue & Token API
  static Future<Map<String, dynamic>?> getQueueData(String clinicId, String date, {String? doctorId}) async {
    try {
      final uri = Uri.parse('$baseUrl/queues/$clinicId/$date').replace(
        queryParameters: doctorId != null ? {'doctorId': doctorId} : null,
      );
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('[ApiService Get Queue Error] $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> createToken(Map<String, dynamic> tokenData) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/queues/token'),
        headers: headers,
        body: jsonEncode(tokenData),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('[ApiService Create Token Error] $e');
    }
    return null;
  }

  static Future<bool> toggleQueueActive(String clinicId, String date, String doctorId, bool isActive) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/queues/toggle-active'),
        headers: headers,
        body: jsonEncode({
          'clinicId': clinicId,
          'date': date,
          'doctorId': doctorId,
          'isActive': isActive,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService Toggle Queue Error] $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> callNextToken(String clinicId, String date, String doctorId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/queues/call-next'),
        headers: headers,
        body: jsonEncode({
          'clinicId': clinicId,
          'date': date,
          'doctorId': doctorId,
        }),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('[ApiService Call Next Error] $e');
    }
    return null;
  }

  static Future<bool> updateTokenStatus(String tokenId, String status) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/queues/token/$tokenId/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService Update Token Status Error] $e');
      return false;
    }
  }
}
