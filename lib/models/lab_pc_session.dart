class LabPcSession {
  final String sessionId;
  final String computerName;
  final String location;
  final DateTime startedAtUtc;
  final DateTime expiresAtUtc;

  const LabPcSession({
    required this.sessionId,
    required this.computerName,
    required this.location,
    required this.startedAtUtc,
    required this.expiresAtUtc,
  });

  factory LabPcSession.fromJson(Map<String, dynamic> json) => LabPcSession(
    sessionId: json['sessionId']?.toString() ?? '',
    computerName: json['computerName']?.toString() ?? 'Lab PC',
    location: json['location']?.toString() ?? '',
    startedAtUtc: DateTime.tryParse(json['startedAtUtc']?.toString() ?? '')?.toUtc() ?? DateTime.now().toUtc(),
    expiresAtUtc: DateTime.tryParse(json['expiresAtUtc']?.toString() ?? '')?.toUtc() ?? DateTime.now().toUtc(),
  );
}
class LabPcChallengePreview {
  final String computerName;
  final String location;
  final DateTime expiresAtUtc;

  const LabPcChallengePreview({
    required this.computerName,
    required this.location,
    required this.expiresAtUtc,
  });

  factory LabPcChallengePreview.fromJson(Map<String, dynamic> json) => LabPcChallengePreview(
    computerName: json['computerName']?.toString() ?? 'Lab PC',
    location: json['location']?.toString() ?? '',
    expiresAtUtc: DateTime.tryParse(json['expiresAtUtc']?.toString() ?? '')?.toUtc() ?? DateTime.now().toUtc(),
  );
}
