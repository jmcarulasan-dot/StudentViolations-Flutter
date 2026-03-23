import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/violation_provider.dart';

const _red  = Color(0xFFFD070C);
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vp = Provider.of<ViolationProvider>(context, listen: false);
      vp.loadSaoViolations();
      vp.loadSaoSummary();
      vp.loadAllUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('SAO Dashboard',
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
            Tab(icon: Icon(Icons.report_problem_rounded), text: 'Violations'),
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Summary'),
            Tab(icon: Icon(Icons.people_rounded), text: 'Users'),
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
              _buildViolationsTab(context, vp),
              _buildSummaryTab(context, vp),
              _buildUsersTab(context, vp),
            ],
          );
        },
      ),
    );
  }

  // ── Tab 1: Violations ───────────────────────────────────────────────────────
  Widget _buildViolationsTab(BuildContext context, ViolationProvider vp) {
    final filtered = _filterViolations(vp);

    return RefreshIndicator(
      onRefresh: () => vp.loadSaoViolations(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(vp),
            const SizedBox(height: 16),

            // Stats
            Row(
              children: [
                Expanded(child: _statCard('Total', vp.violations.length, _navy)),
                const SizedBox(width: 8),
                Expanded(child: _statCard('Pending',
                    vp.violations.where((v) => v.statusDescription == 'Pending').length, Colors.orange)),
                const SizedBox(width: 8),
                Expanded(child: _statCard('Approved',
                    vp.violations.where((v) => v.statusDescription == 'Approved').length, Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _statCard('Rejected',
                    vp.violations.where((v) => v.statusDescription == 'Rejected').length, _red)),
              ],
            ),
            const SizedBox(height: 16),

            // Filter chips
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

            // Violations list
            filtered.isEmpty
                ? _buildEmptyState('No violations found')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final v = filtered[index];
                      final statusColor = _statusColor(v.statusDescription);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: _navy.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 3))],
                          border: Border.all(color: statusColor.withOpacity(0.2)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(v.violationDescription,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(v.statusDescription,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Student: ${v.studentId}',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              Text(DateFormat('MMM dd, yyyy').format(v.date),
                                  style: const TextStyle(fontSize: 12, color: Colors.black45)),
                              if (v.severity != null)
                                Text('Severity: ${v.severity}',
                                    style: const TextStyle(fontSize: 12, color: Colors.black45)),
                              Text('By: ${v.reportedBy ?? 'Unknown'}',
                                  style: const TextStyle(fontSize: 12, color: Colors.black45)),

                              // Action buttons — only show for Pending
                              if (v.statusDescription == 'Pending') ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _actionButton(
                                        'Approve',
                                        Icons.check_circle_rounded,
                                        Colors.green,
                                        () => _confirmApprove(context, vp, v.id),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _actionButton(
                                        'Reject',
                                        Icons.cancel_rounded,
                                        _red,
                                        () => _confirmReject(context, vp, v.id),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _deleteButton(() => _confirmDelete(context, vp, v.id)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  // ── Tab 2: Summary ──────────────────────────────────────────────────────────
  Widget _buildSummaryTab(BuildContext context, ViolationProvider vp) {
    final summary = vp.saoSummary;

    return RefreshIndicator(
      onRefresh: () async {
        await vp.loadSaoSummary();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Summary stats
            if (summary.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(child: _summaryStatCard('Total', summary['total']?.toString() ?? '0', _navy)),
                  const SizedBox(width: 8),
                  Expanded(child: _summaryStatCard('Pending', summary['pending']?.toString() ?? '0', Colors.orange)),
                  const SizedBox(width: 8),
                  Expanded(child: _summaryStatCard('Approved', summary['approved']?.toString() ?? '0', Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(child: _summaryStatCard('Rejected', summary['rejected']?.toString() ?? '0', _red)),
                ],
              ),
              const SizedBox(height: 16),

              // By severity
              if (summary['by_severity'] != null) ...[
                _buildCard(
                  title: '📊 By Severity',
                  child: Column(
                    children: (summary['by_severity'] as List).map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(item['severity'] ?? '',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _navy.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('${item['count']}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _navy)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // By type
              if (summary['by_type'] != null) ...[
                _buildCard(
                  title: '📋 By Violation Type',
                  child: Column(
                    children: (summary['by_type'] as List).map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(item['type'] ?? '',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('${item['count']}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _red)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],

            // Student report search
            _buildCard(
              title: '🔍 Student Report',
              child: Column(
                children: [
                  TextFormField(
                    controller: _reportController,
                    style: const TextStyle(fontSize: 13),
                    decoration: _inputDeco('Enter StudentNo for full report', Icons.person_search_rounded),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_reportController.text.isNotEmpty) {
                          await vp.loadStudentReport(_reportController.text.trim());
                          if (vp.studentReport.isNotEmpty && mounted) {
                            _showStudentReport(context, vp.studentReport);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Get Report', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 3: Users ────────────────────────────────────────────────────────────
  Widget _buildUsersTab(BuildContext context, ViolationProvider vp) {
    return RefreshIndicator(
      onRefresh: () => vp.loadAllUsers(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: _buildCard(
          title: '👥 All Users (${vp.users.length})',
          child: vp.users.isEmpty
              ? _buildEmptyState('No users found')
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vp.users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final u = vp.users[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: _roleColor(u.role.name).withOpacity(0.15),
                        child: Text(u.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(fontWeight: FontWeight.w700,
                                color: _roleColor(u.role.name))),
                      ),
                      title: Text(u.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.username,
                              style: const TextStyle(fontSize: 11, color: Colors.black45)),
                          Text(u.gradeSection ?? '',
                              style: const TextStyle(fontSize: 11, color: Colors.black45)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _roleColor(u.role.name).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(u.role.name.toUpperCase(),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                    color: _roleColor(u.role.name))),
                          ),
                          const SizedBox(width: 4),
                          // Delete user button
                          GestureDetector(
                            onTap: () => _confirmDeleteUser(context, vp, u.id, u.name),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, color: _red, size: 16),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  // ── Student report dialog ────────────────────────────────────────────────────
  void _showStudentReport(BuildContext context, Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(report['name'] ?? 'Student Report',
            style: const TextStyle(color: _navy, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogRow('Student No.', report['student_no'] ?? ''),
              _dialogRow('Course', report['course'] ?? ''),
              _dialogRow('Year', report['year'] ?? ''),
              _dialogRow('Email', report['email'] ?? ''),
              _dialogRow('Contact', report['contact_number'] ?? ''),
              _dialogRow('Violations', report['violation_count']?.toString() ?? '0'),
              _dialogRow('Warning Level', (report['warning_level'] ?? 'green').toUpperCase()),
              const Divider(),
              const Text('Violations:',
                  style: TextStyle(fontWeight: FontWeight.w700, color: _navy, fontSize: 13)),
              const SizedBox(height: 6),
              if (report['violations'] != null)
                ...(report['violations'] as List).map((v) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: _red),
                      const SizedBox(width: 6),
                      Expanded(child: Text('${v['type']} — ${v['status']}',
                          style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                )),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _navy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  // ── Action buttons ───────────────────────────────────────────────────────────
  void _confirmApprove(BuildContext context, ViolationProvider vp, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Approve Violation',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700)),
        content: const Text('Approve this violation?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.black54))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await vp.approveViolation(id);
              if (vp.error == null && mounted) {
                _showSnack(context, 'Violation approved!', Colors.green);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _confirmReject(BuildContext context, ViolationProvider vp, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Violation',
            style: TextStyle(color: _red, fontWeight: FontWeight.w700)),
        content: const Text('Reject this violation?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.black54))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await vp.rejectViolation(id);
              if (vp.error == null && mounted) {
                _showSnack(context, 'Violation rejected', _red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ViolationProvider vp, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Violation',
            style: TextStyle(color: _red, fontWeight: FontWeight.w700)),
        content: const Text('Permanently delete this violation?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.black54))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await vp.deleteSaoViolation(id);
              if (vp.error == null && mounted) {
                _showSnack(context, 'Violation deleted', _red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, ViolationProvider vp, String id, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete User',
            style: TextStyle(color: _red, fontWeight: FontWeight.w700)),
        content: Text('Delete user "$name" permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.black54))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await vp.deleteUser(id);
              if (vp.error == null && mounted) {
                _showSnack(context, 'User deleted', _red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  List _filterViolations(ViolationProvider vp) {
    switch (_violationFilter) {
      case 'pending':  return vp.violations.where((v) => v.statusDescription == 'Pending').toList();
      case 'approved': return vp.violations.where((v) => v.statusDescription == 'Approved').toList();
      case 'rejected': return vp.violations.where((v) => v.statusDescription == 'Rejected').toList();
      default:         return vp.violations;
    }
  }

  Widget _buildWelcomeCard(ViolationProvider vp) {
    final name = Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'SAO';
    final pending = vp.violations.where((v) => v.statusDescription == 'Pending').length;
    return Container(
      padding: const EdgeInsets.all(16),
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
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, $name!',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 2),
                const Text('Student Affairs Office — Highest Authority',
                    style: TextStyle(fontSize: 12, color: Colors.white60)),
                if (pending > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _red.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$pending violation${pending > 1 ? 's' : ''} awaiting decision!',
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _navy.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 4, height: 18,
                decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _navy)),
          ]),
          const SizedBox(height: 14),
          child,
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
        boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3))],
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(count.toString(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
              textAlign: TextAlign.center),
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
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _violationFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _violationFilter = value);
        final vp = Provider.of<ViolationProvider>(context, listen: false);
        if (value == 'all') {
          vp.loadSaoViolations();
        } else {
          vp.loadSaoViolationsByStatus(value);
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
        child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black54)),
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _deleteButton(VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.inbox_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Colors.black45),
      prefixIcon: Icon(icon, color: _navy, size: 20),
      filled: true,
      fillColor: const Color(0xFFF7F8FC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE1EE))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE1EE))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _navy, width: 1.8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'rejected': return _red;
      default:         return Colors.orange;
    }
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'guard':    return Colors.blue;
      case 'guidance': return Colors.purple;
      case 'sao':      return _red;
      default:         return Colors.teal;
    }
  }

  void _showSnack(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
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