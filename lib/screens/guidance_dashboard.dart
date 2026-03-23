import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'Guidance';
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudentsTab(name),
          _buildPendingTab(),
          _buildBySeverityTab(),
        ],
      ),
    );
  }

  // ── Tab 1: Students ─────────────────────────────────────────────────────────
  Widget _buildStudentsTab(String name) {
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
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, $name!',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                const Text('Guidance Office',
                    style: TextStyle(fontSize: 11, color: Colors.white60)),
              ],
            )),
          ]),
        ),
        const SizedBox(height: 16),

        // Search bar
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search by StudentNo or Name...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search_rounded, color: _navy, size: 20),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDDE1EE))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDDE1EE))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _navy, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: const Text('Report', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Text('Tap a student to view their full report  •  Tap Report to search by StudentNo',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 14),

        // Stats
        Row(children: [
          Expanded(child: _statCard('Total Students', 0, _navy, Icons.people_rounded)),
          const SizedBox(width: 8),
          Expanded(child: _statCard('Showing', 0, Colors.teal, Icons.filter_list_rounded)),
        ]),
        const SizedBox(height: 14),

        _emptyState('No students found'),
      ]),
    );
  }

  // ── Tab 2: Pending ──────────────────────────────────────────────────────────
  Widget _buildPendingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.pending_rounded, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Text('0 violations waiting for SAO approval',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange)),
          ]),
        ),
        const SizedBox(height: 14),
        _emptyState('No pending violations 🎉'),
      ]),
    );
  }

  // ── Tab 3: By Severity ──────────────────────────────────────────────────────
  Widget _buildBySeverityTab() {
    final severities = [
      {'label': 'Critical', 'color': Colors.red, 'icon': Icons.dangerous_rounded},
      {'label': 'Major',    'color': Colors.deepOrange, 'icon': Icons.warning_rounded},
      {'label': 'Moderate', 'color': Colors.orange, 'icon': Icons.report_rounded},
      {'label': 'Minor',    'color': Colors.blue, 'icon': Icons.info_rounded},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: severities.map((s) {
          final color = s['color'] as Color;
          final icon  = s['icon'] as IconData;
          final label = s['label'] as String;
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: color.withOpacity(0.1),
                  blurRadius: 8, offset: const Offset(0, 3))],
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(label.toUpperCase(),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                    child: const Text('0 cases',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No $label violations',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12))),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _statCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3))],
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(count.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)), textAlign: TextAlign.center),
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