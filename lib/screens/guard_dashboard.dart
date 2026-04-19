import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/violation_provider.dart';
import '../models/violation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  final _validateController = TextEditingController();

  String? _selectedStudentNo;
  String? _selectedStudentName;
  String? _selectedViolationType;
  String _selectedSeverity = 'minor';

  // Results
  Map<String, dynamic> _historyResult = {};
  Map<String, dynamic> _summaryResult = {};
  Map<String, dynamic> _validateResult = {};

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
      Provider.of<ViolationProvider>(context, listen: false).loadStudents();
    });
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _historyController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _validateController.dispose();
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
              _navItem(0, Icons.report_rounded, 'Record'),
              _navItem(1, Icons.history_rounded, 'History'),
              GestureDetector(
                onTap: () => _showValidateDialog(),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _navy,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _navy.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
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
        return _buildRecordTab();
      case 1:
        return _buildHistoryTab();
      case 2:
        return _buildSummaryTab();
      case 3:
        return _buildStudentsTab();
      default:
        return _buildRecordTab();
    }
  }

  //Record Tab
  Widget _buildRecordTab() {
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
                            'Tap 🔍 in the nav bar to scan student QR code',
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

              _sectionTitle('📋 Record Violation', _red),
              const SizedBox(height: 12),

              // Student dropdown
              DropdownButtonFormField<String>(
                value: _selectedStudentNo,
                isExpanded: true,
                decoration: _inputDeco(
                  'Select Student *',
                  Icons.person_search_rounded,
                ),
                hint: vp.isLoading
                    ? const Text(
                        'Loading students...',
                        style: TextStyle(fontSize: 13),
                      )
                    : const Text(
                        'Choose a student',
                        style: TextStyle(fontSize: 13),
                      ),
                items: vp.students
                    .map(
                      (s) => DropdownMenuItem(
                        value: s.studentNo ?? s.id,
                        child: Text(
                          '${s.name} (${s.studentNo ?? s.id})',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedStudentNo = v;
                    _selectedStudentName = vp.students
                        .firstWhere(
                          (s) => (s.studentNo ?? s.id) == v,
                          orElse: () => vp.students.first,
                        )
                        .name;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Violation type
              DropdownButtonFormField<String>(
                value: _selectedViolationType,
                decoration: _inputDeco(
                  'Violation Type *',
                  Icons.warning_rounded,
                ),
                hint: const Text('Select type', style: TextStyle(fontSize: 13)),
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

              // Severity
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
                decoration: _inputDeco(
                  'Remarks (Optional)',
                  Icons.note_outlined,
                ),
              ),
              const SizedBox(height: 16),

              if (vp.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    vp.error!,
                    style: const TextStyle(color: _red, fontSize: 12),
                  ),
                ),

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
          ),
        );
      },
    );
  }

  // History Tab
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

              // Student info card
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

                // Violations list
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

  // Summary Tab
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
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
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
            ],
          ),
        );
      },
    );
  }

  // Students Tab
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

  // Validate Dialog
  void _showValidateDialog() {
    _validateController.clear();
    _validateResult = {};
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.qr_code_rounded, color: _navy, size: 22),
              SizedBox(width: 8),
              Text(
                'Validate Student',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // QR placeholder
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: MobileScanner(
                      onDetect: (capture) {
                        final barcode = capture.barcodes.first;
                        final value = barcode.rawValue;
                        if (value != null) {
                          _validateController.text = value;
                        }
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'OR enter manually',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                ),
                TextField(
                  controller: _validateController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'e.g. C26-01-0001-MAN121',
                    prefixIcon: const Icon(
                      Icons.badge_rounded,
                      color: _navy,
                      size: 18,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7F8FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFDDE1EE)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),

                // Result
                if (_validateResult.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _warningColor(
                        _validateResult['warning_level'],
                      ).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _warningColor(
                          _validateResult['warning_level'],
                        ).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _validateResult['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _validateResult['student_no'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _warningBadge(
                              _validateResult['warning_level'] ?? 'Safe',
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_validateResult['violation_count'] ?? 0} violation(s)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            Consumer<ViolationProvider>(
              builder: (ctx, vp, _) => ElevatedButton(
                onPressed: vp.isLoading
                    ? null
                    : () async {
                        final studentNo = _validateController.text.trim();
                        if (studentNo.isEmpty) return;
                        await vp.validateStudent(studentNo);
                        setDialogState(() {
                          _validateResult = vp.validatedStudent;
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                    : const Text('Validate'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Actions
  Future<void> _submitViolation() async {
    if (_selectedStudentNo == null) {
      _showSnack('Please select a student', isError: true);
      return;
    }
    if (_selectedViolationType == null) {
      _showSnack('Please select a violation type', isError: true);
      return;
    }

    final vp = Provider.of<ViolationProvider>(context, listen: false);
    await vp.recordViolation(
      studentId: _selectedStudentNo!,
      type: _parseViolationType(_selectedViolationType!),
      reportedBy:
          Provider.of<AuthProvider>(context, listen: false).currentUser?.name ??
          '',
      remarks: _remarksController.text.trim(),
      severity: _selectedSeverity,
      violationName: _selectedViolationType!,
    );

    if (vp.error == null) {
      _showSnack('Violation recorded successfully');
      setState(() {
        _selectedStudentNo = null;
        _selectedStudentName = null;
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
    await vp.validateStudent(studentNo);
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

  // Helpers
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
            v['date'] ?? '',
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
      case 'warning':
        return Colors.yellow.shade700;
      case 'danger':
        return Colors.orange;
      case 'critical':
        return _red;
      default:
        return Colors.green;
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

  Widget _corner(bool top, bool left) => SizedBox(
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
