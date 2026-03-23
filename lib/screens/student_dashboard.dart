import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  bool _showQr = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vp = Provider.of<ViolationProvider>(context, listen: false);
      // Load all student endpoints on init
      vp.loadMyViolations();
      vp.loadMyProfile();
      vp.loadMyQrCode();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: Consumer<ViolationProvider>(
        builder: (context, vp, child) {
          if (vp.isLoading) {
            return const Center(child: CircularProgressIndicator(color: _navy));
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildDashboardTab(vp),
              _buildProfileTab(vp),
              _buildQrCodeTab(vp),
            ],
          );
        },
      ),
    );
  }

  // ── Tab 1: Dashboard ────────────────────────────────────────────────────────
  Widget _buildDashboardTab(ViolationProvider vp) {
    return RefreshIndicator(
      onRefresh: () => vp.loadMyViolations(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(vp),
            const SizedBox(height: 16),
            _buildStatsRow(vp),
            const SizedBox(height: 16),
            _buildWarningLevelCard(vp),
            const SizedBox(height: 16),
            _buildViolationHistoryCard(vp),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(ViolationProvider vp) {
    final name = vp.studentProfile['name'] ??
        Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'Student';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, Color(0xFF1A1F8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _navy.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, $name!',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 2),
                Text(vp.studentProfile['student_no'] ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
                Text('${vp.studentProfile['course'] ?? ''} — ${vp.studentProfile['year'] ?? ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ViolationProvider vp) {
    return Row(
      children: [
        Expanded(child: _statCard('Total', vp.totalCount, _navy)),
        const SizedBox(width: 8),
        Expanded(child: _statCard('Pending', vp.pendingCount, Colors.orange)),
        const SizedBox(width: 8),
        Expanded(child: _statCard('Approved', vp.approvedCount, Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _statCard('Rejected', vp.rejectedCount, _red)),
      ],
    );
  }

  Widget _statCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3))],
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(count.toString(),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildWarningLevelCard(ViolationProvider vp) {
    final level  = vp.warningLevel;
    final color  = _warningColor(level);
    final icon   = _warningIcon(level);
    final msg    = _warningMessage(level);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Warning Level: ${level.toUpperCase()}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 2),
                Text(msg, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViolationHistoryCard(ViolationProvider vp) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _navy.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(width: 4, height: 18,
                    decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                const Text('Violation History',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _navy)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${vp.violations.length} total',
                      style: const TextStyle(fontSize: 11, color: _red, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          vp.violations.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_rounded, size: 56, color: Colors.green),
                        SizedBox(height: 8),
                        Text('No violations recorded!',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.green)),
                        Text('Keep up the good work!',
                            style: TextStyle(color: Colors.black45, fontSize: 12)),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vp.violations.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final v = vp.violations[index];
                    final statusColor = _statusColor(v.statusDescription);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: _red.withOpacity(0.1),
                        child: const Icon(Icons.warning_amber_rounded, color: _red, size: 20),
                      ),
                      title: Text(v.violationDescription,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('MMM dd, yyyy').format(v.date),
                              style: const TextStyle(fontSize: 11, color: Colors.black45)),
                          if (v.remarks != null && v.remarks!.isNotEmpty)
                            Text(v.remarks!, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                          if (v.severity != null && v.severity!.isNotEmpty)
                            Text('Severity: ${v.severity}',
                                style: const TextStyle(fontSize: 11, color: Colors.black45)),
                          Text('By: ${v.reportedBy ?? 'Unknown'}',
                              style: const TextStyle(fontSize: 11, color: Colors.black45)),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(v.statusDescription,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // ── Tab 2: Profile ──────────────────────────────────────────────────────────
  Widget _buildProfileTab(ViolationProvider vp) {
    final profile = vp.studentProfile;
    if (profile.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: _navy),
            const SizedBox(height: 16),
            const Text('Loading profile...'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => vp.loadMyProfile(),
              style: ElevatedButton.styleFrom(backgroundColor: _navy),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_navy, Color(0xFF1A1F8F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    (profile['name'] ?? 'S').substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(profile['name'] ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                Text(profile['student_no'] ?? '',
                    style: const TextStyle(fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Profile details
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: _navy.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                _profileRow('Course', profile['course'] ?? 'N/A', Icons.school_rounded),
                _profileRow('Year', profile['year'] ?? 'N/A', Icons.calendar_today_rounded),
                _profileRow('Email', profile['email'] ?? 'N/A', Icons.email_rounded),
                _profileRow('Gender', profile['gender'] ?? 'N/A', Icons.person_rounded),
                _profileRow('Contact', profile['contact_number'] ?? 'N/A', Icons.phone_rounded),
                _profileRow('Address', profile['address'] ?? 'N/A', Icons.location_on_rounded),
                _profileRow('Warning Level', vp.warningLevel.toUpperCase(),
                    Icons.warning_rounded, valueColor: _warningColor(vp.warningLevel)),
                _profileRow('Total Violations', vp.totalCount.toString(),
                    Icons.report_rounded, isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(String label, String value, IconData icon,
      {bool isLast = false, Color? valueColor}) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _navy.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _navy, size: 18),
          ),
          title: Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w500)),
          subtitle: Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87)),
        ),
        if (!isLast) const Divider(height: 1, indent: 56),
      ],
    );
  }

  // ── Tab 3: QR Code ──────────────────────────────────────────────────────────
  Widget _buildQrCodeTab(ViolationProvider vp) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: _navy.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                const Text('My QR Code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _navy)),
                const SizedBox(height: 4),
                const Text('Show this to the Guard for scanning',
                    style: TextStyle(fontSize: 12, color: Colors.black45)),
                const SizedBox(height: 20),
                vp.studentQrCode != null
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: _navy.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.memory(
                          base64Decode(vp.studentQrCode!),
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Column(
                        children: [
                          const Icon(Icons.qr_code_rounded, size: 80, color: Colors.grey),
                          const SizedBox(height: 8),
                          const Text('QR Code not available',
                              style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => vp.loadMyQrCode(),
                            style: ElevatedButton.styleFrom(backgroundColor: _navy),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _navy.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    vp.studentProfile['student_no'] ?? '',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: _navy, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Color _warningColor(String level) {
    switch (level.toLowerCase()) {
      case 'red':    return Colors.red;
      case 'orange': return Colors.orange;
      case 'yellow': return Colors.amber;
      default:       return Colors.green;
    }
  }

  IconData _warningIcon(String level) {
    switch (level.toLowerCase()) {
      case 'red':    return Icons.dangerous_rounded;
      case 'orange': return Icons.warning_rounded;
      case 'yellow': return Icons.info_rounded;
      default:       return Icons.check_circle_rounded;
    }
  }

  String _warningMessage(String level) {
    switch (level.toLowerCase()) {
      case 'red':    return '3+ violations — Please report to the SAO office immediately.';
      case 'orange': return '2 violations — Parents have been notified.';
      case 'yellow': return '1 violation — Warning issued. Please comply with school rules.';
      default:       return 'No violations. Keep up the good work!';
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'rejected': return _red;
      default:         return Colors.orange;
    }
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