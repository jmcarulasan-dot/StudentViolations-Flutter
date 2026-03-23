import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/violation.dart';

class DatabaseService {
  // ── Update this IP whenever you switch WiFi networks ─────────────────────
  static const String _baseUrl = 'http://192.168.254.148:5277';

  static void initialize() {}

  // ── Token helpers ─────────────────────────────────────────────────────────
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

  // ════════════════════════════════════════════════════════════════════════════
  // AUTH
  // ════════════════════════════════════════════════════════════════════════════

  // POST /login
  static Future<User?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        await _saveToken(data['data']['token']);
        final studentNo = data['data']['student_no'] ?? '';
        await _saveStudentNo(studentNo);
        final roleStr = (data['data']['role'] as String).toLowerCase();
        return User(
          id: data['data']['id'].toString(),
          username: data['data']['username'],
          password: '',
          name: data['data']['name'],
          role: _parseRole(roleStr),
          studentNo: studentNo,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // POST /register
  static Future<User?> register({
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
      final nameParts = name.trim().split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email ?? '$username@aclc.com',
          'firstName': firstName,
          'lastName': lastName,
          'dateOfBirth': dateOfBirth ?? '2000-01-01',
          'gender': gender ?? 'Male',
          'address': address ?? '',
          'number': contactNumber ?? '',
          'role': role.name,
          'course': course,
          'year': year,
          'studentNo': studentNo,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return User(
          id: '',
          username: username,
          password: '',
          name: name,
          role: role,
          contactNumber: contactNumber,
          studentNo: studentNo,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STUDENT ENDPOINTS
  // ════════════════════════════════════════════════════════════════════════════

  // GET /api/student/violations
  // Returns own violations + pending/approved/rejected counts + warning level
  static Future<Map<String, dynamic>> getMyViolations() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/student/violations'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        final d = data['data'];
        final List violationsList = d['violations'];
        return {
          'student_no':       d['student_no'] ?? '',
          'name':             d['name'] ?? '',
          'total_violations': d['total_violations'] ?? 0,
          'pending':          d['pending'] ?? 0,
          'approved':         d['approved'] ?? 0,
          'rejected':         d['rejected'] ?? 0,
          'warning_level':    d['warning_level'] ?? 'green',
          'violations': violationsList.map((v) => Violation(
            id:            v['id'].toString(),
            studentId:     d['student_no'] ?? '',
            type:          _parseViolationType(v['type']),
            date:          DateTime.tryParse(v['date'] ?? '') ?? DateTime.now(),
            remarks:       v['details'] ?? '',
            status:        _parseStatus(v['status']),
            offenseCount:  1,
            reportedBy:    v['recorded_by'] ?? '',
            violationName: v['type'] ?? '',
            severity:      v['severity'] ?? '',
          )).toList(),
        };
      }
      return {};
    } catch (e) {
      throw Exception('Failed to get my violations: $e');
    }
  }

  // GET /api/student/profile
  // Returns own profile + warning level
  static Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/student/profile'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return Map<String, dynamic>.from(data['data']);
      }
      return {};
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  // GET /api/student/qrcode
  // Returns own QR code as Base64 string
  static Future<String?> getMyQrCode() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/student/qrcode'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return data['data']['qr_code'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get QR code: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // GUARD ENDPOINTS
  // ════════════════════════════════════════════════════════════════════════════

  // GET /api/guard/students
  // Returns all registered students — used for dropdown
  static Future<List<User>> getAllStudents() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/guard/students'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List students = data['data'];
        return students.map((s) => User(
          id:           s['student_no'] ?? '',
          username:     s['student_no'] ?? '',
          password:     '',
          name:         s['name'] ?? '',
          role:         UserRole.student,
          gradeSection: '${s['course'] ?? ''} - ${s['year'] ?? ''}',
          studentNo:    s['student_no'] ?? '',
        )).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get students: $e');
    }
  }

  // GET /api/guard/students/{studentNo}
  // Search specific student by StudentNo
  static Future<Map<String, dynamic>?> getStudentByStudentNo(String studentNo) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/guard/students/$studentNo'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return Map<String, dynamic>.from(data['data']);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get student: $e');
    }
  }

  // GET /api/guard/student/validate?studentNo=xxx
  // Validate student by QR code — returns warning level
  static Future<Map<String, dynamic>?> validateStudent(String studentNo) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/guard/student/validate?studentNo=$studentNo'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return {
          'student_no':      data['student_no'],
          'name':            data['name'],
          'violation_count': data['violation_count'],
          'warning_level':   data['warning_level'],
        };
      }
      return null;
    } catch (e) {
      throw Exception('Failed to validate student: $e');
    }
  }

  // POST /api/guard/student/violation
  // Record a new violation
  static Future<Map<String, dynamic>> addViolation(Violation violation) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/guard/student/violation'),
        headers: headers,
        body: jsonEncode({
          'studentNo':     violation.studentId,
          'violationType': violation.violationName ?? _violationTypeToString(violation.type),
          'details':       violation.remarks ?? '',
          'severity':      violation.severity ?? 'minor',
          'guardId':       violation.reportedBy ?? '',
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return {
          'student_no':          data['student_no'],
          'name':                data['name'],
          'new_violation_count': data['new_violation_count'],
          'new_warning_level':   data['new_warning_level'],
        };
      }
      throw Exception(data['message'] ?? 'Failed to record violation');
    } catch (e) {
      throw Exception('Failed to add violation: $e');
    }
  }

  // GET /api/guard/violations/student?studentNo=xxx
  // View all violations of a specific student
  static Future<List<Violation>> getViolationsByStudent(String studentNo) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/guard/violations/student?studentNo=$studentNo'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List violations = data['violations'];
        return violations.map((v) => Violation(
          id:            v['id']?.toString() ?? '',
          studentId:     studentNo,
          type:          _parseViolationType(v['type']),
          date:          DateTime.tryParse(v['date'] ?? '') ?? DateTime.now(),
          remarks:       v['details'] ?? '',
          status:        _parseStatus(v['status']),
          offenseCount:  1,
          reportedBy:    v['recorded_by'] ?? '',
          violationName: v['type'] ?? '',
          severity:      v['severity'] ?? '',
        )).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get student violations: $e');
    }
  }

  // GET /api/guard/violations/summary?StartDate=xxx&EndDate=xxx
  // Returns total violations and top violation in a date range
  static Future<Map<String, dynamic>> getViolationSummary(
      String startDate, String endDate) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/guard/violations/summary?StartDate=$startDate&EndDate=$endDate'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return {
          'totalViolations': data['totalViolations'] ?? 0,
          'topViolation':    data['topViolation'] ?? 'N/A',
          'startDate':       data['startDate'],
          'endDate':         data['endDate'],
        };
      }
      return {'totalViolations': 0, 'topViolation': 'N/A'};
    } catch (e) {
      throw Exception('Failed to get summary: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // GUIDANCE ENDPOINTS
  // ════════════════════════════════════════════════════════════════════════════

  // GET /api/guidance/students
  // Returns all students
  static Future<List<User>> getGuidanceStudents() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/guidance/students'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List students = data['data'];
        return students.map((s) => User(
          id:           s['student_no'] ?? '',
          username:     s['student_no'] ?? '',
          password:     '',
          name:         s['name'] ?? '',
          role:         UserRole.student,
          gradeSection: '${s['course'] ?? ''} - ${s['year'] ?? ''}',
          studentNo:    s['student_no'] ?? '',
        )).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get guidance students: $e');
    }
  }

  // GET /api/guidance/students/{studentNo}/report
  // Returns full student profile + all violations + warning level
  static Future<Map<String, dynamic>?> getGuidanceStudent(String studentNo) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/guidance/students/$studentNo/report'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return Map<String, dynamic>.from(data['data']);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get student report: $e');
    }
  }

  // GET /api/guidance/violations
  // Returns all violations
  static Future<List<Violation>> getAllViolations() async {
    try {
      final headers = await _authHeaders();
      // Guidance has no plain GET /violations — use pending endpoint
      // to show all violations that need attention
      final response = await http.get(
        Uri.parse('$_baseUrl/api/guidance/violations/pending'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List violations = data['data'];
        return violations.map((v) => Violation(
          id:            v['id'].toString(),
          studentId:     v['student_no'] ?? '',
          type:          _parseViolationType(v['type']),
          date:          DateTime.tryParse(v['date'] ?? '') ?? DateTime.now(),
          remarks:       v['details'] ?? '',
          status:        _parseStatus(v['status']),
          offenseCount:  1,
          reportedBy:    v['recorded_by'] ?? '',
          violationName: v['type'] ?? '',
          severity:      v['severity'] ?? '',
        )).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get violations: $e');
    }
  }

  // PUT /api/guidance/violations/{id}/resolve
  // Resolve a violation
  static Future<void> resolveViolation(String violationId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/api/guidance/violations/$violationId/resolve'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['status'] != 1) {
        throw Exception(data['message'] ?? 'Failed to resolve violation');
      }
    } catch (e) {
      throw Exception('Failed to resolve violation: $e');
    }
  }

  // DELETE /api/guidance/violations/{id}
  // Delete a violation
  static Future<void> deleteGuidanceViolation(String violationId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/guidance/violations/$violationId'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['status'] != 1) {
        throw Exception(data['message'] ?? 'Failed to delete violation');
      }
    } catch (e) {
      throw Exception('Failed to delete violation: $e');
    }
  }

  // GET /api/guidance/students/{studentNo}/report
  // Returns full student profile + all violations + warning level
  static Future<Map<String, dynamic>?> getGuidanceStudentReport(String studentNo) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/guidance/students/$studentNo/report'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return Map<String, dynamic>.from(data['data']);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get student report: $e');
    }
  }

  // GET /api/guidance/violations/pending
  // Returns only pending violations
  static Future<List<Violation>> getGuidancePendingViolations() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/guidance/violations/pending'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List violations = data['data'];
        return violations.map((v) => Violation(
          id:            v['id'].toString(),
          studentId:     v['student_no'] ?? '',
          type:          _parseViolationType(v['type']),
          date:          DateTime.tryParse(v['date'] ?? '') ?? DateTime.now(),
          remarks:       v['details'] ?? '',
          status:        _parseStatus(v['status']),
          offenseCount:  1,
          reportedBy:    v['recorded_by'] ?? '',
          violationName: v['type'] ?? '',
          severity:      v['severity'] ?? '',
        )).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get pending violations: $e');
    }
  }

  // GET /api/guidance/violations/by-severity
  // Returns violations grouped by severity
  static Future<List<Map<String, dynamic>>> getGuidanceViolationsBySeverity() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/guidance/violations/by-severity'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List groups = data['data'];
        return groups.map((g) => Map<String, dynamic>.from(g)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get violations by severity: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SAO ENDPOINTS
  // ════════════════════════════════════════════════════════════════════════════

  // GET /api/sao/violations
  // Returns all violations with student info
  static Future<List<Violation>> getSaoViolations() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/sao/violations'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List violations = data['data'];
        return violations.map((v) => Violation(
          id:            v['id'].toString(),
          studentId:     v['student_no'] ?? '',
          type:          _parseViolationType(v['type']),
          date:          DateTime.tryParse(v['date'] ?? '') ?? DateTime.now(),
          remarks:       v['details'] ?? '',
          status:        _parseStatus(v['status']),
          offenseCount:  1,
          reportedBy:    v['recorded_by'] ?? '',
          violationName: v['type'] ?? '',
          severity:      v['severity'] ?? '',
        )).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get SAO violations: $e');
    }
  }

  // GET /api/sao/violations/by-status/{status}
  // Filter violations by status: pending / approved / rejected
  static Future<List<Violation>> getSaoViolationsByStatus(String status) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/sao/violations/by-status/$status'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List violations = data['data'];
        return violations.map((v) => Violation(
          id:            v['id'].toString(),
          studentId:     v['student_no'] ?? '',
          type:          _parseViolationType(v['type']),
          date:          DateTime.tryParse(v['date'] ?? '') ?? DateTime.now(),
          remarks:       v['details'] ?? '',
          status:        _parseStatus(v['status']),
          offenseCount:  1,
          reportedBy:    v['recorded_by'] ?? '',
          violationName: v['type'] ?? '',
          severity:      v['severity'] ?? '',
        )).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get violations by status: $e');
    }
  }

  // GET /api/sao/violations/summary
  // Returns total, pending, approved, rejected counts + by severity + by type
  static Future<Map<String, dynamic>> getSaoSummary() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/sao/violations/summary'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return Map<String, dynamic>.from(data['data']);
      }
      return {};
    } catch (e) {
      throw Exception('Failed to get SAO summary: $e');
    }
  }

  // PUT /api/sao/violations/{id}/approve
  // Approve a violation
  static Future<void> approveViolation(String violationId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/api/sao/violations/$violationId/approve'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['status'] != 1) {
        throw Exception(data['message'] ?? 'Failed to approve violation');
      }
    } catch (e) {
      throw Exception('Failed to approve violation: $e');
    }
  }

  // PUT /api/sao/violations/{id}/reject
  // Reject a violation
  static Future<void> rejectViolation(String violationId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/api/sao/violations/$violationId/reject'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['status'] != 1) {
        throw Exception(data['message'] ?? 'Failed to reject violation');
      }
    } catch (e) {
      throw Exception('Failed to reject violation: $e');
    }
  }

  // DELETE /api/sao/violations/{id}
  // Delete a violation permanently
  static Future<void> deleteSaoViolation(String violationId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/sao/violations/$violationId'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['status'] != 1) {
        throw Exception(data['message'] ?? 'Failed to delete violation');
      }
    } catch (e) {
      throw Exception('Failed to delete violation: $e');
    }
  }

  // GET /api/sao/students/{studentNo}/report
  // Full student profile + violation history + warning level
  static Future<Map<String, dynamic>?> getStudentReport(String studentNo) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/sao/students/$studentNo/report'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
        return Map<String, dynamic>.from(data['data']);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get student report: $e');
    }
  }

  // GET /api/sao/users
  // Returns all registered users in the system
  static Future<List<User>> getAllUsers() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/sao/users'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List users = data['data'];
        return users.map((u) => User(
          id:           u['id'].toString(),
          username:     u['username'],
          password:     '',
          name:         u['name'],
          role:         _parseRole((u['role'] as String).toLowerCase()),
          contactNumber: u['contact_number'],
          gradeSection: '${u['course'] ?? ''} - ${u['year'] ?? ''}',
        )).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  // PUT /api/sao/users/{id}
  // Update a user's info
  static Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/api/sao/users/$userId'),
        headers: headers,
        body: jsonEncode(userData),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['status'] != 1) {
        throw Exception(data['message'] ?? 'Failed to update user');
      }
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // DELETE /api/sao/users/{id}
  // Delete a user permanently
  static Future<void> deleteUser(String userId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/sao/users/$userId'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['status'] != 1) {
        throw Exception(data['message'] ?? 'Failed to delete user');
      }
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════════════════════

  static UserRole _parseRole(String roleStr) {
    switch (roleStr) {
      case 'guard':    return UserRole.guard;
      case 'student':  return UserRole.student;
      case 'sao':      return UserRole.sao;
      case 'guidance': return UserRole.guidance;
      default:         return UserRole.student;
    }
  }

  static ViolationType _parseViolationType(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('id'))                                          return ViolationType.noId;
    if (t.contains('uniform'))                                     return ViolationType.noUniform;
    if (t.contains('piercing') || t.contains('earing') || t.contains('earring')) {
      return ViolationType.piercing;
    }
    if (t.contains('hair') || t.contains('color'))                return ViolationType.coloredHair;
    return ViolationType.noId;
  }

  static String _violationTypeToString(ViolationType type) {
    switch (type) {
      case ViolationType.noId:        return 'No ID';
      case ViolationType.noUniform:   return 'No Uniform';
      case ViolationType.piercing:    return 'Piercing';
      case ViolationType.coloredHair: return 'Colored Hair';
    }
  }

  // API returns: Pending, Approved, Rejected
  static ViolationStatus _parseStatus(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'approved': return ViolationStatus.referredToSAO;
      case 'rejected': return ViolationStatus.cleared;
      case 'pending':  return ViolationStatus.warning;
      default:         return ViolationStatus.warning;
    }
  }

  // Legacy method — kept for compatibility
  static Future<List<Violation>> getStudentViolations(String studentNo) async {
    final result = await getMyViolations();
    return result['violations'] ?? [];
  }

  // Legacy method — kept for compatibility
  static Future<void> updateViolationStatus(
      String violationId, ViolationStatus status) async {
    if (status == ViolationStatus.referredToSAO) {
      await approveViolation(violationId);
    } else if (status == ViolationStatus.cleared) {
      await rejectViolation(violationId);
    } else {
      await resolveViolation(violationId);
    }
  }
}