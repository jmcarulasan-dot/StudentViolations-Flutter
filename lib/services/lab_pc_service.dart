import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database_service.dart';
import '../models/lab_pc_session.dart';

class LabPcService {
  static String get _baseUrl => DatabaseService.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await DatabaseService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<LabPcSession?> getActiveSession() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/labpc/sessions/me/active'), headers: await _headers());
    if (response.statusCode == 404) return null;
    final envelope = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) throw Exception(envelope['message'] ?? 'Could not load your lab session.');
    return LabPcSession.fromJson(envelope['data'] as Map<String, dynamic>);
  }

  static Future<LabPcChallengePreview> previewChallenge(String challengeId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/labpc/challenges/preview'),
      headers: await _headers(),
      body: jsonEncode({'challengeId': challengeId}),
    );
    final envelope = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) throw Exception(envelope['message'] ?? 'This PC QR code is no longer valid.');
    return LabPcChallengePreview.fromJson(envelope['data'] as Map<String, dynamic>);
  }

  static Future<LabPcSession> redeem(String challengeId, String voucherCode) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/labpc/sessions/redeem'),
      headers: await _headers(),
      body: jsonEncode({'challengeId': challengeId, 'voucherCode': voucherCode}),
    );
    final envelope = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) throw Exception(envelope['message'] ?? 'The voucher could not be used.');
    return LabPcSession.fromJson(envelope['data'] as Map<String, dynamic>);
  }

  static Future<void> end(String sessionId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/labpc/sessions/$sessionId/end'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      final envelope = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(envelope['message'] ?? 'Could not end the lab session.');
    }
  }
}