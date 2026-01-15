import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper function to handle both Firestore Timestamps and ISO 8601 Strings
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class ReportModel {
  final String id;
  final bool isAnonymous;
  final GeoPoint location;
  final List<String> photoUrls;
  final DateTime timestamp;
  final String type;
  final String userId;
  final bool isSubmitted;

  // Agent Maps
  final UserAgentModel? userAgent;
  final AuditAgentModel? auditAgent;
  final EvidenceAgentModel? evidenceAgent;

  ReportModel({
    required this.id,
    required this.isAnonymous,
    required this.location,
    required this.photoUrls,
    required this.timestamp,
    required this.type,
    required this.userId,
    this.isSubmitted = true,
    this.userAgent,
    this.auditAgent,
    this.evidenceAgent,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ReportModel(
      id: doc.id,
      isAnonymous: data['isAnonymous'] ?? false,
      location: data['location'] ?? const GeoPoint(0, 0),
      photoUrls: List<String>.from(data['photos'] ?? []),
      // Updated to use the helper
      timestamp: _parseDateTime(data['timestamp']) ?? DateTime.now(),
      type: data['type'] ?? 'Unknown',
      userId: data['userId'] ?? '',
      isSubmitted: data['isSubmitted'] ?? true,

      userAgent: data['userAgent'] != null
          ? UserAgentModel.fromMap(data['userAgent'])
          : null,
      auditAgent: data['auditAgent'] != null
          ? AuditAgentModel.fromMap(data['auditAgent'])
          : null,
      evidenceAgent: data['evidenceAgent'] != null
          ? EvidenceAgentModel.fromMap(data['evidenceAgent'])
          : null,
    );
  }
}

class UserAgentModel {
  final double confidenceScore;
  final String department;
  final String issueType;
  final String summary;
  final String severity;
  final DateTime? processedAt;
  final VisualVerificationModel? visualVerification;

  UserAgentModel({
    required this.confidenceScore,
    required this.department,
    required this.issueType,
    required this.summary,
    required this.severity,
    this.processedAt,
    this.visualVerification,
  });

  factory UserAgentModel.fromMap(Map<String, dynamic> map) {
    return UserAgentModel(
      confidenceScore: (map['confidenceScore'] ?? 0.0).toDouble(),
      department: map['department'] ?? 'General',
      issueType: map['issueType'] ?? 'Unknown',
      summary: map['summary'] ?? '',
      severity: map['severity'] ?? 'Low',
      // Updated to use the helper
      processedAt: _parseDateTime(map['processedAt']),
      visualVerification: map['visualVerification'] != null
          ? VisualVerificationModel.fromMap(map['visualVerification'])
          : null,
    );
  }
}

class VisualVerificationModel {
  final String imageQuality;
  final List<String> detectedObjects;

  VisualVerificationModel({
    required this.imageQuality,
    required this.detectedObjects,
  });

  factory VisualVerificationModel.fromMap(Map<String, dynamic> map) {
    return VisualVerificationModel(
      imageQuality: map['imageQuality'] ?? 'Standard',
      detectedObjects: List<String>.from(map['detectedObjects'] ?? []),
    );
  }
}

class AuditAgentModel {
  final String responsibleContractorName;
  final String responsibleContractorId;
  final String auditReasoning;
  final bool isDiscrepancyVerified;
  final bool foundContractor;
  final double corruptionScore;

  AuditAgentModel({
    required this.responsibleContractorName,
    required this.responsibleContractorId,
    required this.auditReasoning,
    required this.isDiscrepancyVerified,
    required this.foundContractor,
    required this.corruptionScore,
  });

  factory AuditAgentModel.fromMap(Map<String, dynamic> map) {
    return AuditAgentModel(
      responsibleContractorName: map['responsibleContractorName'] ?? 'N/A',
      responsibleContractorId: map['responsibleContractorId'] ?? '',
      auditReasoning: map['auditReasoning'] ?? '',
      isDiscrepancyVerified: map['isDiscrepancyVerified'] ?? false,
      foundContractor: map['foundContractor'] ?? false,
      corruptionScore: (map['corruptionScore'] ?? 0.0).toDouble(),
    );
  }
}

class EvidenceAgentModel {
  final String afterImageDescription;
  final String analysisThinking;
  final String evidenceImageUrl;
  final String fixQuality;
  final bool discrepancyDetected;
  final bool isResolved;
  final DateTime? verifiedAt;

  EvidenceAgentModel({
    required this.afterImageDescription,
    required this.analysisThinking,
    required this.evidenceImageUrl,
    required this.fixQuality,
    required this.discrepancyDetected,
    required this.isResolved,
    this.verifiedAt,
  });

  factory EvidenceAgentModel.fromMap(Map<String, dynamic> map) {
    return EvidenceAgentModel(
      afterImageDescription: map['afterImageDescription'] ?? '',
      analysisThinking: map['analysisThinking'] ?? '',
      evidenceImageUrl: map['evidenceImageUrl'] ?? '',
      fixQuality: map['fixQuality'] ?? '',
      discrepancyDetected: map['discrepancyDetected'] ?? false,
      isResolved: map['isResolved'] ?? false,
      // Updated to use the helper
      verifiedAt: _parseDateTime(map['verifiedAt']),
    );
  }
}