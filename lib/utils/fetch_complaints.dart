import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

// --- MODEL ---
class ComplaintReport {
  final String id;
  final String type;
  final LatLng location;
  final String? imageUrl;
  final DateTime timestamp;
  final int upvotes;

  ComplaintReport({
    required this.id,
    required this.type,
    required this.location,
    this.imageUrl,
    required this.timestamp,
    required this.upvotes,
  });

  factory ComplaintReport.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle GeoPoint conversion safely
    GeoPoint geo = data['location'] is GeoPoint ? data['location'] : const GeoPoint(0, 0);

    // Handle Photos array
    List<dynamic> photos = data['photos'] ?? [];
    String? imgUrl = photos.isNotEmpty ? photos.first.toString() : null;

    return ComplaintReport(
      id: doc.id,
      type: data['type'] ?? 'Reported Issue',
      location: LatLng(geo.latitude, geo.longitude),
      imageUrl: imgUrl,
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      upvotes: data['upvotes'] ?? 0,
    );
  }
}

// --- PROVIDER ---
// This stream will automatically update whenever new reports are added to Firestore
final complaintsStreamProvider = StreamProvider<List<ComplaintReport>>((ref) {
  return FirebaseFirestore.instance
      .collection('reports')
  // Optional: limit to last 50 or filter by time to keep map clean
      .orderBy('timestamp', descending: true)
      .limit(100)
      .snapshots()
      .map((snapshot) => snapshot.docs
      .map((doc) => ComplaintReport.fromFirestore(doc))
      .toList());
});