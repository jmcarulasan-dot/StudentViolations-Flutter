import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

const _red  = Color(0xFFFD070C);
const _navy = Color(0xFF0F136E);

class GuardDashboard extends StatefulWidget {
  const GuardDashboard({super.key});
  @override
  State<GuardDashboard> createState() => _GuardDashboardState();
}

class _GuardDashboardState extends State<GuardDashboard> {
  int _currentIndex = 0;

  final _validateController  = TextEditingController();
  final _remarksController   = TextEditingController();
  final _historyController   = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController   = TextEditingController();

  String? _selectedStudent;
  String? _selectedViolationType;
  String  _selectedSeverity = 'minor';

  final List<String> _violationTypes = [
    'No ID', 'No Uniform', 'Piercing', 'Colored Hair',
    'Late', 'Cutting Class', 'Disruptive Behavior',
    'Vandalism', 'Prohibited Items', 'Other',
  ];
  final List<String> _severities = ['minor', 'moderate', 'major', 'critical'];

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
      body: _buildContent(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
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
                onTap: () => _showValidateDialog(),
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: selected ? _navy : Colors.grey, size: 22),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? _navy : Colors.grey)),
        ]),
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentIndex) {
      case 0:  return _buildRecordTab();
      case 1:  return _buildHistoryTab();
      case 2:  return _buildSummaryTab();
      case 3:  return _buildStudentsTab();
      default: return _buildRecordTab();
    }
  }

  // ── Record Tab ──────────────────────────────────────────────────────────────
  Widget _buildRecordTab() {
    final name = Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'Guard';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Welcome card
        Container(
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
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12)),
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
        ),
        const SizedBox(height: 16),

        _sectionTitle('📋 Record Violation', _red),
        const SizedBox(height: 12),

        // Student dropdown (no data)
        DropdownButtonFormField<String>(
          value: _selectedStudent,
          isExpanded: true,
          decoration: _inputDeco('Select Student *', Icons.person_search_rounded),
          hint: const Text('Choose a student', style: TextStyle(fontSize: 13)),
          items: const [],
          onChanged: (v) => setState(() => _selectedStudent = v),
        ),
        const SizedBox(height: 12),

        // Violation type
        DropdownButtonFormField<String>(
          value: _selectedViolationType,
          decoration: _inputDeco('Violation Type *', Icons.warning_rounded),
          hint: const Text('Select type', style: TextStyle(fontSize: 13)),
          items: _violationTypes.map((t) => DropdownMenuItem(
            value: t, child: Text(t, style: const TextStyle(fontSize: 13)),
          )).toList(),
          onChanged: (v) => setState(() => _selectedViolationType = v),
        ),
        const SizedBox(height: 12),

        // Severity
        DropdownButtonFormField<String>(
          value: _selectedSeverity,
          decoration: _inputDeco('Severity *', Icons.speed_rounded),
          items: _severities.map((s) => DropdownMenuItem(
            value: s, child: Text(s.toUpperCase(), style: const TextStyle(fontSize: 13)),
          )).toList(),
          onChanged: (v) => setState(() => _selectedSeverity = v ?? 'minor'),
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _remarksController,
          maxLines: 2,
          style: const TextStyle(fontSize: 13),
          decoration: _inputDeco('Remarks (Optional)', Icons.note_outlined),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.report_rounded, size: 20),
            label: const Text('Submit Violation',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }

  // ── History Tab ─────────────────────────────────────────────────────────────
  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('📂 Violation History', _navy),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _historyController,
              style: const TextStyle(fontSize: 13),
              decoration: _inputDeco('Enter StudentNo', Icons.search_rounded),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Search', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
        const SizedBox(height: 40),
        Center(child: Column(children: [
          Icon(Icons.search_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text('Search a student to view history',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ])),
      ]),
    );
  }

  // ── Summary Tab ─────────────────────────────────────────────────────────────
  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('📊 Violation Summary', _navy),
        const SizedBox(height: 12),
        TextFormField(
          controller: _startDateController,
          style: const TextStyle(fontSize: 13),
          decoration: _inputDeco('Start Date (yyyy-MM-dd)', Icons.calendar_today_rounded),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _endDateController,
          style: const TextStyle(fontSize: 13),
          decoration: _inputDeco('End Date (yyyy-MM-dd)', Icons.calendar_month_rounded),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 46,
          child: ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: _navy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.bar_chart_rounded),
            label: const Text('Get Summary', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 40),
        Center(child: Column(children: [
          Icon(Icons.bar_chart_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text('Enter a date range to view summary',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ])),
      ]),
    );
  }

  // ── Students Tab ────────────────────────────────────────────────────────────
  Widget _buildStudentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('👥 All Students', _navy),
        const SizedBox(height: 40),
        Center(child: Column(children: [
          Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text('No students found',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ])),
      ]),
    );
  }

  // ── Validate dialog ─────────────────────────────────────────────────────────
  void _showValidateDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.qr_code_rounded, color: _navy, size: 22),
          SizedBox(width: 8),
          Text('Validate Student',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _navy)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // QR placeholder
            Container(
              width: double.infinity, height: 160,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(alignment: Alignment.center, children: [
                Positioned(top: 16, left: 16, child: _corner(true, true)),
                Positioned(top: 16, right: 16, child: _corner(true, false)),
                Positioned(bottom: 16, left: 16, child: _corner(false, true)),
                Positioned(bottom: 16, right: 16, child: _corner(false, false)),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, color: Colors.white54, size: 48),
                    SizedBox(height: 8),
                    Text('Camera available on mobile only',
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ]),
            ),
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
            TextField(
              controller: _validateController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. C26-01-0001-MAN121',
                prefixIcon: const Icon(Icons.badge_rounded, color: _navy, size: 18),
                filled: true,
                fillColor: const Color(0xFFF7F8FC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFDDE1EE))),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _navy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Validate'),
          ),
        ],
      ),
    );
  }

  Widget _corner(bool top, bool left) => SizedBox(
    width: 22, height: 22,
    child: CustomPaint(painter: _CornerPainter(top: top, left: left)),
  );

  Widget _sectionTitle(String text, Color color) {
    return Row(children: [
      Container(width: 4, height: 18,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _navy)),
    ]);
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Colors.black45),
      prefixIcon: Icon(icon, color: _navy, size: 20),
      filled: true, fillColor: const Color(0xFFF7F8FC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDE1EE))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDE1EE))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _navy, width: 1.8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
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
            style: ElevatedButton.styleFrom(backgroundColor: _red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
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
    final x = left ? 0.0 : size.width;
    final y = top  ? 0.0 : size.height;
    canvas.drawLine(Offset(x, y), Offset(x + (left ? size.width : -size.width), y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + (top ? size.height : -size.height)), paint);
  }
  @override
  bool shouldRepaint(_CornerPainter o) => false;
}