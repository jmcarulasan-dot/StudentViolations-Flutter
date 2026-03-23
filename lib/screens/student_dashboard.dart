import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'Student';
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
          _buildProfileTab(name),
          _buildQrCodeTab(),
        ],
      ),
    );
  }

  // ── Tab 1: Dashboard ────────────────────────────────────────────────────────
  Widget _buildDashboardTab(String name) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome card
          Container(
            padding: const EdgeInsets.all(18),
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
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, $name!',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                  const Text('Student Portal',
                      style: TextStyle(fontSize: 12, color: Colors.white60)),
                ],
              )),
            ]),
          ),
          const SizedBox(height: 16),

          // Stats row (empty)
          Row(children: [
            Expanded(child: _statCard('Total', '—', _navy)),
            const SizedBox(width: 8),
            Expanded(child: _statCard('Pending', '—', Colors.orange)),
            const SizedBox(width: 8),
            Expanded(child: _statCard('Approved', '—', Colors.green)),
            const SizedBox(width: 8),
            Expanded(child: _statCard('Rejected', '—', _red)),
          ]),
          const SizedBox(height: 16),

          // Warning level placeholder
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.withOpacity(0.25)),
            ),
            child: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
              SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Warning Level: —',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.green)),
                  Text('No data available',
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              )),
            ]),
          ),
          const SizedBox(height: 16),

          // Violation history placeholder
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: _navy.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(children: [
                  Container(width: 4, height: 18,
                      decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  const Text('Violation History',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _navy)),
                ]),
              ),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Column(children: [
                  Icon(Icons.check_circle_rounded, size: 56, color: Colors.green),
                  SizedBox(height: 8),
                  Text('No violations recorded!',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.green)),
                  Text('Keep up the good work!',
                      style: TextStyle(color: Colors.black45, fontSize: 12)),
                ])),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Profile ──────────────────────────────────────────────────────────
  Widget _buildProfileTab(String name) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
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
              child: Text(name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'S',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            const Text('—', style: TextStyle(fontSize: 13, color: Colors.white70)),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: _navy.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(children: [
            _profileRow('Course', '—', Icons.school_rounded),
            _profileRow('Year', '—', Icons.calendar_today_rounded),
            _profileRow('Email', '—', Icons.email_rounded),
            _profileRow('Gender', '—', Icons.person_rounded),
            _profileRow('Contact', '—', Icons.phone_rounded),
            _profileRow('Address', '—', Icons.location_on_rounded, isLast: true),
          ]),
        ),
      ]),
    );
  }

  Widget _profileRow(String label, String value, IconData icon, {bool isLast = false}) {
    return Column(children: [
      ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _navy.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: _navy, size: 18),
        ),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w500)),
        subtitle: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
      ),
      if (!isLast) const Divider(height: 1, indent: 56),
    ]);
  }

  // ── Tab 3: QR Code ──────────────────────────────────────────────────────────
  Widget _buildQrCodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: _navy.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          const Text('My QR Code',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _navy)),
          const SizedBox(height: 4),
          const Text('Show this to the Guard for scanning',
              style: TextStyle(fontSize: 12, color: Colors.black45)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: _navy.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.qr_code_rounded, size: 120, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _navy.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('—',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _navy, letterSpacing: 1)),
          ),
        ]),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3))],
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)), textAlign: TextAlign.center),
      ]),
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