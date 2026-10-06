import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/clinic.dart';
import '../models/doctor.dart';
import '../models/queue_state.dart';
import '../models/token_model.dart';
import '../models/user_profile.dart';
import 'api_service.dart';

class QueueStore extends ChangeNotifier {
  static const String _kUserProfileKey = 'cs_user_profile';
  static const String _kClinicsKey = 'cs_approved_clinics';
  static const String _kDoctorsKey = 'cs_doctors';
  static const String _kQueuesKey = 'cs_queues_map';
  static const String _kTokensKey = 'cs_tokens_list';

  UserProfile? _currentUser;
  List<Clinic> _clinics = [];
  List<Doctor> _doctors = [];

  // Map key: "clinicId__doctorId__YYYY-MM-DD"
  Map<String, QueueState> _queues = {};
  List<TokenModel> _tokens = [];

  Timer? _queueSyncTimer;
  String? _activeSyncClinicId;
  String? _activeSyncDate;
  String? _activeSyncDoctorId;

  UserProfile? get currentUser => _currentUser;
  List<Clinic> get clinics => _clinics;
  List<Doctor> get doctors => _doctors;
  List<TokenModel> get tokens => _tokens;

  QueueStore() {
    _initAndLoadData();
  }

  @override
  void dispose() {
    _queueSyncTimer?.cancel();
    super.dispose();
  }

  void startQueueSync(String clinicId, String date, {String? doctorId}) {
    _activeSyncClinicId = clinicId;
    _activeSyncDate = date;
    _activeSyncDoctorId = doctorId;
    syncActiveQueueRemote();

    _queueSyncTimer?.cancel();
    _queueSyncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      syncActiveQueueRemote();
    });
  }

  Future<void> syncActiveQueueRemote() async {
    if (_activeSyncClinicId == null || _activeSyncDate == null) return;
    try {
      final res = await ApiService.getQueueData(
        _activeSyncClinicId!,
        _activeSyncDate!,
        doctorId: _activeSyncDoctorId,
      );
      if (res != null && res['success'] == true) {
        if (res['queue'] != null) {
          final qMap = Map<String, dynamic>.from(res['queue']);
          final qState = QueueState.fromJson(qMap);
          final queueKey = '${qState.clinicId}__${qState.doctorId}__${qState.date}';
          _queues[queueKey] = qState;
        }
        if (res['tokens'] != null) {
          final List tokenList = res['tokens'];
          for (var tJson in tokenList) {
            final tModel = TokenModel.fromJson(Map<String, dynamic>.from(tJson));
            final idx = _tokens.indexWhere((t) => t.tokenId == tModel.tokenId);
            if (idx != -1) {
              _tokens[idx] = tModel;
            } else {
              _tokens.add(tModel);
            }
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Patient QueueStore Sync Notice] $e');
    }
  }

  Future<void> _initAndLoadData() async {
    await _loadLocalData();

    // Fetch approved clinics and doctors from Railway FastAPI MongoDB backend
    try {
      final remoteClinics = await ApiService.getClinics();
      if (remoteClinics.isNotEmpty) {
        _clinics = remoteClinics.map((e) => Clinic.fromJson(Map<String, dynamic>.from(e))).toList();
        await _saveData();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[QueueStore] Railway Clinics API Notice: $e');
    }
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();

    final userRaw = prefs.getString(_kUserProfileKey);
    if (userRaw != null) {
      _currentUser = UserProfile.fromJson(jsonDecode(userRaw));
    }

    final clinicsRaw = prefs.getString(_kClinicsKey);
    if (clinicsRaw != null) {
      final List decoded = jsonDecode(clinicsRaw);
      _clinics = decoded.map((e) => Clinic.fromJson(e)).toList();
    } else {
      _seedDefaultData();
    }

    final doctorsRaw = prefs.getString(_kDoctorsKey);
    if (doctorsRaw != null) {
      final List decoded = jsonDecode(doctorsRaw);
      _doctors = decoded.map((e) => Doctor.fromJson(e)).toList();
    }

    final queuesRaw = prefs.getString(_kQueuesKey);
    if (queuesRaw != null) {
      final Map<String, dynamic> decoded = jsonDecode(queuesRaw);
      _queues = decoded.map((k, v) => MapEntry(k, QueueState.fromJson(v)));
    }

    final tokensRaw = prefs.getString(_kTokensKey);
    if (tokensRaw != null) {
      final List decoded = jsonDecode(tokensRaw);
      _tokens = decoded.map((e) => TokenModel.fromJson(e)).toList();
    }

    notifyListeners();
  }

  void _seedDefaultData() {
    const demoClinicId = 'CS-7K82P';

    _clinics = [
      Clinic(
        clinicId: demoClinicId,
        clinicRefNum: 'REF-78291',
        name: 'ABC Dental Clinic',
        phone: '+91 98765 43210',
        email: 'contact@abcdental.com',
        address: '102 Healthcare Avenue, Block B',
        city: 'Mumbai',
        state: 'Maharashtra',
        pincode: '400001',
        latitude: 19.0760,
        longitude: 72.8777,
        speciality: 'Dental & Orthodontics',
        operatingHours: '09:00 AM - 08:00 PM',
        status: ClinicStatus.approved,
      ),
    ];

    _doctors = [
      Doctor(
        doctorId: 'DOC-1',
        clinicId: demoClinicId,
        name: 'Dr. Rahul Sharma',
        phone: '+91 98765 43211',
        speciality: 'Dentist',
        qualification: 'BDS, MDS (Orthodontics)',
        avgConsultationMinutes: 10,
      ),
    ];

    final today = DateFormat('yyyy-MM-DD').format(DateTime.now());
    final queueKey = '${demoClinicId}__DOC-1__$today';

    _queues[queueKey] = QueueState(
      queueId: queueKey,
      clinicId: demoClinicId,
      doctorId: 'DOC-1',
      date: today,
      currentToken: 24,
      lastToken: 27,
      isActive: true,
      updatedAt: DateTime.now(),
    );

    _tokens = [
      TokenModel(
        tokenId: 'T-24',
        clinicId: demoClinicId,
        doctorId: 'DOC-1',
        userId: 'USER-24',
        patientName: 'Ramesh Kumar',
        patientPhone: '+91 98000 00024',
        date: today,
        tokenNumber: 24,
        status: TokenStatus.called,
        createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
      ),
    ];

    _saveData();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    if (_currentUser != null) {
      await prefs.setString(_kUserProfileKey, jsonEncode(_currentUser!.toJson()));
    }

    await prefs.setString(_kClinicsKey, jsonEncode(_clinics.map((e) => e.toJson()).toList()));
    await prefs.setString(_kDoctorsKey, jsonEncode(_doctors.map((e) => e.toJson()).toList()));

    final queuesMapDecoded = _queues.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_kQueuesKey, jsonEncode(queuesMapDecoded));

    await prefs.setString(_kTokensKey, jsonEncode(_tokens.map((e) => e.toJson()).toList()));
  }

  Future<void> setUserProfile(UserProfile profile) async {
    _currentUser = profile;
    await _saveData();
    notifyListeners();
  }

  void switchRole(UserRole role) {
    if (_currentUser != null) {
      _currentUser = UserProfile(
        userId: _currentUser!.userId,
        name: _currentUser!.name,
        phone: _currentUser!.phone,
        age: _currentUser!.age,
        gender: _currentUser!.gender,
        role: role,
        createdAt: _currentUser!.createdAt,
      );
      _saveData();
      notifyListeners();
    }
  }

  Clinic? findClinicById(String inputClinicId) {
    final cleanInput = inputClinicId.trim().toUpperCase().replaceAll('-', '');
    final match = _clinics.where((c) {
      final cleanId = c.clinicId.replaceAll('-', '').toUpperCase();
      return cleanId == cleanInput && c.status == ClinicStatus.approved;
    });
    return match.isNotEmpty ? match.first : null;
  }

  List<Doctor> getDoctorsForClinic(String clinicId) {
    return _doctors.where((d) => d.clinicId == clinicId).toList();
  }

  QueueState getQueueState(String clinicId, String doctorId, String date) {
    final queueKey = '${clinicId}__${doctorId}__$date';
    if (!_queues.containsKey(queueKey)) {
      _queues[queueKey] = QueueState(
        queueId: queueKey,
        clinicId: clinicId,
        doctorId: doctorId,
        date: date,
        currentToken: 0,
        lastToken: 0,
        isActive: false,
        updatedAt: DateTime.now(),
      );
    }
    return _queues[queueKey]!;
  }

  Future<void> toggleQueueActive(String clinicId, String doctorId, String date, bool active) async {
    final q = getQueueState(clinicId, doctorId, date);
    q.isActive = active;
    q.updatedAt = DateTime.now();
    await _saveData();
    notifyListeners();
  }

  TokenModel? getActiveTokenForUser({
    required String userId,
    required String clinicId,
    required String doctorId,
    required String date,
  }) {
    final matches = _tokens.where((t) =>
        t.userId == userId &&
        t.clinicId == clinicId &&
        t.doctorId == doctorId &&
        t.date == date &&
        (t.status == TokenStatus.waiting || t.status == TokenStatus.called));

    return matches.isNotEmpty ? matches.first : null;
  }

  Future<TokenModel> joinQueue({
    required String clinicId,
    required String doctorId,
    required String date,
  }) async {
    if (_currentUser == null) throw Exception('User not authenticated');

    final q = getQueueState(clinicId, doctorId, date);
    if (!q.isActive) {
      throw Exception('Queue currently closed. Doctor is currently unavailable.');
    }

    final existingToken = getActiveTokenForUser(
      userId: _currentUser!.userId,
      clinicId: clinicId,
      doctorId: doctorId,
      date: date,
    );

    if (existingToken != null) {
      return existingToken;
    }

    q.lastToken += 1;
    final newNumber = q.lastToken;

    if (q.currentToken == 0) {
      q.currentToken = newNumber;
    }
    q.updatedAt = DateTime.now();

    final newToken = TokenModel(
      tokenId: 'TOK-${const Uuid().v4().substring(0, 8)}',
      clinicId: clinicId,
      doctorId: doctorId,
      userId: _currentUser!.userId,
      patientName: _currentUser!.name,
      patientPhone: _currentUser!.phone,
      date: date,
      tokenNumber: newNumber,
      status: TokenStatus.waiting,
      createdAt: DateTime.now(),
    );

    _tokens.add(newToken);

    // Call Railway FastAPI backend to register token
    try {
      await ApiService.createToken(newToken.toJson());
    } catch (e) {
      debugPrint('[QueueStore] ApiService Create Token Error: $e');
    }

    await _saveData();
    notifyListeners();

    return newToken;
  }

  List<TokenModel> getTokensForQueue(String clinicId, String doctorId, String date) {
    return _tokens
        .where((t) => t.clinicId == clinicId && t.doctorId == doctorId && t.date == date)
        .toList()
      ..sort((a, b) => a.tokenNumber.compareTo(b.tokenNumber));
  }

  Future<void> callNextToken(String clinicId, String doctorId, String date) async {
    final q = getQueueState(clinicId, doctorId, date);
    final list = getTokensForQueue(clinicId, doctorId, date);

    final currentTokens = list.where((t) => t.status == TokenStatus.called);
    for (var t in currentTokens) {
      t.status = TokenStatus.completed;
      t.completedAt = DateTime.now();
    }

    final waitingTokens = list.where((t) => t.status == TokenStatus.waiting).toList();
    if (waitingTokens.isNotEmpty) {
      final nextToken = waitingTokens.first;
      nextToken.status = TokenStatus.called;
      nextToken.calledAt = DateTime.now();
      q.currentToken = nextToken.tokenNumber;
    } else {
      q.currentToken = q.lastToken > 0 ? q.lastToken : 0;
    }

    q.updatedAt = DateTime.now();
    await _saveData();
    notifyListeners();
  }

  Future<void> skipToken(String tokenId) async {
    final index = _tokens.indexWhere((t) => t.tokenId == tokenId);
    if (index == -1) return;

    final token = _tokens[index];
    token.status = TokenStatus.skipped;
    token.skippedAt = DateTime.now();

    final q = getQueueState(token.clinicId, token.doctorId, token.date);

    if (q.currentToken == token.tokenNumber) {
      final queueTokens = getTokensForQueue(token.clinicId, token.doctorId, token.date);
      final nextWaiting = queueTokens.where((t) => t.status == TokenStatus.waiting);
      if (nextWaiting.isNotEmpty) {
        q.currentToken = nextWaiting.first.tokenNumber;
      }
    }

    q.updatedAt = DateTime.now();
    await _saveData();
    notifyListeners();
  }

  Future<void> callAgainToken(String tokenId) async {
    final index = _tokens.indexWhere((t) => t.tokenId == tokenId);
    if (index == -1) return;

    final token = _tokens[index];
    final q = getQueueState(token.clinicId, token.doctorId, token.date);

    final list = getTokensForQueue(token.clinicId, token.doctorId, token.date);
    for (var t in list.where((x) => x.status == TokenStatus.called)) {
      t.status = TokenStatus.completed;
      t.completedAt = DateTime.now();
    }

    token.status = TokenStatus.called;
    token.calledAt = DateTime.now();
    q.currentToken = token.tokenNumber;
    q.updatedAt = DateTime.now();

    await _saveData();
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserProfileKey);
    notifyListeners();
  }

  Future<void> clearAllData() async {
    _currentUser = null;
    _tokens = [];
    _queues = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
