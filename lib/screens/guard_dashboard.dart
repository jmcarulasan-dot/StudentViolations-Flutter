import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/violation_provider.dart';
import '../models/violation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'notifications_screen.dart';

const _red = Color(0xFFFD070C);
const _navy = Color(0xFF0F136E);

class GuardDashboard extends StatefulWidget {
  const GuardDashboard({super.key});
  @override
  State<GuardDashboard> createState() => _GuardDashboardState();
}

class _GuardDashboardState extends State<GuardDashboard> {
  int _currentIndex = 0;

  final _remarksController = TextEditingController();
  final _historyController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  // QR / Validate state
  String? _scannedStudentNo;
  Map<String, dynamic> _scannedStudentData = {};
  bool _scannerActive = true;

  // Record violation form state (used AFTER scanning)
  String? _selectedViolationType;
  String _selectedSeverity = 'minor';

  Map<String, dynamic> _historyResult = {};
  Map<String, dynamic> _summaryResult = {};

  final List<String> _violationTypes = [
    'No ID',
    'No Uniform',
    'Piercing',
    'Colored Hair',
    'Late',
    'Cutting Class',
    'Disruptive Behavior',
    'Vandalism',
    'Prohibited Items',
    'Other',
  ];
  final List<String> _severities = ['minor', 'moderate', 'major', 'critical'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vp = Provider.of<ViolationProvider>(context, listen: false);
      vp.loadStudents();
      vp.loadNotifications();
    });
  }

  @override
  void dispose() {
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
        title: const Text(
          'Guard Dashboard',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 3,
        actions: [
          _NotificationBell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: _buildContent(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.qr_code_scanner_rounded, 'Scan & Record'),
              _navItem(1, Icons.history_rounded, 'History'),
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
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? _navy : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentIndex) {
      case 0:
        return _buildScanAndRecordTab();
      case 1:
        return _buildHistoryTab();
      case 2:
        return _buildSummaryTab();
      case 3:
        return _buildStudentsTab();
      default:
        return _buildScanAndRecordTab();
    }
  }

  // ── TAB 0: Scan QR → show student data → record violation ──────────────────
  Widget _buildScanAndRecordTab() {
    final name =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.name ??
        'Guard';

    return Consumer<ViolationProvider>(
      builder: (context, vp, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_navy, Color(0xFF1A1F8F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _navy.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, $name!',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Scan student QR code to record a violation',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── QR Scanner ──────────────────────────────────────────────────
              _sectionTitle('📷 Scan Student QR Code', _navy),
              const SizedBox(height: 10),

              Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: _navy.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _scannerActive
                      ? Stack(
                          children: [
                            MobileScanner(
                              onDetect: (capture) {
                                final value = capture.barcodes.first.rawValue;
                                if (value != null &&
                                    value != _scannedStudentNo) {
                                  setState(() {
                                    _scannedStudentNo = value;
                                    _scannerActive = false;
                                    _scannedStudentData = {};
                                    _selectedViolationType = null;
                                    _selectedSeverity = 'minor';
                                    _remarksController.clear();
                                  });
                                  _loadScannedStudent(value, vp);
                                }
                              },
                            ),
                            // Scan overlay corners
                            Positioned.fill(
                              child: Center(
                                child: SizedBox(
                                  width: 160,
                                  height: 160,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        child: _corner(top: true, left: true),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: _corner(top: true, left: false),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        child: _corner(top: false, left: true),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: _corner(top: false, left: false),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Point camera at student QR code',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          color: Colors.black,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green,
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Scanned: ${_scannedStudentNo ?? ''}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _scannerActive = true;
                                      _scannedStudentNo = null;
                                      _scannedStudentData = {};
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.qr_code_scanner_rounded,
                                    color: Colors.white70,
                                  ),
                                  label: const Text(
                                    'Scan Again',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // Manual entry fallback
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      style: const TextStyle(fontSize: 13),
                      decoration: _inputDeco(
                        'Or enter StudentNo manually',
                        Icons.badge_rounded,
                      ),
                      onFieldSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          setState(() {
                            _scannedStudentNo = val.trim().toUpperCase();
                            _scannerActive = false;
                            _scannedStudentData = {};
                          });
                          _loadScannedStudent(val.trim().toUpperCase(), vp);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Student Info Card (after scan) ──────────────────────────────
              if (vp.isLoading && _scannedStudentData.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: _navy),
                  ),
                ),

              if (_scannedStudentData.isNotEmpty) ...[
                _buildStudentInfoCard(_scannedStudentData),
                const SizedBox(height: 16),

                // ── Violation Form ──────────────────────────────────────────
                _sectionTitle('📋 Record Violation', _red),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _selectedViolationType,
                  decoration: _inputDeco(
                    'Violation Type *',
                    Icons.warning_rounded,
                  ),
                  hint: const Text(
                    'Select type',
                    style: TextStyle(fontSize: 13),
                  ),
                  items: _violationTypes
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t, style: const TextStyle(fontSize: 13)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedViolationType = v),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _selectedSeverity,
                  decoration: _inputDeco('Severity *', Icons.speed_rounded),
                  items: _severities
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            s.toUpperCase(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedSeverity = v ?? 'minor'),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _remarksController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13),
                  decoration: _inputDeco('Remarks ()', Icons.note_outlined),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: vp.isLoading ? null : _submitViolation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: vp.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.report_rounded, size: 20),
                    label: Text(
                      vp.isLoading ? 'Submitting...' : 'Submit Violation',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentInfoCard(Map<String, dynamic> data) {
    final level = data['warning_level'] ?? 'green';
    final color = _warningColor(level);
    final violations = (data['violations'] as List?) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withOpacity(0.15),
                  child: Text(
                    (data['name'] ?? 'S')[0].toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: _navy,
                        ),
                      ),
                      Text(
                        data['student_no'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                _warningBadge(level),
              ],
            ),
          ),
          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _miniStat(
                  'Violations',
                  (data['violation_count'] ?? 0).toString(),
                  color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _warningAction(level),
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Recent violations
          if (violations.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: Text(
                'Recent Violations',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            ...violations
                .take(2)
                .map(
                  (v) => ListTile(
                    dense: true,
                    title: Text(
                      v['type'] ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${(v['date'] ?? '').toString().substring(0, 10)} • ${v['severity'] ?? ''}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: _statusChip(v['status'] ?? 'Pending'),
                  ),
                ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  // ── History Tab ─────────────────────────────────────────────────────────────
  Widget _buildHistoryTab() {
    return Consumer<ViolationProvider>(
      builder: (context, vp, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('📂 Violation History', _navy),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _historyController,
                      style: const TextStyle(fontSize: 13),
                      decoration: _inputDeco(
                        'Enter StudentNo (e.g. C26-01-0001-MAN121)',
                        Icons.search_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: vp.isLoading ? null : _searchHistory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: vp.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Search',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_historyResult.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _navy.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _navy.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_rounded, color: _navy, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _historyResult['name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: _navy,
                              ),
                            ),
                            Text(
                              _historyResult['student_no'] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _warningBadge(_historyResult['warning_level'] ?? 'Safe'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (((_historyResult['violations'] as List?) ?? []).isEmpty)
                  _emptyState('No violations found')
                else
                  ...(_historyResult['violations'] as List)
                      .map((v) => _violationCard(v))
                      .toList(),
              ] else
                _emptyState('Search a student to view history'),
            ],
          ),
        );
      },
    );
  }

  // ── Summary Tab ─────────────────────────────────────────────────────────────
  Widget _buildSummaryTab() {
    return Consumer<ViolationProvider>(
      builder: (context, vp, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('📊 Violation Summary', _navy),
              const SizedBox(height: 12),
              TextFormField(
                controller: _startDateController,
                style: const TextStyle(fontSize: 13),
                decoration: _inputDeco(
                  'Start Date (yyyy-MM-dd)',
                  Icons.calendar_today_rounded,
                ),
                onTap: () => _pickDate(_startDateController),
                readOnly: true,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _endDateController,
                style: const TextStyle(fontSize: 13),
                decoration: _inputDeco(
                  'End Date (yyyy-MM-dd)',
                  Icons.calendar_month_rounded,
                ),
                onTap: () => _pickDate(_endDateController),
                readOnly: true,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: vp.isLoading ? null : _getSummary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: vp.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.bar_chart_rounded),
                  label: Text(
                    vp.isLoading ? 'Loading...' : 'Get Summary',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_summaryResult.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        'Total Violations',
                        _summaryResult['totalViolations'].toString(),
                        _navy,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCard(
                        'Top Violation',
                        _summaryResult['topViolation'] ?? 'N/A',
                        _red,
                      ),
                    ),
                  ],
                ),
              ] else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter a date range to view summary',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Students Tab ─────────────────────────────────────────────────────────────
  Widget _buildStudentsTab() {
    return Consumer<ViolationProvider>(
      builder: (context, vp, _) {
        return RefreshIndicator(
          onRefresh: () => vp.loadStudents(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('👥 All Students', _navy),
                const SizedBox(height: 4),
                Text(
                  '${vp.students.length} students registered',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 14),

                if (vp.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: _navy),
                    ),
                  )
                else if (vp.students.isEmpty)
                  _emptyState('No students found')
                else
                  ...vp.students
                      .map(
                        (s) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _navy.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: _navy.withOpacity(0.1),
                                child: Text(
                                  s.name.isNotEmpty
                                      ? s.name[0].toUpperCase()
                                      : 'S',
                                  style: const TextStyle(
                                    color: _navy,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      s.studentNo ?? s.id,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    if (s.gradeSection != null &&
                                        s.gradeSection != ' - ')
                                      Text(
                                        s.gradeSection!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black38,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────────
  Future<void> _loadScannedStudent(
    String studentNo,
    ViolationProvider vp,
  ) async {
    await vp.validateStudent(studentNo);
    setState(() {
      _scannedStudentData = vp.validatedStudent;
    });
  }

  Future<void> _submitViolation() async {
    if (_scannedStudentNo == null || _scannedStudentData.isEmpty) {
      _showSnack('Please scan a student first', isError: true);
      return;
    }
    if (_selectedViolationType == null) {
      _showSnack('Please select a violation type', isError: true);
      return;
    }

    final vp = Provider.of<ViolationProvider>(context, listen: false);
    await vp.recordViolation(
      studentId: _scannedStudentNo!,
      type: _parseViolationType(_selectedViolationType!),
      reportedBy:
          Provider.of<AuthProvider>(context, listen: false).currentUser?.name ??
          '',
      remarks: _remarksController.text.trim(),
      severity: _selectedSeverity,
      violationName: _selectedViolationType!,
    );

    if (vp.error == null) {
      _showSnack('Violation recorded successfully! ✓');
      // Reload student data to show updated violation count
      await _loadScannedStudent(_scannedStudentNo!, vp);
      setState(() {
        _selectedViolationType = null;
        _selectedSeverity = 'minor';
        _remarksController.clear();
      });
    } else {
      _showSnack(vp.error!, isError: true);
    }
  }

  Future<void> _searchHistory() async {
    final studentNo = _historyController.text.trim();
    if (studentNo.isEmpty) {
      _showSnack('Please enter a StudentNo', isError: true);
      return;
    }
    final vp = Provider.of<ViolationProvider>(context, listen: false);
    await vp.validateStudent(studentNo.toUpperCase());
    setState(() {
      _historyResult = vp.validatedStudent;
    });
  }

  Future<void> _getSummary() async {
    if (_startDateController.text.isEmpty || _endDateController.text.isEmpty) {
      _showSnack('Please select both dates', isError: true);
      return;
    }
    final vp = Provider.of<ViolationProvider>(context, listen: false);
    await vp.loadViolationSummary(
      _startDateController.text,
      _endDateController.text,
    );
    setState(() {
      _summaryResult = vp.violationSummary;
    });
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _navy)),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  ViolationType _parseViolationType(String type) {
    final t = type.toLowerCase();
    if (t.contains('uniform')) return ViolationType.noUniform;
    if (t.contains('piercing')) return ViolationType.piercing;
    if (t.contains('hair') || t.contains('color'))
      return ViolationType.coloredHair;
    return ViolationType.noId;
  }

  Widget _violationCard(dynamic v) {
    final status = v['status'] ?? 'Pending';
    final severity = v['severity'] ?? 'minor';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  v['type'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              _severityBadge(severity),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            v['date']?.toString().substring(0, 10) ?? '',
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
          if ((v['details'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              v['details'],
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 6),
          _statusChip(status),
        ],
      ),
    );
  }

  Widget _warningBadge(String level) {
    final color = _warningColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        level,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _severityBadge(String severity) {
    final color = _severityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = _red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _warningColor(String? level) {
    switch ((level ?? '').toLowerCase()) {
      case 'yellow':
        return Colors.yellow.shade700;
      case 'orange':
        return Colors.orange;
      case 'red':
        return _red;
      default:
        return Colors.green;
    }
  }

  String _warningAction(String level) {
    switch (level.toLowerCase()) {
      case 'yellow':
        return 'Issue written warning';
      case 'orange':
        return 'Call parents / schedule counseling';
      case 'red':
        return 'Recommended for dismissal';
      default:
        return 'No action needed';
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return _red;
      case 'major':
        return Colors.deepOrange;
      case 'moderate':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _navy,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Colors.black45),
      prefixIcon: Icon(icon, color: _navy, size: 20),
      filled: true,
      fillColor: const Color(0xFFF7F8FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE1EE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE1EE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _navy, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _corner({required bool top, required bool left}) => SizedBox(
    width: 22,
    height: 22,
    child: CustomPaint(
      painter: _CornerPainter(top: top, left: left),
    ),
  );

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: _red, size: 24),
            SizedBox(width: 10),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _navy,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    canvas.drawLine(
      Offset(x, y),
      Offset(x + (left ? size.width : -size.width), y),
      paint,
    );
    canvas.drawLine(
      Offset(x, y),
      Offset(x, y + (top ? size.height : -size.height)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CornerPainter o) => false;
}

// ── Reusable notification bell widget ────────────────────────────────────────
class _NotificationBell extends StatelessWidget {
  final VoidCallback onTap;
  const _NotificationBell({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<ViolationProvider>(
      builder: (ctx, vp, _) {
        final unread = vp.notifications.where((n) => !n.isRead).length;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_rounded),
              onPressed: onTap,
            ),
            if (unread > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFD070C),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unread > 9 ? '9+' : unread.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
