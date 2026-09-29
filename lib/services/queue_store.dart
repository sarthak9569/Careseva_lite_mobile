import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/clinic.dart';
import '../models/doctor.dart';
import '../models/queue_state.dart';
import '../models/token_model.dart';
import '../models/user_profile.dart';

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

  UserProfile? get currentUser => _currentUser;
  List<Clinic> get clinics => _clinics;
  List<Doctor> get doctors => _doctors;
  List<TokenModel> get tokens => _tokens;

  QueueStore() {
    _initFirestoreAndLoadData();
  }

  Future<void> _initFirestoreAndLoadData() async {
    await _loadLocalData();

    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      final firestore = FirebaseFirestore.instance;
      debugPrint('[QueueStore Live] Connected to Firestore project: ${firestore.app.options.projectId}');

      // 1. Listen to Clinics Collection
      firestore.collection('clinics').snapshots().listen((snapshot) {
        _clinics = snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['clinicId'] = doc.id;
          return Clinic.fromJson(data);
        }).toList();
        _saveData();
        notifyListeners();
      }, onError: (e) => debugPrint('[QueueStore Firestore Error] Clinics stream: $e'));

      // 2. Listen to Doctors Collection
      firestore.collection('doctors').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          _doctors = snapshot.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['doctorId'] = doc.id;
            return Doctor.fromJson(data);
          }).toList();
          _saveData();
          notifyListeners();
        }
      }, onError: (e) => debugPrint('[QueueStore] Firestore Doctors Error: $e'));

      // 3. Listen to Queues Collection
      firestore.collection('queues').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          for (var doc in snapshot.docs) {
            final data = Map<String, dynamic>.from(doc.data());
            data['queueId'] = doc.id;
            _queues[doc.id] = QueueState.fromJson(data);
          }
          _saveData();
          notifyListeners();
        }
      }, onError: (e) => debugPrint('[QueueStore] Firestore Queues Error: $e'));

      // 4. Listen to Tokens Collection
      firestore.collection('tokens').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          _tokens = snapshot.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['tokenId'] = doc.id;
            return TokenModel.fromJson(data);
          }).toList();
          _saveData();
          notifyListeners();
        }
      }, onError: (e) => debugPrint('[QueueStore] Firestore Tokens Error: $e'));
    } catch (e) {
      debugPrint('[QueueStore] Firestore Local Mode: $e');
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
      Clinic(
        clinicId: 'CS-9X42M',
        clinicRefNum: 'REF-9X42M',
        name: 'City Care Polyclinic',
        phone: '+91 98123 45678',
        email: 'info@citycare.org',
        address: '55 Park Street, Near Metro Station',
        city: 'Delhi',
        state: 'Delhi',
        pincode: '110001',
        latitude: 28.6139,
        longitude: 77.2090,
        speciality: 'General Medicine & Pediatrics',
        operatingHours: '10:00 AM - 07:00 PM',
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
    try {
      await FirebaseFirestore.instance.collection('users').doc(profile.userId).set(profile.toJson());
    } catch (_) {}
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
      try {
        FirebaseFirestore.instance.collection('users').doc(_currentUser!.userId).set(_currentUser!.toJson());
      } catch (_) {}
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

    try {
      await FirebaseFirestore.instance.collection('queues').doc(q.queueId).set(q.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[QueueStore] Firestore Toggle Queue Error: $e');
    }

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

  /// Atomic Token Generation with Firestore Transaction & Duplicate Check
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

    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('queues').doc(q.queueId).set(q.toJson());
      await firestore.collection('tokens').doc(newToken.tokenId).set(newToken.toJson());
    } catch (e) {
      debugPrint('[QueueStore] Firestore Join Queue Sync: $e');
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
      try {
        FirebaseFirestore.instance.collection('tokens').doc(t.tokenId).update({
          'status': TokenStatus.completed.name,
          'completedAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }

    final waitingTokens = list.where((t) => t.status == TokenStatus.waiting).toList();
    if (waitingTokens.isNotEmpty) {
      final nextToken = waitingTokens.first;
      nextToken.status = TokenStatus.called;
      nextToken.calledAt = DateTime.now();
      q.currentToken = nextToken.tokenNumber;
      try {
        FirebaseFirestore.instance.collection('tokens').doc(nextToken.tokenId).update({
          'status': TokenStatus.called.name,
          'calledAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    } else {
      q.currentToken = q.lastToken > 0 ? q.lastToken : 0;
    }

    q.updatedAt = DateTime.now();
    try {
      FirebaseFirestore.instance.collection('queues').doc(q.queueId).set(q.toJson());
    } catch (_) {}

    await _saveData();
    notifyListeners();
  }

  Future<void> skipToken(String tokenId) async {
    final index = _tokens.indexWhere((t) => t.tokenId == tokenId);
    if (index == -1) return;

    final token = _tokens[index];
    token.status = TokenStatus.skipped;
    token.skippedAt = DateTime.now();

    try {
      FirebaseFirestore.instance.collection('tokens').doc(token.tokenId).update({
        'status': TokenStatus.skipped.name,
        'skippedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    final q = getQueueState(token.clinicId, token.doctorId, token.date);

    if (q.currentToken == token.tokenNumber) {
      final queueTokens = getTokensForQueue(token.clinicId, token.doctorId, token.date);
      final nextWaiting = queueTokens.where((t) => t.status == TokenStatus.waiting);
      if (nextWaiting.isNotEmpty) {
        q.currentToken = nextWaiting.first.tokenNumber;
      }
    }

    q.updatedAt = DateTime.now();
    try {
      FirebaseFirestore.instance.collection('queues').doc(q.queueId).set(q.toJson());
    } catch (_) {}

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
      try {
        FirebaseFirestore.instance.collection('tokens').doc(t.tokenId).update({
          'status': TokenStatus.completed.name,
          'completedAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }

    token.status = TokenStatus.called;
    token.calledAt = DateTime.now();
    q.currentToken = token.tokenNumber;

    try {
      FirebaseFirestore.instance.collection('tokens').doc(token.tokenId).update({
        'status': TokenStatus.called.name,
        'calledAt': DateTime.now().toIso8601String(),
      });
      FirebaseFirestore.instance.collection('queues').doc(q.queueId).set(q.toJson());
    } catch (_) {}

    q.updatedAt = DateTime.now();
    await _saveData();
    notifyListeners();
  }
}
