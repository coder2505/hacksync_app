import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final bool isAnonymous;
  final GeoPoint location;
  final List<String> photoUrls;
  final DateTime timestamp;
  final String type;
  final String userId;

  ReportModel({
    required this.id,
    required this.isAnonymous,
    required this.location,
    required this.photoUrls,
    required this.timestamp,
    required this.type,
    required this.userId,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      isAnonymous: data['isAnonymous'] ?? false,
      location: data['location'],
      photoUrls: List<String>.from(data['photos'] ?? []),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: data['type'] ?? 'Unknown',
      userId: data['userId'] ?? '',
    );
  }
}