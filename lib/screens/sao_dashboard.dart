import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/violation_provider.dart';
import 'notifications_screen.dart';

const _red = Color(0xFFFD070C);
const _navy = Color(0xFF0F136E);

class SAODashboard extends StatefulWidget {
  const SAODashboard({super.key});
  @override
  State<SAODashboard> createState() => _SAODashboardState();
}

class _SAODashboardState extends State<SAODashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _violationFilter = 'all';
  final _reportController = TextEditingController();
  final _remarkController = TextEditingController();
  Map<String, dynamic> _studentReport = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vp = Provider.of<ViolationProvider>(context, listen: false);
      vp.loadSaoViolations();
      vp.loadSaoSummary();
      vp.loadAllUsers();
      vp.loadNotifications();
      vp.loadPendingDismissals();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reportController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.name ??
        'SAO';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'SAO Dashboard',
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _red,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabs: const [
            Tab(
              icon: Icon(Icons.report_problem_rounded, size: 18),
              text: 'Violations',
            ),
            Tab(icon: Icon(Icons.bar_chart_rounded, size: 18), text: 'Summary'),
            Tab(icon: Icon(Icons.gavel_rounded, size: 18), text: 'Appeals'),
            Tab(icon: Icon(Icons.people_rounded, size: 18), text: 'Users'),
            Tab(icon: Icon(Icons.block_rounded, size: 18), text: 'Dismiss'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildViolationsTab(name),
          _buildSummaryTab(),
          _buildAppealsTab(),
          _buildUsersTab(),
          _buildDismissTab(),
        ],
      ),
    );
  }
  // ── Dismiss Tab ──────────────────────────────────────────────────────────────
Widget _buildDismissTab() {
  return Consumer<ViolationProvider>(
    builder: (context, vp, _) {
      return RefreshIndicator(
        onRefresh: () async {
          await vp.loadPendingDismissals();
          await vp.loadDismissedStudents();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Pending Dismissal ──
              _buildSectionCard(
                title: '⚠️ Pending Dismissal',
                child: vp.pendingDismissals.isEmpty
                    ? _emptyState('No students pending dismissal')
                    : Column(
                        children: vp.pendingDismissals.map((a) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _red.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _red.withOpacity(0.25)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${a['first_name']} ${a['last_name']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      a['student_no'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black45,
                                      ),
                                    ),
                                    Text(
                                      '${a['course'] ?? ''} • Year ${a['year'] ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black38,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _dismissStudent(a['student_no'], vp),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _red,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Dismiss', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => _cancelDismiss(a['student_no'], vp),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green,
                                  side: const BorderSide(color: Colors.green),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
              ),
              const SizedBox(height: 16),

              // ── Dismissed Students ──
              _buildSectionCard(
                title: '🚫 Dismissed Students',
                child: vp.dismissedStudents.isEmpty
                    ? _emptyState('No dismissed students')
                    : Column(
                        children: vp.dismissedStudents.map((a) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.25)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${a['first_name']} ${a['last_name']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      a['student_no'] ?? '',
                                      style: const TextStyle(fontSize: 12, color: Colors.black45),
                                    ),
                                    Text(
                                      '${a['course'] ?? ''} • Year ${a['year'] ?? ''}',
                                      style: const TextStyle(fontSize: 11, color: Colors.black38),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _cancelDismiss(a['student_no'], vp),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green,
                                  side: const BorderSide(color: Colors.green),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.restore_rounded, size: 14),
                                label: const Text('Restore', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  // ── Violations Tab ──────────────────────────────────────────────────────────
  Widget _buildViolationsTab(String name) {
    return Consumer<ViolationProvider>(
      builder: (context, vp, _) {
        final filtered = _violationFilter == 'all'
            ? vp.violations
            : vp.violations
                  .where(
                    (v) =>
                        v.statusDescription.toLowerCase() ==
                        _violationFilter.toLowerCase(),
                  )
                  .toList();

        return RefreshIndicator(
          onRefresh: () => vp.loadSaoViolations(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
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
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 30,
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
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Student Affairs Office',
                              style: TextStyle(
                                fontSize: 12,
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

                // Stats
                Row(
                  children: [
                    Expanded(
                      child: _statCard('Total', vp.violations.length, _navy),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statCard(
                        'Pending',
                        vp.violations
                            .where((v) => v.statusDescription == 'Pending')
                            .length,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statCard(
                        'Approved',
                        vp.violations
                            .where((v) => v.statusDescription == 'Approved')
                            .length,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statCard(
                        'Rejected',
                        vp.violations
                            .where((v) => v.statusDescription == 'Rejected')
                            .length,
                        _red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _filterChip('Pending', 'pending'),
                      const SizedBox(width: 8),
                      _filterChip('Approved', 'approved'),
                      const SizedBox(width: 8),
                      _filterChip('Rejected', 'rejected'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                if (vp.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: _navy),
                    ),
                  )
                else if (filtered.isEmpty)
                  _emptyState('No violations found')
                else
                  ...filtered.map((v) => _violationCard(v, vp)).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _violationCard(violation, ViolationProvider vp) {
    final status = violation.statusDescription;
    final severity = violation.severity ?? 'minor';
    final isPending = status == 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        violation.violationName ??
                            violation.violationDescription,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        violation.studentId,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        violation.date.toString().substring(0, 10),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black38,
                        ),
                      ),
                      if ((violation.remarks ?? '').isNotEmpty)
                        Text(
                          violation.remarks!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _severityBadge(severity),
                    const SizedBox(height: 6),
                    _statusChip(status),
                  ],
                ),
              ],
            ),
          ),

          if (isPending) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _approveViolation(violation.id, vp),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                      label: const Text(
                        'Approve',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectViolation(violation.id, vp),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _red,
                        side: const BorderSide(color: _red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.cancel_rounded, size: 16),
                      label: const Text(
                        'Reject',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, size: 20),
                    color: Colors.grey.shade400,
                    onPressed: () => _deleteViolation(violation.id, vp),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          ] else ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.delete_rounded,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                    onPressed: () => _deleteViolation(violation.id, vp),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Summary Tab ─────────────────────────────────────────────────────────────
  Widget _buildSummaryTab() {
    return Consumer<ViolationProvider>(
      builder: (context, vp, _) {
        final summary = vp.saoSummary;

        return RefreshIndicator(
          onRefresh: () async {
            await vp.loadSaoSummary();
            await vp.loadPendingDismissals();
            await vp.loadDismissedStudents();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _summaryStatCard(
                        'Total',
                        summary['total']?.toString() ?? '—',
                        _navy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _summaryStatCard(
                        'Pending',
                        summary['pending']?.toString() ?? '—',
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _summaryStatCard(
                        'Approved',
                        summary['approved']?.toString() ?? '—',
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _summaryStatCard(
                        'Rejected',
                        summary['rejected']?.toString() ?? '—',
                        _red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildSectionCard(
                  title: '📊 By Severity',
                  child: summary.isEmpty || summary['by_severity'] == null
                      ? _emptyState('No severity data')
                      : Column(
                          children: (summary['by_severity'] as List)
                              .map(
                                (s) => _summaryRow(
                                  s['severity'] ?? '',
                                  s['count']?.toString() ?? '0',
                                  _severityColor(s['severity'] ?? ''),
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 16),

                _buildSectionCard(
                  title: '📋 By Violation Type',
                  child: summary.isEmpty || summary['by_type'] == null
                      ? _emptyState('No type data')
                      : Column(
                          children: (summary['by_type'] as List)
                              .map(
                                (t) => _summaryRow(
                                  t['type'] ?? '',
                                  t['count']?.toString() ?? '0',
                                  _navy,
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 16),

              
                // Student report search
                _buildSectionCard(
                  title: '🔍 Student Report',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _reportController,
                        style: const TextStyle(fontSize: 13),
                        decoration: _inputDeco(
                          'Enter StudentNo for full report',
                          Icons.person_search_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: vp.isLoading ? null : _getStudentReport,
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
                              : const Icon(Icons.search_rounded),
                          label: Text(
                            vp.isLoading ? 'Loading...' : 'Get Report',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      if (_studentReport.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _buildStudentReportCard(_studentReport, vp),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentReportCard(
    Map<String, dynamic> report,
    ViolationProvider vp,
  ) {
    final violations = (report['violations'] as List?) ?? [];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _navy.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _navy,
                        ),
                      ),
                      Text(
                        '${report['student_no'] ?? ''} • ${report['course'] ?? ''} ${report['year'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        'Status: ${report['status'] ?? 'Active'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                _warningBadge(report['warning_level'] ?? 'Safe'),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                if (report['status'] == 'PendingDismissal')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _dismissStudent(report['student_no'], vp),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.block_rounded, size: 16),
                      label: const Text(
                        'Confirm Dismiss',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                if (report['status'] == 'PendingDismissal' ||
                    report['status'] == 'Dismissed') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelDismiss(report['student_no'], vp),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.restore_rounded, size: 16),
                      label: const Text(
                        'Cancel Dismiss',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (violations.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Text(
                'Violations (${violations.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
            ),
            ...violations
                .take(5)
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
                      '${v['date'] ?? ''} • ${v['recorded_by'] ?? ''}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: _statusChip(v['status'] ?? 'Pending'),
                  ),
                )
                .toList(),
            if (violations.length > 5)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: Text(
                    '+${violations.length - 5} more',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ── Appeals Tab ──────────────────────────────────────────────────────────────
  Widget _buildAppealsTab() {
    return Consumer<ViolationProvider>(
      builder: (context, vp, _) {
        // Only load appeals when this tab is viewed
        return RefreshIndicator(
          onRefresh: () => _loadAppeals(vp),
          child: FutureBuilder(
            future: _loadAppeals(vp),
            builder: (ctx, snapshot) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_rounded,
                            color: Colors.blue,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Only violations where a student has submitted an appeal are shown here.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (vp.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: _navy),
                        ),
                      )
                    else
                      _AppealsListFromBackend(
                        onReview: (violationId) =>
                            _showAppealReviewDialog(violationId),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _loadAppeals(ViolationProvider vp) async {
    // Appeals are loaded separately via the backend's /appeals endpoint
    // which only returns violations with AppealStatus = 'Pending'
  }

  // ── Users Tab ────────────────────────────────────────────────────────────────
  Widget _buildUsersTab() {
    return Consumer<ViolationProvider>(
      builder: (context, vp, _) {
        return RefreshIndicator(
          onRefresh: () => vp.loadAllUsers(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: _buildSectionCard(
              title: '👥 All Users (${vp.users.length})',
              child: vp.isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: _navy),
                      ),
                    )
                  : vp.users.isEmpty
                  ? _emptyState('No users found')
                  : Column(
                      children: vp.users.map((u) => _userTile(u, vp)).toList(),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _userTile(user, ViolationProvider vp) {
  final roleDisplay = _roleLabel(user.role.toString().split('.').last);
  final roleColor = _roleColor(roleDisplay);

  return Column(
    children: [
      ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: roleColor.withOpacity(0.12),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: TextStyle(color: roleColor, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(
          '@${user.username} • ${roleDisplay.toUpperCase()}',
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_rounded, color: _navy, size: 20),
              onPressed: () => _showEditUserDialog(user, vp),
            ),
            IconButton(
              icon: Icon(Icons.delete_rounded, color: Colors.grey.shade400, size: 20),
              onPressed: () => _deleteUser(user.id, vp),
            ),
          ],
        ),
      ),
      const Divider(height: 1, indent: 56),
    ],
  );
}

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'sao':
        return 'SAO';
      case 'guard':
        return 'Guard';
      case 'guidance':
        return 'Guidance';
      default:
        return role;
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────────
  Future<void> _approveViolation(String id, ViolationProvider vp) async {
    await vp.approveViolation(id);
    _showSnack(
      vp.error == null ? 'Violation approved' : vp.error!,
      isError: vp.error != null,
    );
  }

  Future<void> _rejectViolation(String id, ViolationProvider vp) async {
    await vp.rejectViolation(id);
    _showSnack(
      vp.error == null ? 'Violation rejected' : vp.error!,
      isError: vp.error != null,
    );
  }

  Future<void> _deleteViolation(String id, ViolationProvider vp) async {
    final confirm = await _showConfirmDialog(
      'Delete Violation',
      'This cannot be undone.',
    );
    if (!confirm) return;
    await vp.deleteSaoViolation(id);
    _showSnack(
      vp.error == null ? 'Violation deleted' : vp.error!,
      isError: vp.error != null,
    );
  }

  Future<void> _getStudentReport() async {
    final studentNo = _reportController.text.trim();
    if (studentNo.isEmpty) {
      _showSnack('Enter a StudentNo', isError: true);
      return;
    }
    final vp = Provider.of<ViolationProvider>(context, listen: false);
    await vp.loadStudentReport(studentNo);
    setState(() => _studentReport = vp.studentReport);
  }

  Future<void> _dismissStudent(String? studentNo, ViolationProvider vp) async {
    if (studentNo == null) return;
    final confirm = await _showConfirmDialog(
      'Confirm Dismissal',
      'This will permanently dismiss the student. Are you sure?',
    );
    if (!confirm) return;
    await vp.dismissStudent(studentNo);
    _showSnack(
      vp.error == null ? 'Student dismissed' : vp.error!,
      isError: vp.error != null,
    );
    if (vp.error == null) {
      await vp.loadStudentReport(studentNo);
      setState(() => _studentReport = vp.studentReport);
    }
  }

  Future<void> _cancelDismiss(String? studentNo, ViolationProvider vp) async {
    if (studentNo == null) return;
    await vp.cancelDismiss(studentNo);
    _showSnack(
      vp.error == null ? 'Dismissal cancelled' : vp.error!,
      isError: vp.error != null,
    );
    if (vp.error == null) {
      await vp.loadStudentReport(studentNo);
      setState(() => _studentReport = vp.studentReport);
    }
  }

 Future<void> _deleteUser(String id, ViolationProvider vp) async {
    final confirm = await _showConfirmDialog(
      'Delete User',
      'This cannot be undone.',
    );
    if (!confirm) return;
    await vp.deleteUser(id);
    _showSnack(
      vp.error == null ? 'User deleted' : vp.error!,
      isError: vp.error != null,
    );
  }

  void _showEditUserDialog(user, ViolationProvider vp) {
    final firstNameController = TextEditingController(text: user.name.split(' ').first);
    final lastNameController = TextEditingController(text: user.name.split(' ').last);
    final emailController = TextEditingController();
    final contactController = TextEditingController(text: user.contactNumber ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit User', style: TextStyle(color: _navy, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: firstNameController, decoration: _inputDeco('First Name', Icons.person_rounded)),
              const SizedBox(height: 10),
              TextField(controller: lastNameController, decoration: _inputDeco('Last Name', Icons.person_rounded)),
              const SizedBox(height: 10),
              TextField(controller: emailController, decoration: _inputDeco('Email', Icons.email_rounded)),
              const SizedBox(height: 10),
              TextField(controller: contactController, decoration: _inputDeco('Contact Number', Icons.phone_rounded)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await vp.updateUser(user.id, {
                'firstName': firstNameController.text.trim(),
                'lastName': lastNameController.text.trim(),
                if (emailController.text.trim().isNotEmpty) 'email': emailController.text.trim(),
                if (contactController.text.trim().isNotEmpty) 'contactNumber': contactController.text.trim(),
              });
              if (mounted) {
                Navigator.of(dialogContext).pop();
                _showSnack(vp.error == null ? 'User updated' : vp.error!, isError: vp.error != null);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAppealReviewDialog(String violationId) {
    _remarkController.clear();
    String selectedStatus = 'Approved';
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.rate_review_rounded, color: _navy, size: 22),
              SizedBox(width: 8),
              Text(
                'Review Appeal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Decision',
                  filled: true,
                  fillColor: const Color(0xFFF7F8FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                items: ['Approved', 'Rejected']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedStatus = v ?? 'Approved'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _remarkController,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Enter remarks...',
                  filled: true,
                  fillColor: const Color(0xFFF7F8FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFDDE1EE)),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            Consumer<ViolationProvider>(
              builder: (ctx, vp, _) => ElevatedButton(
                onPressed: vp.isLoading
                    ? null
                    : () async {
                        await vp.saoReviewAppeal(
                          violationId,
                          selectedStatus,
                          _remarkController.text.trim(),
                        );
                        if (mounted) {
                          Navigator.of(dialogContext).pop();
                          _showSnack(
                            vp.error == null ? 'Appeal reviewed' : vp.error!,
                            isError: vp.error != null,
                          );
                        }
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
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, color: _navy),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: _red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _summaryStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _violationFilter == value;
    return GestureDetector(
      onTap: () async {
        setState(() => _violationFilter = value);
        final vp = Provider.of<ViolationProvider>(context, listen: false);
        if (value == 'all') {
          await vp.loadSaoViolations();
        } else {
          await vp.loadSaoViolationsByStatus(
            value[0].toUpperCase() + value.substring(1),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _navy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _navy : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black54,
          ),
        ),
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

  Color _warningColor(String level) {
    switch (level.toLowerCase()) {
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

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'guard':
        return Colors.blue;
      case 'guidance':
        return Colors.teal;
      case 'sao':
        return _red;
      default:
        return _navy;
    }
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

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
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

// ── Appeals list widget — fetches directly from SAO appeals endpoint ──────────
class _AppealsListFromBackend extends StatefulWidget {
  final void Function(String violationId) onReview;
  const _AppealsListFromBackend({required this.onReview});

  @override
  State<_AppealsListFromBackend> createState() =>
      _AppealsListFromBackendState();
}

class _AppealsListFromBackendState extends State<_AppealsListFromBackend> {
  List<Map<String, dynamic>> _appeals = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final vp = Provider.of<ViolationProvider>(context, listen: false);
      final appeals = await vp.loadSaoAppeals();
      setState(() {
        _appeals = appeals;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFF0F136E)),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(
          'Error: $_error',
          style: const TextStyle(color: Colors.red, fontSize: 13),
        ),
      );
    }
    if (_appeals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(Icons.gavel_rounded, size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'No pending appeals',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Students have not submitted any appeals yet.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: _appeals.map((a) => _appealCard(a)).toList());
  }

  Widget _appealCard(Map<String, dynamic> a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        a['type'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'APPEAL PENDING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Student: ${a['student_no'] ?? ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  'Violation Date: ${(a['date'] ?? '').toString().substring(0, 10)}',
                  style: const TextStyle(fontSize: 11, color: Colors.black38),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Student\'s Appeal:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a['appeal_text'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => widget.onReview(a['id'].toString()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F136E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.rate_review_rounded, size: 16),
                label: const Text(
                  'Review This Appeal',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification Bell ────────────────────────────────────────────────────────
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
