import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _cloudBaseUrl = 'https://caresevalitebackend-production.up.railway.app/api';
  static final String _localBaseUrl = kIsWeb ? 'http://localhost:8000/api' : 'http://10.0.2.2:8000/api';

  // In development / local testing, prioritize local backend for instant responses
  static String _activeBaseUrl = (kDebugMode || kIsWeb) ? 'http://localhost:8000/api' : _cloudBaseUrl;
  static String get baseUrl => _activeBaseUrl;

  static List<String> get _candidateHosts => [
        _activeBaseUrl,
        'http://localhost:8000/api',
        'http://192.168.1.7:8000/api',
        _localBaseUrl,
        if (!kIsWeb) 'http://10.0.2.2:8000/api',
        _cloudBaseUrl,
      ].toSet().toList();

  static String get wsBaseUrl {
    if (_activeBaseUrl.contains('railway.app')) {
      return 'wss://caresevalitebackend-production.up.railway.app';
    } else if (_activeBaseUrl.contains('localhost')) {
      return 'ws://localhost:8000';
    } else {
      return 'ws://192.168.1.7:8000';
    }
  }

  static String getQueueWebSocketUrl(String clinicId, String date) =>
      '$wsBaseUrl/ws/queue/$clinicId/$date';

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Future<http.Response> _get(String path, {Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse('$_activeBaseUrl$path').replace(queryParameters: queryParams);
      final res = await http.get(uri, headers: headers).timeout(const Duration(milliseconds: 1500));
      if (res.statusCode < 500) {
        return res;
      }
    } catch (_) {}

    for (final host in _candidateHosts) {
      if (host == _activeBaseUrl) continue;
      try {
        final uri = Uri.parse('$host$path').replace(queryParameters: queryParams);
        final res = await http.get(uri, headers: headers).timeout(const Duration(milliseconds: 1500));
        if (res.statusCode < 500) {
          _activeBaseUrl = host;
          return res;
        }
      } catch (_) {}
    }
    throw Exception('Failed to connect to any backend host for GET $path');
  }

  static Future<http.Response> _post(String path, {Object? body}) async {
    final encodedBody = body != null ? jsonEncode(body) : '{}';

    try {
      final uri = Uri.parse('$_activeBaseUrl$path');
      final res = await http.post(
        uri,
        headers: headers,
        body: encodedBody,
      ).timeout(const Duration(milliseconds: 2000));
      if (res.statusCode < 500) {
        return res;
      }
    } catch (_) {}

    for (final host in _candidateHosts) {
      if (host == _activeBaseUrl) continue;
      try {
        final uri = Uri.parse('$host$path');
        final res = await http.post(
          uri,
          headers: headers,
          body: encodedBody,
        ).timeout(const Duration(milliseconds: 2000));
        if (res.statusCode < 500) {
          _activeBaseUrl = host;
          return res;
        }
      } catch (_) {}
    }
    throw Exception('Failed to post to any backend host for POST $path');
  }

  // Health check
  static Future<bool> checkBackendHealth() async {
    try {
      final res = await _get('/health');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Auth Routes
  static Future<Map<String, dynamic>?> loginOrRegister(Map<String, dynamic> body) async {
    try {
      final res = await _post('/auth/login', body: body);
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[ApiService Login Error] $e');
      return null;
    }
  }

  // Clinics & Doctors
  static Future<List<dynamic>> getClinics({String? search, String? city}) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (city != null && city.isNotEmpty) queryParams['city'] = city;

      final res = await _get('/clinics', queryParams: queryParams.isNotEmpty ? queryParams : null);
      final data = jsonDecode(res.body);
      return data['clinics'] ?? [];
    } catch (e) {
      debugPrint('[ApiService Get Clinics Error] $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getClinicByIdentifier(String identifier) async {
    try {
      final res = await _get('/clinics/lookup/$identifier');
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[ApiService Lookup Clinic Error] $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> sendCompounderOtp(String clinicId) async {
    try {
      final res = await _post('/clinics/$clinicId/send-compounder-otp');
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[ApiService Send Compounder OTP Error] $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> verifyCompounderOtp(String clinicId, String otp) async {
    try {
      final res = await _post('/clinics/$clinicId/verify-compounder-otp', body: {'otp': otp});
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[ApiService Verify Compounder OTP Error] $e');
      return null;
    }
  }

  static Future<bool> toggleClinicBooking(String clinicId, bool state) async {
    try {
      final res = await _post('/clinics/$clinicId/toggle-booking', body: {'state': state});
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService Toggle Clinic Booking Error] $e');
      return false;
    }
  }

  static Future<bool> toggleClinicOpd(String clinicId, bool state) async {
    try {
      final res = await _post('/clinics/$clinicId/toggle-opd', body: {'state': state});
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService Toggle Clinic OPD Error] $e');
      return false;
    }
  }

  static Future<List<dynamic>> getDoctors(String clinicId) async {
    try {
      final res = await _get('/clinics/$clinicId/doctors');
      final data = jsonDecode(res.body);
      return data['doctors'] ?? [];
    } catch (e) {
      debugPrint('[ApiService Get Doctors Error] $e');
      return [];
    }
  }

  // Applications
  static Future<Map<String, dynamic>?> submitApplication(Map<String, dynamic> appData) async {
    try {
      final res = await _post('/applications', body: appData);
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[ApiService Submit Application Error] $e');
      return null;
    }
  }

  static Future<List<dynamic>> getApplications({String? status}) async {
    try {
      final res = await _get(
        '/applications',
        queryParams: status != null ? {'status': status} : null,
      );
      final data = jsonDecode(res.body);
      return data['applications'] ?? [];
    } catch (e) {
      debugPrint('[ApiService Get Applications Error] $e');
      return [];
    }
  }

  static Future<bool> approveApplication(String appId) async {
    try {
      final res = await _post('/applications/$appId/approve');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService Approve Application Error] $e');
      return false;
    }
  }

  static Future<bool> rejectApplication(String appId, String reason) async {
    try {
      final res = await _post(
        '/applications/$appId/reject',
        body: {'rejectionReason': reason},
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
      final res = await _get(
        '/queues/$clinicId/$date',
        queryParams: doctorId != null ? {'doctorId': doctorId} : null,
      );
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[ApiService Get Queue Error] $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> createToken(Map<String, dynamic> tokenData) async {
    try {
      final res = await _post('/queues/token', body: tokenData);
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[ApiService Create Token Error] $e');
      return null;
    }
  }

  static Future<bool> toggleQueueActive(String clinicId, String date, String doctorId, bool isActive) async {
    try {
      final res = await _post(
        '/queues/toggle-active',
        body: {
          'clinicId': clinicId,
          'date': date,
          'doctorId': doctorId,
          'isActive': isActive,
        },
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService Toggle Queue Error] $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> callNextToken(String clinicId, String date, String doctorId) async {
    try {
      final res = await _post(
        '/queues/call-next',
        body: {
          'clinicId': clinicId,
          'date': date,
          'doctorId': doctorId,
        },
      );
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('[ApiService Call Next Error] $e');
      return null;
    }
  }

  static Future<bool> updateTokenStatus(String tokenId, String status) async {
    try {
      for (final host in _candidateHosts) {
        try {
          final res = await http.patch(
            Uri.parse('$host/queues/token/$tokenId/status'),
            headers: headers,
            body: jsonEncode({'status': status}),
          ).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200) {
            _activeBaseUrl = host;
            return true;
          }
        } catch (_) {}
      }
      return false;
    } catch (e) {
      debugPrint('[ApiService Update Token Status Error] $e');
      return false;
    }
  }
}
