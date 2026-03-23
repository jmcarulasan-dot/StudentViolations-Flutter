import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/auth_provider.dart';
import '../providers/violation_provider.dart';
import '../models/user.dart';

const _red  = Color(0xFFFD070C);
const _navy = Color(0xFF0F136E);

class GuardDashboard extends StatefulWidget {
  const GuardDashboard({super.key});
  @override
  State<GuardDashboard> createState() => _GuardDashboardState();
}

class _GuardDashboardState extends State<GuardDashboard> {
  int _currentIndex = 0;

  // Validate
  final _validateController = TextEditingController();
  Map<String, dynamic> _validatedStudent = {};
  String? _validateError;

  // Record
  final _recordFormKey = GlobalKey<FormState>();
  User?   _selectedStudent;
  String? _selectedViolationType;
  String  _selectedSeverity = 'minor';
  final   _remarksController = TextEditingController();

  // History
  final _historyController = TextEditingController();
  String? _historyError;

  // Summary
  final _summaryFormKey      = GlobalKey<FormState>();
  final _startDateController = TextEditingController();
  final _endDateController   = TextEditingController();

  final List<String> _violationTypes = [
    'No ID', 'No Uniform', 'Piercing', 'Colored Hair',
    'Late', 'Cutting Class', 'Disruptive Behavior',
    'Vandalism', 'Prohibited Items', 'Other',
  ];
  final List<String> _severities = ['minor', 'moderate', 'major', 'critical'];

  // Date regex validator
  final _dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ViolationProvider>(context, listen: false).loadStudents();
    });
    final now = DateTime.now();
    _startDateController.text =
        DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 7)));
    _endDateController.text = DateFormat('yyyy-MM-dd').format(now);
  }

  @override
  void dispose() {
    _validateController.dispose();
    _remarksController.dispose();
    _historyController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Guard Dashboard',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 3,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Consumer<ViolationProvider>(
        builder: (context, vp, child) => _buildContent(context, vp),
      ),
      bottomNavigationBar: Consumer<ViolationProvider>(
        builder: (context, vp, child) => _buildBottomNav(context, vp),
      ),
    );
  }

  // ── Bottom Nav ───────────────────────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context, ViolationProvider vp) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
            blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.report_rounded, 'Record'),
              _navItem(1, Icons.history_rounded, 'History'),
              // QR center button
              GestureDetector(
                onTap: () => _openQrScanner(context, vp),
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: _navy,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _navy.withOpacity(0.4),
                        blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded,
                      color: Colors.white, size: 26),
                ),
              ),
              _navItem(2, Icons.bar_chart_rounded, 'Summary'),
              _navItem(3, Icons.people_rounded, 'Students'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _navy.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? _navy : Colors.grey, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? _navy : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ViolationProvider vp) {
    switch (_currentIndex) {
      case 0:  return _buildRecordContent(context, vp);
      case 1:  return _buildHistoryContent(vp);
      case 2:  return _buildSummaryContent(vp);
      case 3:  return _buildStudentsContent(vp);
      default: return _buildRecordContent(context, vp);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // RECORD TAB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildRecordContent(BuildContext context, ViolationProvider vp) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      child: Form(
        key: _recordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 16),

            // Validated student card
            if (_validatedStudent.isNotEmpty) ...[
              _buildValidatedCard(_validatedStudent),
              const SizedBox(height: 14),
            ],

            _sectionTitle('📋 Record Violation', _red),
            const SizedBox(height: 12),

            // Student dropdown with validation
            DropdownButtonFormField<User>(
              value: _selectedStudent,
              isExpanded: true,
              decoration: _inputDeco('Select Student *', Icons.person_search_rounded),
              hint: const Text('Choose a student', style: TextStyle(fontSize: 13)),
              validator: (v) => v == null ? 'Please select a student' : null,
              items: vp.students.map((s) => DropdownMenuItem(
                value: s,
                child: Text('${s.name} — ${s.gradeSection ?? ''}',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (v) => setState(() => _selectedStudent = v),
            ),
            const SizedBox(height: 12),

            // Violation type with validation
            DropdownButtonFormField<String>(
              value: _selectedViolationType,
              decoration: _inputDeco('Violation Type *', Icons.warning_rounded),
              hint: const Text('Select type', style: TextStyle(fontSize: 13)),
              validator: (v) => v == null ? 'Please select a violation type' : null,
              items: _violationTypes.map((t) => DropdownMenuItem(
                value: t,
                child: Text(t, style: const TextStyle(fontSize: 13)),
              )).toList(),
              onChanged: (v) => setState(() => _selectedViolationType = v),
            ),
            const SizedBox(height: 12),

            // Severity
            DropdownButtonFormField<String>(
              value: _selectedSeverity,
              decoration: _inputDeco('Severity *', Icons.speed_rounded),
              validator: (v) => v == null ? 'Please select severity' : null,
              items: _severities.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s.toUpperCase(), style: const TextStyle(fontSize: 13)),
              )).toList(),
              onChanged: (v) => setState(() => _selectedSeverity = v ?? 'minor'),
            ),
            const SizedBox(height: 12),

            // Remarks (optional)
            TextFormField(
              controller: _remarksController,
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
              decoration: _inputDeco('Remarks (Optional)', Icons.note_outlined),
            ),
            const SizedBox(height: 16),

            // Error from provider
            if (vp.error != null) ...[
              _errorBanner(vp.error!),
              const SizedBox(height: 10),
            ],

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: vp.isLoading ? null : () => _submitRecord(context, vp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: vp.isLoading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.report_rounded, size: 20),
                label: Text(vp.isLoading ? 'Recording...' : 'Submit Violation',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitRecord(BuildContext context, ViolationProvider vp) async {
    if (!_recordFormKey.currentState!.validate()) return;

    final auth    = Provider.of<AuthProvider>(context, listen: false);
    final guardId = auth.currentUser?.id ?? '';

    if (guardId.isEmpty) {
      _showErrorSnack(context, 'Guard ID not found. Please login again.');
      return;
    }

    await vp.recordViolation(
      studentId:  _selectedStudent!.studentNo ?? _selectedStudent!.id,
      type:       _mapViolationType(_selectedViolationType!),
      reportedBy: guardId,
      remarks:    _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      severity:   _selectedSeverity,
    );

    if (vp.error == null && mounted) {
      _showSuccessSnack(context, 'Violation recorded successfully!');
      setState(() {
        _selectedStudent       = null;
        _selectedViolationType = null;
        _selectedSeverity      = 'minor';
        _remarksController.clear();
      });
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HISTORY TAB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildHistoryContent(ViolationProvider vp) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('📂 Violation History', _navy),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _historyController,
                  style: const TextStyle(fontSize: 13),
                  decoration: _inputDeco('Enter StudentNo', Icons.search_rounded,
                      error: _historyError),
                  onChanged: (_) => setState(() => _historyError = null),
                  onFieldSubmitted: (v) => _searchHistory(vp),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: vp.isLoading ? null : () => _searchHistory(vp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: vp.isLoading
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Search',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ],
          ),

          if (_historyError != null) ...[
            const SizedBox(height: 6),
            Text(_historyError!,
                style: const TextStyle(fontSize: 12, color: _red, fontWeight: FontWeight.w500)),
          ],

          const SizedBox(height: 16),

          if (vp.error != null)
            _errorBanner(vp.error!)
          else if (vp.violations.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vp.violations.length,
              itemBuilder: (context, index) {
                final v  = vp.violations[index];
                final sc = _statusColor(v.statusDescription);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sc.withOpacity(0.2)),
                    boxShadow: [BoxShadow(color: _navy.withOpacity(0.06),
                        blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _red.withOpacity(0.1), radius: 20,
                        child: const Icon(Icons.warning_amber_rounded, color: _red, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.violationDescription,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(DateFormat('MMM dd, yyyy').format(v.date),
                              style: const TextStyle(fontSize: 11, color: Colors.black45)),
                          if (v.severity != null)
                            Text('Severity: ${v.severity}',
                                style: const TextStyle(fontSize: 11, color: Colors.black45)),
                          Text('By: ${v.reportedBy ?? 'Unknown'}',
                              style: const TextStyle(fontSize: 11, color: Colors.black45)),
                        ],
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(v.statusDescription,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sc)),
                      ),
                    ],
                  ),
                );
              },
            )
          else if (_historyController.text.isNotEmpty)
            _emptyState('No violations found for this student'),
        ],
      ),
    );
  }

  void _searchHistory(ViolationProvider vp) {
    final input = _historyController.text.trim();
    if (input.isEmpty) {
      setState(() => _historyError = 'Please enter a StudentNo to search');
      return;
    }
    setState(() => _historyError = null);
    vp.loadViolationsByStudent(input);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SUMMARY TAB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildSummaryContent(ViolationProvider vp) {
    final summary = vp.violationSummary;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      child: Form(
        key: _summaryFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('📊 Violation Summary', _navy),
            const SizedBox(height: 12),

            TextFormField(
              controller: _startDateController,
              style: const TextStyle(fontSize: 13),
              decoration: _inputDeco('Start Date * (yyyy-MM-dd)', Icons.calendar_today_rounded),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Start date is required';
                if (!_dateRegex.hasMatch(v.trim())) return 'Format must be yyyy-MM-dd (e.g. 2026-03-01)';
                return null;
              },
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _endDateController,
              style: const TextStyle(fontSize: 13),
              decoration: _inputDeco('End Date * (yyyy-MM-dd)', Icons.calendar_month_rounded),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'End date is required';
                if (!_dateRegex.hasMatch(v.trim())) return 'Format must be yyyy-MM-dd (e.g. 2026-03-31)';
                try {
                  final start = DateTime.parse(_startDateController.text.trim());
                  final end   = DateTime.parse(v.trim());
                  if (end.isBefore(start)) return 'End date must be after start date';
                } catch (_) {}
                return null;
              },
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: vp.isLoading ? null : () => _getSummary(vp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: vp.isLoading
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.bar_chart_rounded),
                label: Text(vp.isLoading ? 'Loading...' : 'Get Summary',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),

            if (vp.error != null)
              _errorBanner(vp.error!)
            else if (summary.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(child: _summaryCard('Total',
                      summary['totalViolations']?.toString() ?? '0', _navy)),
                  const SizedBox(width: 12),
                  Expanded(child: _summaryCard('Top Violation',
                      summary['topViolation']?.toString() ?? 'N/A', _red)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: _navy.withOpacity(0.06),
                      blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Date Range',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _navy)),
                    const SizedBox(height: 8),
                    _infoRow('From', summary['startDate']?.toString().substring(0, 10) ?? ''),
                    _infoRow('To',   summary['endDate']?.toString().substring(0, 10) ?? ''),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _getSummary(ViolationProvider vp) {
    if (!_summaryFormKey.currentState!.validate()) return;
    vp.loadViolationSummary(
      _startDateController.text.trim(),
      _endDateController.text.trim(),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STUDENTS TAB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildStudentsContent(ViolationProvider vp) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('👥 All Students', _navy),
          const SizedBox(height: 12),
          if (vp.isLoading)
            const Center(child: CircularProgressIndicator(color: _navy))
          else if (vp.error != null)
            _errorBanner(vp.error!)
          else if (vp.students.isEmpty)
            Center(child: Column(children: [
              const SizedBox(height: 40),
              Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text('No students found',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => vp.loadStudents(),
                style: ElevatedButton.styleFrom(backgroundColor: _navy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Retry'),
              ),
            ]))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vp.students.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final s = vp.students[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: _navy.withOpacity(0.06),
                        blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _navy.withOpacity(0.1),
                        child: Text(s.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w700, color: _navy)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(s.studentNo ?? s.id,
                              style: const TextStyle(fontSize: 11, color: Colors.black45)),
                          Text(s.gradeSection ?? '',
                              style: const TextStyle(fontSize: 11, color: Colors.black45)),
                        ],
                      )),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // QR SCANNER
  // ════════════════════════════════════════════════════════════════════════════
  void _openQrScanner(BuildContext context, ViolationProvider vp) {
    // Always show the validate dialog — it has QR scanner + manual input together
    _showManualValidateDialog(context, vp);
  }

  void _openQrScannerFullScreen(BuildContext context, ViolationProvider vp) {
    final MobileScannerController cam = MobileScannerController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(children: [
              const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Scan Student QR Code',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                onPressed: () { cam.dispose(); Navigator.of(ctx).pop(); },
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ]),
          ),
          Expanded(
            child: Stack(alignment: Alignment.center, children: [
              MobileScanner(
                controller: cam,
                onDetect: (capture) {
                  final scanned = capture.barcodes.firstOrNull?.rawValue;
                  if (scanned != null && scanned.isNotEmpty) {
                    cam.dispose();
                    Navigator.of(ctx).pop();
                    _validateAndShow(vp, scanned);
                  }
                },
              ),
              Center(
                child: SizedBox(width: 220, height: 220,
                  child: Stack(children: [
                    Positioned(top: 0, left: 0,   child: _corner(true, true)),
                    Positioned(top: 0, right: 0,  child: _corner(true, false)),
                    Positioned(bottom: 0, left: 0, child: _corner(false, true)),
                    Positioned(bottom: 0, right: 0,child: _corner(false, false)),
                  ]),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const Text('Point camera at the student\'s QR code',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                  onPressed: () => cam.toggleTorch(),
                  icon: const Icon(Icons.flashlight_on_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => cam.switchCamera(),
                  icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 26),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    ).then((_) => cam.dispose());
  }

  void _showManualValidateDialog(BuildContext context, ViolationProvider vp) {
    final ctrl = TextEditingController();
    String? dialogError;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.qr_code_rounded, color: _navy, size: 22),
            SizedBox(width: 8),
            Text('Validate Student',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _navy)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // QR Scanner box inside dialog
              if (!kIsWeb)
                SizedBox(
                  height: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        MobileScanner(
                          onDetect: (capture) {
                            final scanned = capture.barcodes.firstOrNull?.rawValue;
                            if (scanned != null && scanned.isNotEmpty) {
                              Navigator.of(dialogContext).pop();
                              _validateAndShow(vp, scanned);
                            }
                          },
                        ),
                        // Corner brackets overlay
                        SizedBox(
                          width: 140, height: 140,
                          child: Stack(children: [
                            Positioned(top: 0, left: 0,    child: _corner(true, true)),
                            Positioned(top: 0, right: 0,   child: _corner(true, false)),
                            Positioned(bottom: 0, left: 0, child: _corner(false, true)),
                            Positioned(bottom: 0, right: 0,child: _corner(false, false)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),

              // OR divider
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('OR enter manually',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400,
                            fontWeight: FontWeight.w600)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ]),
              ),

              // Manual input
              TextField(
                controller: ctrl,
                autofocus: kIsWeb,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. C26-01-0001-MAN121',
                  errorText: dialogError,
                  prefixIcon: const Icon(Icons.badge_rounded, color: _navy, size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF7F8FC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFDDE1EE))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _navy, width: 1.5)),
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _red, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (_) => setDialogState(() => dialogError = null),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              onPressed: () {
                final input = ctrl.text.trim();
                if (input.isEmpty) {
                  setDialogState(() => dialogError = 'Please enter a StudentNo');
                  return;
                }
                Navigator.of(dialogContext).pop();
                _validateAndShow(vp, input);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Validate'),
            ),
          ],
        ),
      ),
    );
  }

  void _validateAndShow(ViolationProvider vp, String studentNo) async {
    await vp.validateStudent(studentNo);
    if (mounted) {
      if (vp.validatedStudent.isNotEmpty) {
        setState(() {
          _validatedStudent = vp.validatedStudent;
          _currentIndex = 0; // Switch to Record tab
        });
      } else {
        setState(() => _validateError = 'Student not found: $studentNo');
        if (mounted) _showErrorSnack(context, 'Student not found: $studentNo');
      }
    }
  }

  Widget _buildValidatedCard(Map<String, dynamic> student) {
    final level = student['warning_level'] ?? 'green';
    final color = _warningColor(level);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.15), radius: 22,
          child: Icon(Icons.person_rounded, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(student['name'] ?? '',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            Text(student['student_no'] ?? '',
                style: const TextStyle(fontSize: 11, color: Colors.black45)),
            Text('Violations: ${student['violation_count'] ?? 0}',
                style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
          child: Text(level.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      ]),
    );
  }

  Widget _corner(bool top, bool left) => SizedBox(
    width: 24, height: 24,
    child: CustomPaint(painter: _CornerPainter(top: top, left: left)),
  );

  // ════════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildWelcomeCard() {
    final name = Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'Guard';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, Color(0xFF1A1F8F)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _navy.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.security_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, $name!',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            const Text('Tap 🔍 in the nav bar to scan student QR code',
                style: TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        )),
      ]),
    );
  }

  Widget _sectionTitle(String text, Color color) {
    return Row(children: [
      Container(width: 4, height: 18,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _navy)),
    ]);
  }

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _red.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: _red, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message,
            style: const TextStyle(fontSize: 12, color: _red, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _emptyState(String message) {
    return Center(child: Column(children: [
      const SizedBox(height: 40),
      Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
      const SizedBox(height: 8),
      Text(message, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
    ]));
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.black45,
            fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon, {String? error}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Colors.black45),
      prefixIcon: Icon(icon, color: _navy, size: 20),
      errorText: error,
      filled: true,
      fillColor: const Color(0xFFF7F8FC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDE1EE))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDE1EE))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _navy, width: 1.8)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _red, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _red, width: 1.8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Color _warningColor(String level) {
    switch (level.toLowerCase()) {
      case 'red':    return Colors.red;
      case 'orange': return Colors.orange;
      case 'yellow': return Colors.amber;
      default:       return Colors.green;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'rejected': return _red;
      default:         return Colors.orange;
    }
  }

  dynamic _mapViolationType(String type) {
    switch (type.toLowerCase()) {
      case 'no uniform':   return 'noUniform';
      case 'piercing':     return 'piercing';
      case 'colored hair': return 'coloredHair';
      default:             return 'noId';
    }
  }

  void _showSuccessSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showErrorSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: _red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.logout_rounded, color: _red, size: 24),
          SizedBox(width: 10),
          Text('Logout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _navy)),
        ]),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(fontSize: 14, color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(foregroundColor: _navy),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.logout();
              if (mounted) Navigator.of(context).pushReplacementNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool top, left;
  const _CornerPainter({required this.top, required this.left});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white ..strokeWidth = 3
      ..style = PaintingStyle.stroke ..strokeCap = StrokeCap.round;
    final x  = left ? 0.0 : size.width;
    final y  = top  ? 0.0 : size.height;
    final dx = left ? size.width  : -size.width;
    final dy = top  ? size.height : -size.height;
    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }
  @override
  bool shouldRepaint(_CornerPainter o) => false;
}