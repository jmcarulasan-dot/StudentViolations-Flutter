import 'package:flutter/foundation.dart';
import '../models/violation.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../models/notification_model.dart';
import 'dart:io';
import 'dart:convert';

class ViolationProvider with ChangeNotifier {
  List<Violation> _violations = [];
  List<NotificationModel> _notifications = [];
  List<User> _students = [];
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  // Student-specific data
  String _warningLevel = 'green';
  int _pendingCount = 0;
  int _approvedCount = 0;
  int _rejectedCount = 0;
  int _totalCount = 0;
  String? _studentQrCode;
  Map<String, dynamic> _studentProfile = {};
  Map<String, dynamic> _validatedStudent = {};
  Map<String, dynamic> _violationSummary = {};
  Map<String, dynamic> _saoSummary = {};
  Map<String, dynamic> _studentReport = {};
  Map<String, dynamic> _guardProfile = {};

  // Getters
  List<Violation> get violations => _violations;
  List<User> get students => _students;
  List<User> get users => _users;
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get warningLevel => _warningLevel;
  int get pendingCount => _pendingCount;
  int get approvedCount => _approvedCount;
  int get rejectedCount => _rejectedCount;
  int get totalCount => _totalCount;
  String? get studentQrCode => _studentQrCode;
  Map<String, dynamic> get studentProfile => _studentProfile;
  Map<String, dynamic> get validatedStudent => _validatedStudent;
  Map<String, dynamic> get violationSummary => _violationSummary;
  Map<String, dynamic> get saoSummary => _saoSummary;
  Map<String, dynamic> get studentReport => _studentReport;
  Map<String, dynamic> get guardProfile => _guardProfile;
  List<Map<String, dynamic>> _pendingDismissals = [];
  List<Map<String, dynamic>> get pendingDismissals => _pendingDismissals;
  List<Map<String, dynamic>> _dismissedStudents = [];
  List<Map<String, dynamic>> get dismissedStudents => _dismissedStudents;

  //STUDENTS METHOD
  // GET /api/student/violations
  Future<void> loadMyViolations() async {
    _setLoading(true);
    _error = null;
    try {
      final result = await DatabaseService.getMyViolations();
      if (result.isNotEmpty) {
        _violations = List<Violation>.from(result['violations'] ?? []);
        _pendingCount = result['pending'] ?? 0;
        _approvedCount = result['approved'] ?? 0;
        _rejectedCount = result['rejected'] ?? 0;
        _totalCount = result['total_violations'] ?? 0;
        _warningLevel = result['warning_level'] ?? 'green';
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load violations: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/student/profile
  Future<void> loadMyProfile() async {
    _setLoading(true);
    _error = null;
    try {
      _studentProfile = await DatabaseService.getMyProfile();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load profile: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> uploadProfilePhoto(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      await DatabaseService.uploadProfilePhoto(base64String);
      await loadMyProfile();
      return null;
    } catch (e) {
      return 'Upload failed. Try again.';
    }
  }

  Future<void> loadGuardProfile() async {
    _setLoading(true);
    _error = null;
    try {
      _guardProfile = await DatabaseService.getMyProfile();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load profile: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/student/qrcode
  Future<void> loadMyQrCode() async {
    _setLoading(true);
    _error = null;
    try {
      _studentQrCode = await DatabaseService.getMyQrCode();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load QR code: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadStudentViolations(String studentId) async {
    await loadMyViolations();
  }

  // GUARD METHODS
  // GET /api/guard/students
  Future<void> loadStudents() async {
    _setLoading(true);
    _error = null;
    try {
      _students = await DatabaseService.getAllStudents();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load students: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/guard/students/{studentNo}
  // Search specific student by StudentNo
  Future<Map<String, dynamic>?> searchStudent(String studentNo) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await DatabaseService.validateStudent(studentNo);
      notifyListeners();
      return result;
    } catch (e) {
      _error = 'Student not found: ${e.toString()}';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/guard/student/validate?studentNo=xxx
  // Validate student by QR code scan
  Future<void> validateStudent(String studentNo) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await DatabaseService.validateStudent(studentNo);
      _validatedStudent = result ?? {};
      notifyListeners();
    } catch (e) {
      _error = 'Failed to validate student: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // POST /api/guard/student/violation
  // Record a new violation
  Future<void> recordViolation({
    required String studentId,
    required ViolationType type,
    required String reportedBy,
    String? remarks,
    String? severity,
    String? violationName,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final violation = Violation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        studentId: studentId,
        type: type,
        date: DateTime.now(),
        remarks: remarks,
        status: ViolationStatus.warning,
        offenseCount: 1,
        reportedBy: reportedBy,
        violationName: violationName ?? _violationTypeToString(type),
        severity: severity ?? 'minor',
      );
      await DatabaseService.addViolation(violation);
      await loadStudents();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to record violation: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/guard/violations/student?studentNo=xxx
  // View all violations of a specific student
  Future<void> loadViolationsByStudent(String studentNo) async {
    _setLoading(true);
    _error = null;
    try {
      _violations = await DatabaseService.getViolationsByStudent(studentNo);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load violations: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/guard/violations/summary?StartDate=xxx&EndDate=xxx
  // Get violation summary for a date range
  Future<void> loadViolationSummary(String startDate, String endDate) async {
    _setLoading(true);
    _error = null;
    try {
      _violationSummary = await DatabaseService.getViolationSummary(
        startDate,
        endDate,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load summary: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // SAO METHODS
  // SAO METHODS

  // GET /api/sao/violations
  // Load all violations for SAO
  Future<void> loadSaoViolations() async {
    _setLoading(true);
    _error = null;
    try {
      _violations = await DatabaseService.getSaoViolations();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load SAO violations: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/sao/violations/by-status/{status}
  // Filter violations by status: pending / approved / rejected
  Future<void> loadSaoViolationsByStatus(String status) async {
    _setLoading(true);
    _error = null;
    try {
      _violations = await DatabaseService.getSaoViolationsByStatus(status);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load violations by status: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/sao/violations/summary
  // Load SAO summary stats
  Future<void> loadSaoSummary() async {
    _setLoading(true);
    _error = null;
    try {
      _saoSummary = await DatabaseService.getSaoSummary();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load SAO summary: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // PUT /api/sao/violations/{id}/approve
  Future<void> approveViolation(String violationId) async {
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.approveViolation(violationId);
      await loadSaoViolations();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to approve violation: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // PUT /api/sao/violations/{id}/reject
  Future<void> rejectViolation(String violationId) async {
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.rejectViolation(violationId);
      await loadSaoViolations();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to reject violation: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // DELETE /api/sao/violations/{id}
  Future<void> deleteSaoViolation(String violationId) async {
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.deleteSaoViolation(violationId);
      await loadSaoViolations();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete violation: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/sao/students/{studentNo}/report
  Future<void> loadStudentReport(String studentNo) async {
    _setLoading(true);
    _error = null;
    try {
      _studentReport = await DatabaseService.getStudentReport(studentNo) ?? {};
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load student report: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/sao/users
  Future<void> loadAllUsers() async {
    _setLoading(true);
    _error = null;
    try {
      _users = await DatabaseService.getAllUsers();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load users: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // PUT /api/sao/users/{id}
  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.updateUser(userId, userData);
      await loadAllUsers();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update user: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // DELETE /api/sao/users/{id}
  Future<void> deleteUser(String userId) async {
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.deleteUser(userId);
      await loadAllUsers();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete user: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateViolationStatus(
    String violationId,
    ViolationStatus status,
  ) async {
    if (status == ViolationStatus.referredToSAO) {
      await approveViolation(violationId);
    } else if (status == ViolationStatus.cleared) {
      await rejectViolation(violationId);
    } else {
      await resolveViolation(violationId);
    }
  }

  Future<void> warnStudent(String studentNo) async {
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.warnStudent(studentNo);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to warn student: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPendingDismissals() async {
    _setLoading(true);
    _error = null;
    try {
      _pendingDismissals = await DatabaseService.getPendingDismissals();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load dismissals: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/sao/students/dismissed
  Future<void> loadDismissedStudents() async {
    _setLoading(true);
    _error = null;
    try {
      _dismissedStudents = await DatabaseService.getDismissedStudents();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load dismissed students: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // PUT /api/sao/students/{studentNo}/recommend-dismiss
  Future<void> recommendDismiss(String studentNo) async {
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.recommendDismiss(studentNo);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to recommend dismissal: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // PUT /api/sao/violations/{id}/appeal/review
  Future<void> guidanceReviewAppeal(
    String violationId,
    String appealStatus,
    String appealRemarks,
  ) async {
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.guidanceReviewAppeal(
        violationId,
        appealStatus,
        appealRemarks,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to review appeal: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // PUT /api/sao/violations/{id}/appeal/review
  Future<void> saoReviewAppeal(
    String violationId,
    String appealStatus,
    String appealRemarks,
  ) async {
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.saoReviewAppeal(
        violationId,
        appealStatus,
        appealRemarks,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to review appeal: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/sao/violations/appeals
  Future<List<Map<String, dynamic>>> loadSaoAppeals() async {
    _error = null;
    try {
      return await DatabaseService.getSaoAppeals();
    } catch (e) {
      _error = 'Failed to load appeals: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }

  // PUT /api/sao/students/{studentNo}/dismiss
  Future<void> dismissStudent(String studentNo) async {
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.dismissStudent(studentNo);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to dismiss student: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // PUT /api/sao/students/{studentNo}/cancel-dismiss
  Future<void> cancelDismiss(String studentNo) async {
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.cancelDismiss(studentNo);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to cancel dismissal: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submitAppeal(String violationId, String appealText) async {
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.submitAppeal(violationId, appealText);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to submit appeal: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markNotificationAsRead(int id) async {
    try {
      await DatabaseService.markNotificationAsRead(id);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          targetUsername: _notifications[index].targetUsername,
          targetRole: _notifications[index].targetRole,
          title: _notifications[index].title,
          message: _notifications[index].message,
          isRead: true,
          createdAt: _notifications[index].createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to mark as read: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      await DatabaseService.markAllNotificationsAsRead();
      _notifications = _notifications
          .map(
            (n) => NotificationModel(
              id: n.id,
              targetUsername: n.targetUsername,
              targetRole: n.targetRole,
              title: n.title,
              message: n.message,
              isRead: true,
              createdAt: n.createdAt,
            ),
          )
          .toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to mark all as read: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> loadNotifications() async {
    _setLoading(true);
    _error = null;
    try {
      _notifications = await DatabaseService.getNotifications();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load notifications: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
  // HELPERS

  String _violationTypeToString(ViolationType type) {
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

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
