import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/violation.dart';
import '../models/notification_model.dart';

class DatabaseService {
  static const String _baseUrl = 'http://10.131.40.11:5277';

  static void initialize() {}

  // ── Token helpers ────────────────────────────────────────────────────────────
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> _saveStudentNo(String studentNo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_no', studentNo);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('student_no');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── FCM TOKEN ────────────────────────────────────────────────────────────────
  static Future<void> _saveTokenToBackend() async {
    try {
      final jwtToken = await _getToken();
      if (jwtToken == null) return;

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      await http.post(
        Uri.parse('$_baseUrl/api/notifications/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({'FCMToken': fcmToken}),
      );
    } catch (e) {}
  }

  // ── AUTH ─────────────────────────────────────────────────────────────────────

  // POST /api/auth/login
  static Future<Map<String, dynamic>?> login(
    String username,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 200) {
        await _saveToken(data['token']);
        await _saveStudentNo('');
        await _saveTokenToBackend();

        final decodedToken = _decodeJwt(data['token']);
        final name = decodedToken['name']?.toString() ?? username;
        final id =
            decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier']
                ?.toString() ??
            '';
        final studentNo = decodedToken['studentNo']?.toString() ?? '';
        final roleStr = (data['role'] as String).toLowerCase();

        return {
          'user': User(
            id: id,
            username: username,
            password: '',
            name: name,
            role: _parseRole(roleStr),
            studentNo: studentNo,
          ),
        };
      }
      // return the API's actual message
      return {'error': data['message'] ?? 'Invalid username or password'};
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  static Map<String, dynamic> _decodeJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    String payload = parts[1];
    payload = payload.replaceAll('-', '+').replaceAll('_', '/');
    switch (payload.length % 4) {
      case 0:
        break;
      case 2:
        payload += '==';
        break;
      case 3:
        payload += '=';
        break;
    }
    final decoded = utf8.decode(base64.decode(payload));
    return jsonDecode(decoded);
  }

  // POST /api/auth/register
  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String name,
    required UserRole role,
    String? gradeSection,
    String? contactNumber,
    String? studentNo,
    String? email,
    String? gender,
    String? dateOfBirth,
    String? address,
    String? course,
    String? year,
  }) async {
    try {
      String? yearNum;
      if (year != null) {
        yearNum = year.replaceAll(RegExp(r'[^0-9]'), '');
      }

      final nameParts = name.trim().split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1
          ? nameParts.skip(1).join(' ')
          : firstName;

      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'email': email ?? '$username@aclc.com',
          'gender': (gender ?? 'male').toLowerCase(),
          'dateOfBirth': dateOfBirth ?? '2000-01-01',
          'address': address ?? '',
          'number': contactNumber ?? '',
          'role': role.name,
          'course': course,
          'year': yearNum,
          'studentNo': studentNo,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 200) {
        return {
          'success': true,
          'user': User(
            id: '',
            username: username,
            password: '',
            name: name,
            role: role,
            contactNumber: contactNumber,
            studentNo: studentNo,
          ),
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Registration failed. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // ── STUDENT ENDPOINTS ────────────────────────────────────────────────────────

  // GET /api/student/violations
  static Future<Map<String, dynamic>> getMyViolations() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/student/violations'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 200) {
        final d = data['data'];
        final List violationsList = d['violations'] ?? [];
        return {
          'student_no': d['student_no'] ?? '',
          'name': d['name'] ?? '',
          'total_violations': d['total_violations'] ?? 0,
          'pending': d['pending'] ?? 0,
          'approved': d['approved'] ?? 0,
          'rejected': d['rejected'] ?? 0,
          'warning_level': d['warning_level'] ?? 'green',
          'violations': violationsList
              .map(
                (v) => Violation(
                  id: v['id'].toString(),
                  studentId: d['student_no'] ?? '',
                  type: _parseViolationType(v['type']),
                  date: DateTime.tryParse(v['date'] ?? '') ?? DateTime.now(),
                  remarks: v['details'] ?? '',
                  status: _parseStatus(v['status']),
                  offenseCount: 1,
                  reportedBy: v['recorded_by'] ?? '',
                  violationName: v['type'] ?? '',
                  severity: v['severity'] ?? '',
                  appealStatus: v['appeal_status'],
                  appealRemarks: v['appeal_remarks'],
                ),
              )
              .toList(),
        };
      }
      return {};
    } catch (e) {
      throw Exception('Failed to get my violations: $e');
    }
  }

  // GET /api/student/profile
  static Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/student/profile'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 200) {
        return Map<String, dynamic>.from(data['data']);
      }
      return {};
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  static Future<void> uploadProfilePhoto(String base64Photo) async {
    final headers = await _authHeaders();
    final response = await http.put(
      Uri.parse('$_baseUrl/api/student/profile/photo'),
      headers: headers,
      body: jsonEncode({'base64Photo': base64Photo}),
    );
    if (response.statusCode != 200) {
      throw Exception('Upload failed');
    }
  }

  // GET /api/student/qrcode
  static Future<String?> getMyQrCode() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/student/qrcode'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 200) {
        return data['data']['qr_code'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get QR code: $e');
    }
  }

  // POST /api/student/violations/{id}/appeal
  static Future<bool> submitAppeal(
    String violationId,
    String appealText,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/student/violations/$violationId/appeal'),
        headers: headers,
        body: jsonEncode({'AppealText': appealText}),
      );
      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['status'] == 200;
    } catch (e) {
      throw Exception('Failed to submit appeal: $e');
    }
  }

  // ── GUARD ENDPOINTS ──────────────────────────────────────────────────────────

  // GET /api/guard/student/validate?studentNo=xxx
  static Future<Map<String, dynamic>?> validateStudent(String studentNo) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/guard/student/validate?studentNo=$studentNo'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 200) {
        final d = data['data'];
        return {
          'student_no': d['student_no'],
          'name': d['name'],
          'violation_count': d['violation_count'],
          'warning_level': d['warning_level'],
          'violations': d['violations'] ?? [],
          'profile_photo': d['profile_photo'] ?? '',
        };
      }
      return null;
    } catch (e) {
      throw Exception('Failed to validate student: $e');
    }
  }

  // POST /api/guard/student/violation
  static Future<Map<String, dynamic>> addViolation(Violation violation) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/guard/student/violation'),
        headers: headers,
        body: jsonEncode({
          'studentNo': violation.studentId,
          'violationType':
              violation.violationName ?? _violationTypeToString(violation.type),
          'details':
              (violation.remarks != null &&
                  violation.remarks!.trim().isNotEmpty)
              ? violation.remarks!.trim()
              : 'No additional details',
          'severity': violation.severity ?? 'minor',
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 200) {
        final d = data['data'];
        return {
          'student_no': d['student_no'],
          'name': d['name'],
          'new_violation_count': d['new_violation_count'],
          'new_warning_level': d['new_warning_level'],
        };
      }
      throw Exception(data['message'] ?? 'Failed to record violation');
    } catch (e) {
      throw Exception('Failed to add violation: $e');
    }
  }

  // GET /api/guard/violations/summary?StartDate=xxx&EndDate=xxx
  static Future<Map<String, dynamic>> getViolationSummary(
    String startDate,
    String endDate,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/api/guard/violations/summary?StartDate=$startDate&EndDate=$endDate',
        ),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 200) {
        final d = data['data'];
        return {
          'totalViolations': d['totalViolations'] ?? 0,
          'topViolation': d['topViolation'] ?? 'N/A',
          'startDate': d['startDate'] ?? startDate,
          'endDate': d['endDate'] ?? endDate,
        };
      }
      return {'totalViolations': 0, 'topViolation': 'N/A'};
    } catch (e) {
      throw Exception('Failed to get summary: $e');
    }
  }

  // GET /api/guard/students
  static Future<List<User>> getAllStudents() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/guard/students'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 200) {
        final List students = data['data'];
        return students
            .map(
              (s) => User(
                id: s['student_no'] ?? '',
                username: s['student_no'] ?? '',
                password: '',
                name: s['name'] ?? '',
                role: UserRole.student,
                gradeSection: '${s['course'] ?? ''} - ${s['year'] ?? ''}',
                studentNo: s['student_no'] ?? '',
                profilePhoto: s['profile_photo'] ?? '',
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get students: $e');
    }
  }

  // GET /api/guard/students/exist?studentNo=xxx
  static Future<bool> checkStudentExists(String studentNo) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/guard/students/exist?studentNo=$studentNo'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['status'] == 200;
    } catch (e) {
      return false;
    }
  }

  // GET violations for a specific student (reuses validate endpoint)
  static Future<List<Violation>> getViolationsByStudent(
    String studentNo,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/guard/student/validate?studentNo=$studentNo'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 200) {
        final List violations = data['data']['violations'] ?? [];
        return violations
            .map(
              (v) => Violation(
                id: v['id']?.toString() ?? '',
                studentId: studentNo,
                type: _parseViolationType(v['type']),
                date: DateTime.tryParse(v['date'] ?? '') ?? DateTime.now(),
                remarks: v['details'] ?? '',
                status: _parseStatus(v['status']),
                offenseCount: 1,
                reportedBy: v['recorded_by'] ?? '',
                violationName: v['type'] ?? '',
                severity: v['severity'] ?? '',
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get student violations: $e');
    }
  }

  // GET /api/sao/students/{studentNo}/report
  // SAO violation endpoints
  static Future<List<Violation>> getAllViolations() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/guidance/violations/by-status'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 200) {
        final List groups = data['data'];
        final allViolations = <Violation>[];
        for (final group in groups) {
          final List violations = group['violations'] ?? [];
          allViolations.addAll(_mapViolations(violations));
        }
        return allViolations;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get violations: $e');
    }
  }

  // GET /api/guidance/violations/by-status — pending only
  static Future<List<Violation>> getGuidancePendingViolations() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/guidance/violations/by-status'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 200) {
        final List groups = data['data'];
        for (final group in groups) {
          if ((group['status'] ?? '').toString().toLowerCase() == 'pending') {
            return _mapViolations(group['violations'] ?? []);
          }
        }
        return [];
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get pending violations: $e');
    }
  }

  // GET /api/guidance/violations/by-severity
  static Future<List<Map<String, dynamic>>>
  getGuidanceViolationsBySeverity() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/guidance/violations/by-severity'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 200) {
        final List groups = data['data'];
        return groups.map((g) => Map<String, dynamic>.from(g)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get violations by severity: $e');
    }
  }

  // PUT /api/sao/students/{studentNo}/recommend-dismiss
  static Future<bool> recommendDismiss(String studentNo) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse(
          '$_baseUrl/api/guidance/students/$studentNo/recommend-dismiss',
        ),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['status'] == 200;
    } catch (e) {
      throw Exception('Failed to recommend dismissal: $e');
    }
  }

  // ── SAO ENDPOINTS ────────────────────────────────────────────────────────────

  // GET /api/sao/violations
  static Future<List<Violation>> getSaoViolations() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/sao/violations'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 200) {
        return _mapViolations(data['data']);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get SAO violations: $e');
    }
  }

  // GET /api/sao/violations/by-status/{status}
  static Future<List<Violation>> getSaoViolationsByStatus(String status) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/sao/violations/by-status/$status'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 200) {
        return _mapViolations(data['data']);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get violations by status: $e');
    }
  }

  // GET /api/sao/violations/summary
  static Future<Map<String, dynamic>> getSaoSummary() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/sao/violations/summary'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 200) {
        return Map<String, dynamic>.from(data['data']);
      }
      return {};
    } catch (e) {
      throw Exception('Failed to get SAO summary: $e');
    }
  }

  // PUT /api/sao/violations/{id}/approve
  static Future<void> approveViolation(String violationId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/api/sao/violations/$violationId/approve'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['status'] != 200) {
        throw Exception(data['message'] ?? 'Failed to approve violation');
      }
    } catch (e) {
      throw Exception('Failed to approve violation: $e');
    }
  }

  // PUT /api/sao/violations/{id}/reject
  static Future<void> rejectViolation(String violationId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/api/sao/violations/$violationId/reject'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['status'] != 200) {
        throw Exception(data['message'] ?? 'Failed to reject violation');
      }
    } catch (e) {
      throw Exception('Failed to reject violation: $e');
    }
  }

  // DELETE /api/sao/violations/{id}
  static Future<void> deleteSaoViolation(String violationId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/sao/violations/$violationId'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['status'] != 200) {
        throw Exception(data['message'] ?? 'Failed to delete violation');
      }
    } catch (e) {
      throw Exception('Failed to delete violation: $e');
    }
  }

  // PUT /api/sao/violations/{id}/appeal/review
  static Future<bool> saoReviewAppeal(
    String violationId,
    String appealStatus,
    String appealRemarks,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/api/sao/violations/$violationId/appeal/review'),
        headers: headers,
        body: jsonEncode({
          'AppealStatus': appealStatus,
          'AppealRemarks': appealRemarks,
        }),
      );
      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['status'] == 200;
    } catch (e) {
      throw Exception('Failed to review appeal: $e');
    }
  }

  // GET /api/sao/violations/appeals
  static Future<List<Map<String, dynamic>>> getSaoAppeals() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/sao/violations/appeals'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 200) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get appeals: $e');
    }
  }

  // GET /api/sao/students/{studentNo}/report
  static Future<Map<String, dynamic>?> getStudentReport(
    String studentNo,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/sao/students/$studentNo/report'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 200) {
        return Map<String, dynamic>.from(data['data']);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get student report: $e');
    }
  }

  // PUT /api/sao/students/{studentNo}/dismiss
  static Future<bool> dismissStudent(String studentNo) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/api/sao/students/$studentNo/dismiss'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['status'] == 200;
    } catch (e) {
      throw Exception('Failed to dismiss student: $e');
    }
  }

  // PUT /api/sao/students/{studentNo}/cancel-dismiss
  static Future<bool> cancelDismiss(String studentNo) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/api/sao/students/$studentNo/cancel-dismiss'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['status'] == 200;
    } catch (e) {
      throw Exception('Failed to cancel dismissal: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingDismissals() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/sao/students/pending-dismissal'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // handle both wrapped and unwrapped responses
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // GET /api/sao/students/dismissed
  static Future<List<Map<String, dynamic>>> getDismissedStudents() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/sao/students/dismissed'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // GET /api/sao/users
  static Future<List<User>> getAllUsers() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/sao/users'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 200) {
        final List users = data['data'];
        return users
            .map(
              (u) => User(
                id: u['id'].toString(),
                username: u['username'],
                password: '',
                name: u['name'],
                role: _parseRole((u['role'] as String).toLowerCase()),
                contactNumber: u['contact_number'],
                gradeSection: '${u['course'] ?? ''} - ${u['year'] ?? ''}',
                studentNo: u['student_no'] ?? '',
                profilePhoto: u['profile_photo'] ?? '',
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  // GET /api/sao/users/{id}
  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/sao/users/$userId'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 200) {
        return Map<String, dynamic>.from(data['data']);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // PUT /api/sao/users/{id}
  static Future<void> updateUser(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/api/sao/users/$userId'),
        headers: headers,
        body: jsonEncode(userData),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['status'] != 200) {
        throw Exception(data['message'] ?? 'Failed to update user');
      }
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // DELETE /api/sao/users/{id}
  static Future<void> deleteUser(String userId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/sao/users/$userId'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['status'] != 200) {
        throw Exception(data['message'] ?? 'Failed to delete user');
      }
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // ── NOTIFICATIONS ────────────────────────────────────────────────────────────

  static Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/notifications'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List data = body['data'] ?? [];
        return data.map((e) => NotificationModel.fromMap(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // PUT /api/notifications/{id}/read
  static Future<void> markNotificationAsRead(int id) async {
    try {
      await http.put(
        Uri.parse('$_baseUrl/api/notifications/$id/read'),
        headers: await _authHeaders(),
      );
    } catch (e) {
      // Silently fail — notification read status is non-critical
    }
  }

  // PUT /api/notifications/read-all
  static Future<void> markAllNotificationsAsRead() async {
    try {
      await http.put(
        Uri.parse('$_baseUrl/api/notifications/read-all'),
        headers: await _authHeaders(),
      );
    } catch (e) {
      // Silently fail — notification read status is non-critical
    }
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────────

  static List<Violation> _mapViolations(List violations) {
    return violations
        .map(
          (v) => Violation(
            id: v['id'].toString(),
            studentId: v['student_no'] ?? '',
            type: _parseViolationType(v['type']),
            date: DateTime.tryParse(v['date'] ?? '') ?? DateTime.now(),
            remarks: v['details'] ?? '',
            status: _parseStatus(v['status']),
            offenseCount: 1,
            reportedBy: v['recorded_by'] ?? '',
            violationName: v['type'] ?? '',
            severity: v['severity'] ?? '',
          ),
        )
        .toList();
  }

  static UserRole _parseRole(String roleStr) {
    switch (roleStr) {
      case 'guard':
        return UserRole.guard;
      case 'student':
        return UserRole.student;
      case 'sao':
        return UserRole.sao;      default:
        return UserRole.student;
    }
  }

  static ViolationType _parseViolationType(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('uniform')) return ViolationType.noUniform;
    if (t.contains('piercing') || t.contains('earring'))
      return ViolationType.piercing;
    if (t.contains('hair') || t.contains('color'))
      return ViolationType.coloredHair;
    return ViolationType.noId;
  }

  static String _violationTypeToString(ViolationType type) {
    switch (type) {
      case ViolationType.noId:
        return 'No ID';
      case ViolationType.noUniform:
        return 'No Uniform';
      case ViolationType.piercing:
        return 'Piercing';
      case ViolationType.coloredHair:
        return 'Colored Hair';
    }
  }

  static ViolationStatus _parseStatus(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'approved':
        return ViolationStatus.referredToSAO;
      case 'rejected':
        return ViolationStatus.cleared;
      case 'pending':
        return ViolationStatus.warning;
      default:
        return ViolationStatus.warning;
    }
  }

  // ── Legacy stubs (kept for compatibility) ────────────────────────────────────
  static Future<List<Violation>> getStudentViolations(String studentNo) async {
    final result = await getMyViolations();
    return result['violations'] ?? [];
  }

  static Future<void> updateViolationStatus(
    String violationId,
    ViolationStatus status,
  ) async {
    if (status == ViolationStatus.referredToSAO) {
      await approveViolation(violationId);
    } else if (status == ViolationStatus.cleared) {
      await rejectViolation(violationId);
    }
  }
}
