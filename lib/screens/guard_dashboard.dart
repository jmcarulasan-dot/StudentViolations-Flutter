import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/violation.dart';
import '../providers/auth_provider.dart';
import '../providers/violation_provider.dart';

const _guardBlue = Color(0xFF0288D1);
const _guardNavy = Color(0xFF1A237E);
const _guardRed = Color(0xFFC62828);

class GuardDashboard extends StatefulWidget {
  const GuardDashboard({super.key});

  @override
  State<GuardDashboard> createState() => _GuardDashboardState();
}

class _GuardDashboardState extends State<GuardDashboard> {
  final _studentNoController = TextEditingController();
  final _detailsController = TextEditingController();

  static const Map<String, String> _severityByViolation = {
    'No ID': 'minor',
    'No Uniform': 'minor',
    'Piercing': 'minor',
    'Colored Hair': 'minor',
    'Disruptive Behavior': 'moderate',
    'Vandalism': 'major',
    'Prohibited Items': 'critical',
    'Other': 'minor',
  };

  String? _selectedViolation;
  Map<String, dynamic> _student = {};
  String? _validationMessage;
  bool _scannerActive = true;
  bool _isValidating = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _studentNoController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guardName =
        context.read<AuthProvider>().currentUser?.name.trim() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FD),
      appBar: AppBar(
        title: const Text('Guard • Student validation'),
        backgroundColor: Colors.white,
        foregroundColor: _guardNavy,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _introCard(guardName.isEmpty ? 'Guard' : guardName),
              const SizedBox(height: 18),
              _scannerCard(),
              const SizedBox(height: 14),
              _manualEntryCard(),
              if (_isValidating) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_validationMessage != null) ...[
                const SizedBox(height: 14),
                _messageCard(
                  _validationMessage!,
                  icon: Icons.error_outline_rounded,
                  color: _guardRed,
                ),
              ],
              if (_student.isNotEmpty) ...[
                const SizedBox(height: 16),
                _studentCard(),
                const SizedBox(height: 16),
                _recordViolationCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _introCard(String guardName) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFE1F5FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFB3E5FC)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _guardBlue.withOpacity(.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.qr_code_scanner_rounded,
                color: _guardBlue, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, $guardName',
                    style: const TextStyle(
                        color: _guardNavy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  'Scan or enter a student number to validate the student and record a violation.',
                  style: TextStyle(color: Color(0xFF546E7A), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scannerCard() {
    return _panel(
      title: 'Scan student QR code',
      icon: Icons.qr_code_scanner_rounded,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 230,
              width: double.infinity,
              child: _scannerActive
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          onDetect: (capture) {
                            if (_isValidating || capture.barcodes.isEmpty) {
                              return;
                            }
                            final code = capture.barcodes.first.rawValue;
                            if (code != null && code.trim().isNotEmpty) {
                              _validateStudent(code);
                            }
                          },
                        ),
                        IgnorePointer(
                          child: Center(
                            child: Container(
                              width: 190,
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.white, width: 3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Text(
                            'Place the student QR code inside the frame',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              shadows: [Shadow(blurRadius: 8)],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: const Color(0xFF10243A),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.lightGreenAccent, size: 42),
                          const SizedBox(height: 8),
                          Text(
                            _studentNoController.text,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                          ),
                          TextButton.icon(
                            onPressed: _resetScan,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Scan another student'),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _scannerActive ? null : _resetScan,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan again'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _manualEntryCard() {
    return _panel(
      title: 'Validate by student number',
      icon: Icons.badge_outlined,
      child: Column(
        children: [
          TextField(
            controller: _studentNoController,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              labelText: 'Student number',
              hintText: 'e.g. C26-01-0001-MAN121',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            onSubmitted: (value) => _validateStudent(value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isValidating
                  ? null
                  : () => _validateStudent(_studentNoController.text),
              icon: _isValidating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(_isValidating ? 'Validating…' : 'Validate student'),
              style: FilledButton.styleFrom(
                backgroundColor: _guardBlue,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentCard() {
    final studentNo = (_student['student_no'] ?? '').toString();
    final name = (_student['name'] ?? 'Student').toString();
    final course = (_student['course'] ?? '').toString();
    final year = (_student['year'] ?? '').toString();
    final courseYear = [course, if (year.isNotEmpty) 'Year $year']
        .where((part) => part.isNotEmpty)
        .join(' • ');

    return _panel(
      title: 'Student validated',
      icon: Icons.verified_user_rounded,
      child: Row(
        children: [
          _studentAvatar(name),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: _guardNavy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(studentNo,
                    style: const TextStyle(
                        color: Color(0xFF546E7A),
                        fontWeight: FontWeight.w600)),
                if (courseYear.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(courseYear,
                      style: const TextStyle(color: Color(0xFF78909C))),
                ],
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: Colors.green, size: 25),
        ],
      ),
    );
  }

  Widget _studentAvatar(String name) {
    final encoded = (_student['profile_photo'] ?? '').toString().trim();
    if (encoded.isNotEmpty) {
      try {
        final base64Value = encoded.contains(',') ? encoded.split(',').last : encoded;
        return CircleAvatar(
          radius: 27,
          backgroundColor: const Color(0xFFE1F5FE),
          backgroundImage: MemoryImage(base64Decode(base64Value)),
        );
      } catch (_) {
        // Use the initials fallback when an older profile photo is malformed.
      }
    }
    return CircleAvatar(
      radius: 27,
      backgroundColor: const Color(0xFFE1F5FE),
      child: Text(
        name.isEmpty ? 'S' : name.substring(0, 1).toUpperCase(),
        style: const TextStyle(
            color: _guardBlue, fontSize: 20, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _recordViolationCard() {
    final severity = _selectedViolation == null
        ? null
        : _severityByViolation[_selectedViolation!];

    return _panel(
      title: 'Record a violation',
      icon: Icons.report_problem_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedViolation,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Violation type',
              prefixIcon: Icon(Icons.warning_amber_rounded),
            ),
            hint: const Text('Choose a violation'),
            items: _severityByViolation.entries
                .map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text('${entry.key} • ${entry.value.toUpperCase()}'),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedViolation = value),
          ),
          if (severity != null) ...[
            const SizedBox(height: 10),
            _severityNotice(severity),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _detailsController,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Details',
              hintText: 'Describe what happened',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _submitViolation,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_isSubmitting ? 'Submitting…' : 'Submit violation'),
              style: FilledButton.styleFrom(
                backgroundColor: _guardRed,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _severityNotice(String severity) {
    final color = switch (severity) {
      'critical' => _guardRed,
      'major' => Colors.deepOrange,
      'moderate' => Colors.orange.shade800,
      _ => _guardBlue,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        border: Border.all(color: color.withOpacity(.25)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 18, color: color),
          const SizedBox(width: 8),
          Text('Severity is set automatically: ${severity.toUpperCase()}',
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _panel({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1EAF0)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _guardBlue.withOpacity(.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _guardBlue, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: _guardNavy,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _messageCard(String message,
      {required IconData icon, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        border: Border.all(color: color.withOpacity(.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 9),
          Expanded(
              child: Text(message,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Future<void> _validateStudent(String rawStudentNo) async {
    final studentNo = rawStudentNo.trim().toUpperCase();
    if (studentNo.isEmpty) {
      setState(() {
        _student = {};
        _validationMessage = 'Enter or scan a student number first.';
      });
      return;
    }

    setState(() {
      _studentNoController.text = studentNo;
      _student = {};
      _validationMessage = null;
      _selectedViolation = null;
      _detailsController.clear();
      _scannerActive = false;
      _isValidating = true;
    });

    final provider = context.read<ViolationProvider>();
    await provider.validateStudent(studentNo);
    if (!mounted) return;

    setState(() {
      _isValidating = false;
      _student = provider.validatedStudent;
      _validationMessage = provider.error;
    });
  }

  Future<void> _submitViolation() async {
    if (_student.isEmpty || _selectedViolation == null) {
      _showMessage('Validate a student and choose a violation type.', isError: true);
      return;
    }
    final details = _detailsController.text.trim();
    if (details.isEmpty) {
      _showMessage('Enter details describing the violation.', isError: true);
      return;
    }

    final severity = _severityByViolation[_selectedViolation!]!;
    setState(() => _isSubmitting = true);
    final provider = context.read<ViolationProvider>();
    await provider.recordViolation(
      studentId: _studentNoController.text.trim().toUpperCase(),
      type: _parseViolationType(_selectedViolation!),
      reportedBy: context.read<AuthProvider>().currentUser?.name ?? 'Guard',
      remarks: details,
      severity: severity,
      violationName: _selectedViolation!,
    );
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    if (provider.error == null) {
      _showMessage(
          '${_selectedViolation!} recorded with ${severity.toUpperCase()} severity.');
      setState(() {
        _selectedViolation = null;
        _detailsController.clear();
      });
    } else {
      _showMessage(provider.error!, isError: true);
    }
  }

  void _resetScan() {
    setState(() {
      _scannerActive = true;
      _studentNoController.clear();
      _student = {};
      _validationMessage = null;
      _selectedViolation = null;
      _detailsController.clear();
    });
  }

  ViolationType _parseViolationType(String value) {
    switch (value) {
      case 'No Uniform':
        return ViolationType.noUniform;
      case 'Piercing':
        return ViolationType.piercing;
      case 'Colored Hair':
        return ViolationType.coloredHair;
      default:
        return ViolationType.noId;
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _guardRed : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to verify your account again.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (shouldLogout == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}

