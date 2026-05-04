import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../providers/violation_provider.dart';
import 'notifications_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

const _red = Color(0xFFFD070C);
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
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vp = Provider.of<ViolationProvider>(context, listen: false);
      vp.loadMyViolations();
      vp.loadMyProfile();
      vp.loadMyQrCode();
      vp.loadNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _appealController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 600,
    );
    if (picked == null) return;

    final token =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.token ??
        '';
    final vp = Provider.of<ViolationProvider>(context, listen: false);

    final error = await vp.uploadProfilePhoto(File(picked.path));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Profile photo updated!'),
          backgroundColor: error != null ? _red : Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.name ??
        'Student';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Student Dashboard',
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
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Dashboard'),
            Tab(icon: Icon(Icons.person_rounded), text: 'Profile'),
            Tab(icon: Icon(Icons.qr_code_rounded), text: 'QR Code'),
            Tab(icon: Icon(Icons.gavel_rounded), text: 'Appeals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(name),
          _buildProfileTab(),
          _buildQrCodeTab(),
          _buildAppealsTab(),
        ],
      ),
    );
  }

  Widget _buildAppealsTab() {
    return Consumer<ViolationProvider>(
      builder: (context, vp, _) {
        // only show violations that haven't been appealed yet
        final appealable = vp.violations
    .where(
      (v) => v.appealStatus == null || v.appealStatus == 'None',
    )
    .toList();

        // violations that already have an appeal submitted
        final appealed = vp.violations
            .where((v) => v.appealStatus != null && v.appealStatus != 'None')
            .toList();

        return RefreshIndicator(
          onRefresh: () => vp.loadMyViolations(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Appeals you can still submit ---
                if (appealable.isNotEmpty) ...[
                  const Text(
                    'Appealable Violations',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...appealable.map((v) => _appealCard(v, canAppeal: true)),
                  const SizedBox(height: 20),
                ],

                // --- Already appealed ---
                if (appealed.isNotEmpty) ...[
                  const Text(
                    'Submitted Appeals',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...appealed.map((v) => _appealCard(v, canAppeal: false)),
                ],

                // --- Nothing at all ---
                if (appealable.isEmpty && appealed.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          Icon(
                            Icons.gavel_rounded,
                            size: 56,
                            color: Colors.black26,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No violations to appeal',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _appealCard(dynamic v, {required bool canAppeal}) {
    final name = v.violationName ?? v.violationDescription;
    final date = v.date.toString().substring(0, 10);
    final severity = v.severity ?? 'minor';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.07),
            blurRadius: 10,
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
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              _severityBadge(severity),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),

          // show appeal result if already appealed
          if (!canAppeal && v.appealStatus != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _appealColor(v.appealStatus ?? '').withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _appealColor(v.appealStatus ?? '').withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.gavel_rounded,
                        size: 13,
                        color: _appealColor(v.appealStatus ?? ''),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Appeal: ${v.appealStatus ?? ''}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _appealColor(v.appealStatus ?? ''),
                        ),
                      ),
                    ],
                  ),
                  if (v.appealRemarks != null &&
                      v.appealRemarks!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Remarks: ${v.appealRemarks}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // appeal button if not yet appealed
          if (canAppeal) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAppealDialog(v.id),
                icon: const Icon(Icons.gavel_rounded, size: 16),
                label: const Text(
                  'Submit Appeal',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDashboardTab(String name) {
    return Consumer<ViolationProvider>(
      builder: (context, vp, _) {
        return RefreshIndicator(
          onRefresh: () => vp.loadMyViolations(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
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
                          Icons.school_rounded,
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
                              'Student Portal',
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

                if (vp.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: _navy),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          'Total',
                          vp.totalCount.toString(),
                          _navy,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statCard(
                          'Pending',
                          vp.pendingCount.toString(),
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statCard(
                          'Approved',
                          vp.approvedCount.toString(),
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statCard(
                          'Rejected',
                          vp.rejectedCount.toString(),
                          _red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildWarningCard(vp.warningLevel),
                  const SizedBox(height: 16),

                  Container(
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
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
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
                              const Text(
                                'Violation History',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        if (vp.violations.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 56,
                                    color: Colors.green,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'No violations recorded!',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'Keep up the good work!',
                                    style: TextStyle(
                                      color: Colors.black45,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...vp.violations
                              .map((v) => _violationTile(v))
                              .toList(),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWarningCard(String warningLevel) {
    final color = _warningColor(warningLevel);
    final icon = _warningIcon(warningLevel);
    final action = _warningAction(warningLevel);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warning Level: $warningLevel',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  action,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _violationTile(violation) {
    final name = violation.violationName ?? violation.violationDescription;
    final date = violation.date.toString().substring(0, 10);
    final status = violation.statusDescription;
    final severity = violation.severity ?? 'minor';

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              _severityBadge(severity),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 4),
              Row(children: [_statusChip(status)]),

              // Show appeal status and remarks if appeal was submitted
              if (violation.appealStatus != null &&
                  violation.appealStatus != 'None') ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _appealColor(
                      violation.appealStatus ?? '',
                    ).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _appealColor(
                        violation.appealStatus ?? '',
                      ).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.gavel_rounded,
                            size: 13,
                            color: _appealColor(violation.appealStatus ?? ''),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Appeal: ${violation.appealStatus ?? ''}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _appealColor(violation.appealStatus ?? ''),
                            ),
                          ),
                        ],
                      ),
                      if (violation.appealRemarks != null &&
                          violation.appealRemarks!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Remarks: ${violation.appealRemarks}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1, indent: 16),
      ],
    );
  }

  Widget _buildProfileTab() {
    return Consumer<ViolationProvider>(
      builder: (context, vp, _) {
        final profile = vp.studentProfile;
        final name =
            Provider.of<AuthProvider>(
              context,
              listen: false,
            ).currentUser?.name ??
            'Student';

        return RefreshIndicator(
          onRefresh: () => vp.loadMyProfile(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_navy, Color(0xFF1A1F8F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _navy.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // top banner area
                      Container(
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      // avatar overlapping the banner
                      Transform.translate(
                        offset: const Offset(0, -40),
                        child: GestureDetector(
                          onTap: () => _pickAndUploadPhoto(context),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.2,
                                  ),
                                  backgroundImage:
                                      (profile['profile_photo'] != null &&
                                          profile['profile_photo']
                                              .toString()
                                              .isNotEmpty)
                                      ? MemoryImage(
                                          base64Decode(
                                            profile['profile_photo'],
                                          ),
                                        )
                                      : null,
                                  child:
                                      (profile['profile_photo'] == null ||
                                          profile['profile_photo']
                                              .toString()
                                              .isEmpty)
                                      ? Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : 'S',
                                          style: const TextStyle(
                                            fontSize: 38,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: _red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // name and student no — pulled up to fill the gap from Transform
                      Transform.translate(
                        offset: const Offset(0, -30),
                        child: Column(
                          children: [
                            Text(
                              profile['name'] ?? name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                profile['student_no'] ?? '—',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (vp.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: _navy),
                    ),
                  )
                else
                  Container(
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
                      children: [
                        _profileRow(
                          'Course',
                          profile['course'] ?? '—',
                          Icons.school_rounded,
                        ),
                        _profileRow(
                          'Year',
                          profile['year']?.toString() ?? '—',
                          Icons.calendar_today_rounded,
                        ),
                        _profileRow(
                          'Email',
                          profile['email'] ?? '—',
                          Icons.email_rounded,
                        ),
                        _profileRow(
                          'Gender',
                          profile['gender'] ?? '—',
                          Icons.person_rounded,
                        ),
                        _profileRow(
                          'Contact',
                          profile['contact_number'] ?? '—',
                          Icons.phone_rounded,
                        ),
                        _profileRow(
                          'Status',
                          profile['status'] ?? 'Active',
                          Icons.verified_user_rounded,
                        ),
                        _profileRow(
                          'Address',
                          profile['address'] ?? '—',
                          Icons.location_on_rounded,
                          isLast: true,
                        ),
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

  Widget _profileRow(
    String label,
    String value,
    IconData icon, {
    bool isLast = false,
  }) {
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
          title: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black45,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 56),
      ],
    );
  }

  Widget _buildQrCodeTab() {
    return Consumer<ViolationProvider>(
      builder: (context, vp, _) {
        final studentNo =
            Provider.of<AuthProvider>(
              context,
              listen: false,
            ).currentUser?.studentNo ??
            '—';

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
                boxShadow: [
                  BoxShadow(
                    color: _navy.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'My QR Code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Show this to the Guard for scanning',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
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
                        base64Decode(vp.studentQrCode!.replaceAll('\n', '')),
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
                      child: const Icon(
                        Icons.qr_code_rounded,
                        size: 120,
                        color: Colors.black87,
                      ),
                    ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _navy.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      studentNo,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _navy,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAppealDialog(String violationId) {
    _appealController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: _navy, size: 22),
            SizedBox(width: 8),
            Text(
              'Submit Appeal',
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
                      final text = _appealController.text.trim();
                      if (text.isEmpty) return;
                      await vp.submitAppeal(violationId, text);
                      if (mounted) {
                        Navigator.of(dialogContext).pop();
                        _showSnack(
                          vp.error == null
                              ? 'Appeal submitted successfully'
                              : vp.error!,
                          isError: vp.error != null,
                        );
                        if (vp.error == null) vp.loadMyViolations();
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
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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

  IconData _warningIcon(String level) {
    switch (level.toLowerCase()) {
      case 'yellow':
        return Icons.warning_rounded;
      case 'orange':
        return Icons.error_rounded;
      case 'red':
        return Icons.dangerous_rounded;
      default:
        return Icons.check_circle_rounded;
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

  Color _appealColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return _red;
      default:
        return Colors.orange;
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
