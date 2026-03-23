import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/violation_provider.dart';

const _red  = Color(0xFFFD070C);
const _navy = Color(0xFF0F136E);

class GuidanceDashboard extends StatefulWidget {
  const GuidanceDashboard({super.key});
  @override
  State<GuidanceDashboard> createState() => _GuidanceDashboardState();
}

class _GuidanceDashboardState extends State<GuidanceDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Students tab
  final _searchController = TextEditingController();
  String? _searchError;
  List _filteredStudents = [];
  bool _isFiltering = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vp = Provider.of<ViolationProvider>(context, listen: false);
      vp.loadGuidanceStudents();
      vp.loadPendingViolations();
      vp.loadViolationsBySeverity();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Guidance Dashboard',
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
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.people_rounded, size: 18), text: 'Students'),
            Tab(icon: Icon(Icons.pending_rounded, size: 18), text: 'Pending'),
            Tab(icon: Icon(Icons.speed_rounded, size: 18), text: 'By Severity'),
          ],
        ),
      ),
      body: Consumer<ViolationProvider>(
        builder: (context, vp, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildStudentsTab(context, vp),
              _buildPendingTab(context, vp),
              _buildBySeverityTab(context, vp),
            ],
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TAB 1: Students — clickable list + manual search
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildStudentsTab(BuildContext context, ViolationProvider vp) {
    // Filter students based on search
    final displayList = _isFiltering ? _filteredStudents : vp.students;

    return RefreshIndicator(
      onRefresh: () => vp.loadGuidanceStudents(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(vp),
            const SizedBox(height: 16),

            // ── Search bar ──────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by StudentNo or Name...',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search_rounded, color: _navy, size: 20),
                      errorText: _searchError,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _isFiltering = false;
                                  _filteredStudents = [];
                                  _searchError = null;
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFDDE1EE))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFDDE1EE))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _navy, width: 1.5)),
                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _red, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchError = null;
                        if (value.trim().isEmpty) {
                          _isFiltering = false;
                          _filteredStudents = [];
                        } else {
                          _isFiltering = true;
                          _filteredStudents = vp.students.where((s) {
                            final q = value.trim().toLowerCase();
                            return s.name.toLowerCase().contains(q) ||
                                (s.studentNo ?? '').toLowerCase().contains(q);
                          }).toList();
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Full report search button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _searchStudentReport(context, vp),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: const Text('Report',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tap a student to view their full report  •  Tap Report to search by StudentNo',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 14),

            // ── Stats row ───────────────────────────────────────────────────
            Row(children: [
              Expanded(child: _statCard('Total Students', vp.students.length, _navy, Icons.people_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _statCard('Showing',
                  _isFiltering ? _filteredStudents.length : vp.students.length,
                  Colors.teal, Icons.filter_list_rounded)),
            ]),
            const SizedBox(height: 14),

            // ── Students list ────────────────────────────────────────────────
            if (vp.isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: _navy),
              ))
            else if (vp.error != null)
              _errorBanner(vp.error!)
            else if (displayList.isEmpty)
              _emptyState(_isFiltering ? 'No students match your search' : 'No students found')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final s = displayList[index];
                  // Use studentNo from User model — warningLevel comes from report
                  final studentNo = s.studentNo ?? s.id;
                  final name      = s.name;
                  return GestureDetector(
                    onTap: () => _showStudentReport(context, vp, studentNo),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: _navy.withOpacity(0.06),
                            blurRadius: 8, offset: const Offset(0, 3))],
                        border: Border.all(color: _navy.withOpacity(0.1)),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          backgroundColor: _navy.withOpacity(0.1),
                          child: Text(
                            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: _navy),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            Text(studentNo,
                                style: const TextStyle(fontSize: 11, color: Colors.black45)),
                            Text(s.gradeSection ?? '',
                                style: const TextStyle(fontSize: 11, color: Colors.black45)),
                          ],
                        )),
                        const Row(children: [
                          Text('View report',
                              style: TextStyle(fontSize: 10, color: _navy,
                                  fontWeight: FontWeight.w600)),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_forward_ios_rounded, size: 10, color: _navy),
                        ]),
                      ]),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TAB 2: All Violations
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildAllViolationsTab(BuildContext context, ViolationProvider vp) {
    return RefreshIndicator(
      onRefresh: () => vp.loadAllViolations(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats
            Row(children: [
              Expanded(child: _statCard('Total', vp.violations.length, _navy, Icons.list_alt_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _statCard('Pending',
                  vp.violations.where((v) => v.statusDescription == 'Pending').length,
                  Colors.orange, Icons.pending_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _statCard('Approved',
                  vp.violations.where((v) => v.statusDescription == 'Approved').length,
                  Colors.green, Icons.check_circle_rounded)),
            ]),
            const SizedBox(height: 14),

            if (vp.isLoading)
              const Center(child: CircularProgressIndicator(color: _navy))
            else if (vp.error != null)
              _errorBanner(vp.error!)
            else if (vp.violations.isEmpty)
              _emptyState('No violations found')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vp.violations.length,
                itemBuilder: (context, index) =>
                    _buildViolationCard(context, vp, vp.violations[index]),
              ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TAB 3: Pending Violations
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildPendingTab(BuildContext context, ViolationProvider vp) {
    // Use violations filtered to pending from the provider
    final pending = vp.violations.where((v) => v.statusDescription == 'Pending').toList();

    return RefreshIndicator(
      onRefresh: () => vp.loadPendingViolations(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.pending_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text('${pending.length} violation${pending.length != 1 ? 's' : ''} waiting for SAO approval',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: Colors.orange)),
              ]),
            ),
            const SizedBox(height: 14),

            if (vp.isLoading)
              const Center(child: CircularProgressIndicator(color: _navy))
            else if (pending.isEmpty)
              _emptyState('No pending violations 🎉')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pending.length,
                itemBuilder: (context, index) =>
                    _buildViolationCard(context, vp, pending[index]),
              ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TAB 4: By Severity
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildBySeverityTab(BuildContext context, ViolationProvider vp) {
    return RefreshIndicator(
      onRefresh: () => vp.loadViolationsBySeverity(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vp.isLoading)
              const Center(child: CircularProgressIndicator(color: _navy))
            else if (vp.severityGroups.isEmpty)
              _emptyState('No severity data found')
            else
              ...vp.severityGroups.map((group) {
                final severity  = group['severity'] ?? 'Unknown';
                final count     = group['count'] ?? 0;
                final violations = List.from(group['violations'] ?? []);
                final color     = _severityColor(severity);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.1),
                        blurRadius: 8, offset: const Offset(0, 3))],
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Severity header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        ),
                        child: Row(children: [
                          Icon(_severityIcon(severity), color: color, size: 20),
                          const SizedBox(width: 8),
                          Text(severity.toUpperCase(),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                                  color: color)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('$count case${count != 1 ? 's' : ''}',
                                style: const TextStyle(fontSize: 11,
                                    fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ]),
                      ),

                      // Violations under this severity
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: violations.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (context, i) {
                          final v = violations[i];
                          final statusColor = _statusColor(v['status'] ?? '');
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.1),
                              radius: 18,
                              child: Icon(_severityIcon(severity), color: color, size: 16),
                            ),
                            title: Text(v['type'] ?? 'Unknown',
                                style: const TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Student: ${v['student_no'] ?? 'N/A'}',
                                    style: const TextStyle(fontSize: 11,
                                        color: Colors.black54)),
                                Text(
                                  v['date'] != null
                                      ? DateFormat('MMM dd, yyyy').format(
                                          DateTime.tryParse(v['date']) ?? DateTime.now())
                                      : '',
                                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                                ),
                                if (v['details'] != null && v['details'].toString().isNotEmpty)
                                  Text(v['details'],
                                      style: const TextStyle(fontSize: 11,
                                          color: Colors.black45)),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(v['status'] ?? '',
                                  style: TextStyle(fontSize: 10,
                                      fontWeight: FontWeight.w700, color: statusColor)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ── Violation card (used in All + Pending tabs) ───────────────────────────
  Widget _buildViolationCard(BuildContext context, ViolationProvider vp, violation) {
    final statusColor = _statusColor(violation.statusDescription);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: _navy.withOpacity(0.06), blurRadius: 8,
            offset: const Offset(0, 3))],
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(violation.violationDescription,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(violation.statusDescription,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: statusColor)),
              ),
            ]),
            const SizedBox(height: 6),
            Text('Student: ${violation.studentId}',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            Text(DateFormat('MMM dd, yyyy').format(violation.date),
                style: const TextStyle(fontSize: 12, color: Colors.black45)),
            if (violation.severity != null && violation.severity!.isNotEmpty)
              Row(children: [
                Icon(_severityIcon(violation.severity!),
                    size: 13, color: _severityColor(violation.severity!)),
                const SizedBox(width: 4),
                Text('Severity: ${violation.severity}',
                    style: TextStyle(fontSize: 12,
                        color: _severityColor(violation.severity!),
                        fontWeight: FontWeight.w600)),
              ]),
            Text('By: ${violation.reportedBy ?? 'Unknown'}',
                style: const TextStyle(fontSize: 11, color: Colors.black45)),

            // Action buttons for pending violations
            if (violation.statusDescription == 'Pending') ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _actionBtn('Resolve', Icons.check_circle_rounded,
                    Colors.green, () => _confirmResolve(context, vp, violation.id))),
                const SizedBox(width: 8),
                Expanded(child: _actionBtn('Delete', Icons.delete_outline_rounded,
                    _red, () => _confirmDelete(context, vp, violation.id))),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  // ── Search student report ─────────────────────────────────────────────────
  void _searchStudentReport(BuildContext context, ViolationProvider vp) async {
    final input = _searchController.text.trim();
    if (input.isEmpty) {
      setState(() => _searchError = 'Please enter a StudentNo to get a report');
      return;
    }
    setState(() => _searchError = null);
    await _showStudentReport(context, vp, input);
  }

  // ── Show student report dialog ────────────────────────────────────────────
  Future<void> _showStudentReport(BuildContext context, ViolationProvider vp,
      String studentNo) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: _navy)),
    );

    final report = await vp.getGuidanceStudentReport(studentNo);
    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading

    if (report == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('Student "$studentNo" not found',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    // Show full report dialog
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_navy, Color(0xFF1A1F8F)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      (report['name'] ?? 'S').substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 26,
                          fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(report['name'] ?? '',
                      style: const TextStyle(fontSize: 17,
                          fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(report['student_no'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.white60)),
                  const SizedBox(height: 8),
                  // Warning level pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _warningColor(report['warning_level'] ?? 'green'),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.circle, size: 8, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Warning: ${(report['warning_level'] ?? 'green').toUpperCase()}  •  ${report['violation_count'] ?? 0} violations',
                        style: const TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ]),
                  ),
                ]),
              ),

              // Info rows
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(children: [
                  _dialogRow('Email', report['email'] ?? 'N/A', Icons.email_rounded),
                  _dialogRow('Contact', report['contact_number'] ?? 'N/A', Icons.phone_rounded),
                  _dialogRow('Gender', report['gender'] ?? 'N/A', Icons.person_rounded),
                  _dialogRow('Address', report['address'] ?? 'N/A', Icons.location_on_rounded),
                ]),
              ),

              // Violations list inside report
              if (report['violations'] != null &&
                  (report['violations'] as List).isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(children: [
                    Container(width: 4, height: 16,
                        decoration: BoxDecoration(color: _red,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    const Text('Violations',
                        style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700, color: _navy)),
                  ]),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: (report['violations'] as List).length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, i) {
                    final v = (report['violations'] as List)[i];
                    final sc = _statusColor(v['status'] ?? '');
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        Icon(_severityIcon(v['severity'] ?? ''),
                            size: 16,
                            color: _severityColor(v['severity'] ?? '')),
                        const SizedBox(width: 8),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v['type'] ?? '',
                                style: const TextStyle(fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            Text(
                              v['date'] != null
                                  ? DateFormat('MMM dd, yyyy').format(
                                      DateTime.tryParse(v['date']) ?? DateTime.now())
                                  : '',
                              style: const TextStyle(fontSize: 11, color: Colors.black45),
                            ),
                            if (v['details'] != null &&
                                v['details'].toString().isNotEmpty)
                              Text(v['details'],
                                  style: const TextStyle(fontSize: 11,
                                      color: Colors.black54)),
                          ],
                        )),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: sc.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(v['status'] ?? '',
                              style: TextStyle(fontSize: 9,
                                  fontWeight: FontWeight.w700, color: sc)),
                        ),
                      ]),
                    );
                  },
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text('No violations recorded',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                  ),
                ),

              // Close button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Confirm resolve ───────────────────────────────────────────────────────
  void _confirmResolve(BuildContext context, ViolationProvider vp, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Resolve Violation',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700)),
        content: const Text('Mark this violation as resolved?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.black54))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await vp.resolveViolation(id);
              if (vp.error == null && mounted) {
                _showSnack(context, 'Violation resolved!', Colors.green);
              } else if (mounted && vp.error != null) {
                _showSnack(context, vp.error!, _red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  // ── Confirm delete ────────────────────────────────────────────────────────
  void _confirmDelete(BuildContext context, ViolationProvider vp, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Violation',
            style: TextStyle(color: _red, fontWeight: FontWeight.w700)),
        content: const Text('Permanently delete this violation? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.black54))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await vp.deleteGuidanceViolation(id);
              if (vp.error == null && mounted) {
                _showSnack(context, 'Violation deleted', _red);
              } else if (mounted && vp.error != null) {
                _showSnack(context, vp.error!, _red);
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

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildWelcomeCard(ViolationProvider vp) {
    final name = Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'Guidance';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, Color(0xFF1A1F8F)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _navy.withOpacity(0.3), blurRadius: 12,
            offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, $name!',
                style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w800, color: Colors.white)),
            Text('${vp.students.length} students  •  ${vp.violations.length} pending violations',
                style: const TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        )),
      ]),
    );
  }

  Widget _statCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 6,
            offset: const Offset(0, 3))],
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(count.toString(),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _dialogRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 16, color: _navy.withOpacity(0.5)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 12,
            color: Colors.black45, fontWeight: FontWeight.w500)),
        Expanded(child: Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 1,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
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
    return Center(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(children: [
        Icon(Icons.inbox_rounded, size: 52, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Text(message, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      ]),
    ));
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

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical': return Colors.red;
      case 'major':    return Colors.deepOrange;
      case 'moderate': return Colors.orange;
      default:         return Colors.blue;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical': return Icons.dangerous_rounded;
      case 'major':    return Icons.warning_rounded;
      case 'moderate': return Icons.report_rounded;
      default:         return Icons.info_rounded;
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
          Text('Logout',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _navy)),
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