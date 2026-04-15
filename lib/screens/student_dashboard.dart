import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../providers/violation_provider.dart';

const _red  = Color(0xFFFD070C);
const _navy = Color(0xFF0F136E);

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _appealController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vp = Provider.of<ViolationProvider>(context, listen: false);
      vp.loadMyViolations();
      vp.loadMyProfile();
      vp.loadMyQrCode();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _appealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = Provider.of<AuthProvider>(context, listen: false)
            .currentUser?.name ?? 'Student';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Student Dashboard',
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _red,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Dashboard'),
            Tab(icon: Icon(Icons.person_rounded), text: 'Profile'),
            Tab(icon: Icon(Icons.qr_code_rounded), text: 'QR Code'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(name),
          _buildProfileTab(),
          _buildQrCodeTab(),
        ],
      ),
    );
  }

  // ── Tab 1: Dashboard ────────────────────────────────────────────────────────
  Widget _buildDashboardTab(String name) {
    return Consumer<ViolationProvider>(
      builder: (context, vp, _) {
        return RefreshIndicator(
          onRefresh: () => vp.loadMyViolations(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Welcome card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_navy, Color(0xFF1A1F8F)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: _navy.withOpacity(0.3),
                      blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.school_rounded,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome, $name!',
                          style: const TextStyle(fontSize: 17,
                              fontWeight: FontWeight.w800, color: Colors.white)),
                      const Text('Student Portal',
                          style: TextStyle(fontSize: 12, color: Colors.white60)),
                    ],
                  )),
                ]),
              ),
              const SizedBox(height: 16),

              // Loading
              if (vp.isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: _navy),
                ))
              else ...[
                // Stats row
                Row(children: [
                  Expanded(child: _statCard('Total',
                      vp.totalCount.toString(), _navy)),
                  const SizedBox(width: 8),
                  Expanded(child: _statCard('Pending',
                      vp.pendingCount.toString(), Colors.orange)),
                  const SizedBox(width: 8),
                  Expanded(child: _statCard('Approved',
                      vp.approvedCount.toString(), Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(child: _statCard('Rejected',
                      vp.rejectedCount.toString(), _red)),
                ]),
                const SizedBox(height: 16),

                // Warning level
                _buildWarningCard(vp.warningLevel),
                const SizedBox(height: 16),

                // Violation history
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: _navy.withOpacity(0.08),
                        blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(children: [
                        Container(width: 4, height: 18,
                            decoration: BoxDecoration(color: _navy,
                                borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        const Text('Violation History',
                            style: TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w700, color: _navy)),
                      ]),
                    ),
                    const Divider(height: 1),
                    if (vp.violations.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: Column(children: [
                          Icon(Icons.check_circle_rounded,
                              size: 56, color: Colors.green),
                          SizedBox(height: 8),
                          Text('No violations recorded!',
                              style: TextStyle(fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green)),
                          Text('Keep up the good work!',
                              style: TextStyle(color: Colors.black45,
                                  fontSize: 12)),
                        ])),
                      )
                    else
                      ...vp.violations.map((v) =>
                          _violationTile(v)).toList(),
                  ]),
                ),
              ],
            ]),
          ),
        );
      },
    );
  }

  Widget _buildWarningCard(String warningLevel) {
    final color = _warningColor(warningLevel);
    final icon  = _warningIcon(warningLevel);
    final action = _warningAction(warningLevel);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Warning Level: $warningLevel',
                style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w700, color: color)),
            Text(action,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        )),
      ]),
    );
  }

  Widget _violationTile(violation) {
    final name    = violation.violationName ?? violation.violationDescription;
    final date    = violation.date.toString().substring(0, 10);
    final status  = violation.statusDescription;
    final severity = violation.severity ?? 'minor';

    return Column(children: [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(children: [
          Expanded(child: Text(name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
          _severityBadge(severity),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date, style: const TextStyle(fontSize: 12, color: Colors.black45)),
            const SizedBox(height: 4),
            Row(children: [
              _statusChip(status),
              const Spacer(),
              if (status == 'Pending')
                TextButton(
                  onPressed: () => _showAppealDialog(violation.id),
                  style: TextButton.styleFrom(
                    foregroundColor: _navy,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Appeal',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
            ]),
          ],
        ),
      ),
      const Divider(height: 1, indent: 16),
    ]);
  }

  // ── Tab 2: Profile ──────────────────────────────────────────────────────────
  Widget _buildProfileTab() {
    return Consumer<ViolationProvider>(
      builder: (context, vp, _) {
        final profile = vp.studentProfile;
        final name = Provider.of<AuthProvider>(context, listen: false)
                .currentUser?.name ?? 'Student';

        return RefreshIndicator(
          onRefresh: () => vp.loadMyProfile(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Avatar card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_navy, Color(0xFF1A1F8F)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                      style: const TextStyle(fontSize: 32,
                          fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(profile['name'] ?? name,
                      style: const TextStyle(fontSize: 18,
                          fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(profile['student_no'] ?? '—',
                      style: const TextStyle(fontSize: 13,
                          color: Colors.white70)),
                ]),
              ),
              const SizedBox(height: 16),

              if (vp.isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: _navy),
                ))
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: _navy.withOpacity(0.08),
                        blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(children: [
                    _profileRow('Course',
                        profile['course'] ?? '—', Icons.school_rounded),
                    _profileRow('Year',
                        profile['year']?.toString() ?? '—',
                        Icons.calendar_today_rounded),
                    _profileRow('Email',
                        profile['email'] ?? '—', Icons.email_rounded),
                    _profileRow('Gender',
                        profile['gender'] ?? '—', Icons.person_rounded),
                    _profileRow('Contact',
                        profile['contact_number'] ?? '—', Icons.phone_rounded),
                    _profileRow('Status',
                        profile['status'] ?? 'Active',
                        Icons.verified_user_rounded),
                    _profileRow('Address',
                        profile['address'] ?? '—',
                        Icons.location_on_rounded, isLast: true),
                  ]),
                ),
            ]),
          ),
        );
      },
    );
  }

  Widget _profileRow(String label, String value, IconData icon,
      {bool isLast = false}) {
    return Column(children: [
      ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: _navy.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: _navy, size: 18),
        ),
        title: Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black45,
                fontWeight: FontWeight.w500)),
        subtitle: Text(value,
            style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.w600, color: Colors.black87)),
      ),
      if (!isLast) const Divider(height: 1, indent: 56),
    ]);
  }

  // ── Tab 3: QR Code ──────────────────────────────────────────────────────────
  Widget _buildQrCodeTab() {
    return Consumer<ViolationProvider>(
      builder: (context, vp, _) {
        final studentNo = Provider.of<AuthProvider>(context, listen: false)
                .currentUser?.studentNo ?? '—';

        return RefreshIndicator(
          onRefresh: () => vp.loadMyQrCode(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: _navy.withOpacity(0.08),
                    blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(children: [
                const Text('My QR Code',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w700, color: _navy)),
                const SizedBox(height: 4),
                const Text('Show this to the Guard for scanning',
                    style: TextStyle(fontSize: 12, color: Colors.black45)),
                const SizedBox(height: 24),

                if (vp.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: _navy),
                  )
                else if (vp.studentQrCode != null &&
                    vp.studentQrCode!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: _navy.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.memory(
                      base64Decode(vp.studentQrCode!),
                      width: 200, height: 200,
                      fit: BoxFit.contain,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: _navy.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.qr_code_rounded,
                        size: 120, color: Colors.black87),
                  ),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _navy.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(studentNo,
                      style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700, color: _navy,
                          letterSpacing: 1)),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  // ── Appeal Dialog ───────────────────────────────────────────────────────────
  void _showAppealDialog(String violationId) {
    _appealController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.gavel_rounded, color: _navy, size: 22),
          SizedBox(width: 8),
          Text('Submit Appeal',
              style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w700, color: _navy)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            'Explain why you are appealing this violation:',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _appealController,
            maxLines: 4,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'e.g. I was not on campus that day...',
              filled: true,
              fillColor: const Color(0xFFF7F8FC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFDDE1EE))),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.black54)),
          ),
          Consumer<ViolationProvider>(
            builder: (ctx, vp, _) => ElevatedButton(
              onPressed: vp.isLoading ? null : () async {
                final text = _appealController.text.trim();
                if (text.isEmpty) return;
                await vp.submitAppeal(violationId, text);
                if (mounted) {
                  Navigator.of(dialogContext).pop();
                  _showSnack(vp.error == null
                      ? 'Appeal submitted successfully'
                      : vp.error!,
                      isError: vp.error != null);
                  if (vp.error == null) vp.loadMyViolations();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: vp.isLoading
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withOpacity(0.12),
            blurRadius: 8, offset: const Offset(0, 3))],
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 22,
            fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 10,
            color: color.withOpacity(0.8)), textAlign: TextAlign.center),
      ]),
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
      child: Text(severity.toUpperCase(),
          style: TextStyle(fontSize: 10,
              fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved': color = Colors.green; break;
      case 'rejected': color = _red; break;
      default:         color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status,
          style: TextStyle(fontSize: 11,
              fontWeight: FontWeight.w600, color: color)),
    );
  }

  Color _warningColor(String level) {
    switch (level.toLowerCase()) {
      case 'warning':  return Colors.yellow.shade700;
      case 'danger':   return Colors.orange;
      case 'critical': return _red;
      default:         return Colors.green;
    }
  }

  IconData _warningIcon(String level) {
    switch (level.toLowerCase()) {
      case 'warning':  return Icons.warning_rounded;
      case 'danger':   return Icons.error_rounded;
      case 'critical': return Icons.dangerous_rounded;
      default:         return Icons.check_circle_rounded;
    }
  }

  String _warningAction(String level) {
    switch (level.toLowerCase()) {
      case 'warning':  return 'Issue written warning';
      case 'danger':   return 'Call parents / schedule counseling';
      case 'critical': return 'Recommended for dismissal';
      default:         return 'No action needed';
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical': return _red;
      case 'major':    return Colors.deepOrange;
      case 'moderate': return Colors.orange;
      default:         return Colors.blue;
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? _red : Colors.green,
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
          Text('Logout', style: TextStyle(fontSize: 18,
              fontWeight: FontWeight.w700, color: _navy)),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}