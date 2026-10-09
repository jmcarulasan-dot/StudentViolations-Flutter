import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/lab_pc_session.dart';
import '../services/lab_pc_service.dart';

const _labNavy = Color(0xFF0F136E);

class LabPcScreen extends StatefulWidget {
  const LabPcScreen({super.key});
  @override
  State<LabPcScreen> createState() => _LabPcScreenState();
}

class _LabPcScreenState extends State<LabPcScreen> {
  final _voucherController = TextEditingController();
  LabPcSession? _session;
  String? _challenge;
  String? _error;
  bool _loading = true;
  bool _submitting = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadSession(showLoading: false));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _loadSession({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _loading = true);
    try {
      final result = await LabPcService.getActiveSession();
      if (mounted) setState(() { _session = result; _error = null; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _scanPc() async {
    final value = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _LabPcScanner()),
    );
    if (value != null && mounted) setState(() { _challenge = value; _error = null; });
  }

  Future<void> _redeem() async {
    if (_challenge == null || _voucherController.text.trim().isEmpty) {
      setState(() => _error = 'Scan the computer QR and enter the voucher from Lab Staff.');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      final session = await LabPcService.redeem(_challenge!, _voucherController.text.trim());
      if (!mounted) return;
      setState(() { _session = session; _challenge = null; _voucherController.clear(); });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _endSession() async {
    final session = _session;
    if (session == null) return;
    setState(() => _submitting = true);
    try {
      await LabPcService.end(session.sessionId);
      if (mounted) setState(() { _session = null; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _labNavy));
    final session = _session;
    return RefreshIndicator(
      onRefresh: _loadSession,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Computer Lab', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: _labNavy)),
          const SizedBox(height: 8),
          const Text('Use a voucher from Lab Staff to start a timed session on an available lab computer.'),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Material(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: TextStyle(color: Colors.red.shade900)))),
          ],
          const SizedBox(height: 20),
          if (session != null) _activeCard(session) else _redeemCard(),
        ],
      ),
    );
  }

  Widget _redeemCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Start a session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: _scanPc, icon: const Icon(Icons.qr_code_scanner), label: Text(_challenge == null ? 'Scan the PC QR code' : 'PC QR scanned')),
        const SizedBox(height: 12),
        TextField(controller: _voucherController, textCapitalization: TextCapitalization.characters, autocorrect: false, enableSuggestions: false, decoration: const InputDecoration(labelText: 'Voucher code', border: OutlineInputBorder())),
        const SizedBox(height: 14),
        FilledButton(onPressed: _submitting ? null : _redeem, child: _submitting ? const CircularProgressIndicator() : const Text('Start timed session')),
      ]),
    ),
  );

  Widget _activeCard(LabPcSession session) {
    final remaining = session.expiresAtUtc.difference(DateTime.now().toUtc());
    final minutes = remaining.inMinutes.clamp(0, 999);
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Your lab session is active', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(session.computerName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          if (session.location.isNotEmpty) Text(session.location),
          const SizedBox(height: 10),
          Text('Ends at ${session.expiresAtUtc.toLocal().toString().substring(0, 16)}'),
          Text('About $minutes minutes remaining'),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _submitting ? null : _endSession, child: const Text('End session now')),
        ]),
      ),
    );
  }
}

class _LabPcScanner extends StatefulWidget {
  const _LabPcScanner();
  @override
  State<_LabPcScanner> createState() => _LabPcScannerState();
}

class _LabPcScannerState extends State<_LabPcScanner> {
  bool _handled = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scan lab PC')),
    body: MobileScanner(
      onDetect: (capture) {
        if (_handled) return;
        final value = capture.barcodes.map((barcode) => barcode.rawValue).firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
        if (value == null) return;
        _handled = true;
        Navigator.of(context).pop(value);
      },
    ),
  );
}