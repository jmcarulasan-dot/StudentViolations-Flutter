import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'SAO';
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildViolationsTab(name),
          _buildSummaryTab(),
          _buildUsersTab(),
        ],
      ),
    );
  }

  // ── Tab 1: Violations ───────────────────────────────────────────────────────
  Widget _buildViolationsTab(String name) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, $name!',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                const Text('Student Affairs Office — Highest Authority',
                    style: TextStyle(fontSize: 12, color: Colors.white60)),
              ],
            )),
          ]),
        ),
        const SizedBox(height: 16),

        // Stats
        Row(children: [
          Expanded(child: _statCard('Total', 0, _navy)),
          const SizedBox(width: 8),
          Expanded(child: _statCard('Pending', 0, Colors.orange)),
          const SizedBox(width: 8),
          Expanded(child: _statCard('Approved', 0, Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _statCard('Rejected', 0, _red)),
        ]),
        const SizedBox(height: 16),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _filterChip('All', 'all'),
            const SizedBox(width: 8),
            _filterChip('Pending', 'pending'),
            const SizedBox(width: 8),
            _filterChip('Approved', 'approved'),
            const SizedBox(width: 8),
            _filterChip('Rejected', 'rejected'),
          ]),
        ),
        const SizedBox(height: 14),
        _emptyState('No violations found'),
      ]),
    );
  }

  // ── Tab 2: Summary ──────────────────────────────────────────────────────────
  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Stats placeholders
        Row(children: [
          Expanded(child: _summaryStatCard('Total', '—', _navy)),
          const SizedBox(width: 8),
          Expanded(child: _summaryStatCard('Pending', '—', Colors.orange)),
          const SizedBox(width: 8),
          Expanded(child: _summaryStatCard('Approved', '—', Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _summaryStatCard('Rejected', '—', _red)),
        ]),
        const SizedBox(height: 16),

        // By severity placeholder
        _buildSectionCard(
          title: '📊 By Severity',
          child: _emptyState('No severity data'),
        ),
        const SizedBox(height: 16),

        // By type placeholder
        _buildSectionCard(
          title: '📋 By Violation Type',
          child: _emptyState('No type data'),
        ),
        const SizedBox(height: 16),

        // Student report search
        _buildSectionCard(
          title: '🔍 Student Report',
          child: Column(children: [
            TextFormField(
              controller: _reportController,
              style: const TextStyle(fontSize: 13),
              decoration: _inputDeco('Enter StudentNo for full report', Icons.person_search_rounded),
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
                icon: const Icon(Icons.search_rounded),
                label: const Text('Get Report', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Tab 3: Users ────────────────────────────────────────────────────────────
  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildSectionCard(
        title: '👥 All Users (0)',
        child: _emptyState('No users found'),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _navy.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 4, height: 18,
              decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _navy)),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
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
      child: Column(children: [
        Text(count.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)), textAlign: TextAlign.center),
      ]),
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
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _violationFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _violationFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _navy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _navy : Colors.grey.shade300),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black54)),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(children: [
        Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Text(message, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      ]),
    ));
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