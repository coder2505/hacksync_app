import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Model for complaint report matching the Schema
class ComplaintReport {
  final String id;
  final String type; // Acts as title/category
  final GeoPoint location;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isAnonymous;
  final String userId;
  final int upvotes;

  // Local-only field to track if *this* user liked it during this session
  // Note: For permanent tracking, you'd need a 'likedBy' array in Firestore.
  bool hasUserUpvoted;

  ComplaintReport({
    required this.id,
    required this.type,
    required this.location,
    this.imageUrl,
    required this.timestamp,
    required this.isAnonymous,
    required this.userId,
    this.upvotes = 0,
    this.hasUserUpvoted = false,
  });

  factory ComplaintReport.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle Photos array safely
    List<dynamic> photos = data['photos'] ?? [];
    String? imgUrl = photos.isNotEmpty ? photos[0].toString() : null;

    return ComplaintReport(
      id: doc.id,
      type: data['type'] ?? 'Unknown Issue',
      location: data['location'] is GeoPoint
          ? data['location']
          : const GeoPoint(0, 0),
      imageUrl: imgUrl,
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isAnonymous: data['isAnonymous'] ?? false,
      userId: data['userId'] ?? 'Unknown',
      upvotes: data['upvotes'] ?? 0, // Defaults to 0 if field is missing
    );
  }
}

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  // Keep track of locally upvoted IDs for session persistence
  final Set<String> _localUpvotedIds = {};

  Future<void> _handleUpvote(ComplaintReport report) async {
    final docRef = FirebaseFirestore.instance.collection('reports').doc(report.id);
    final isUpvoting = !_localUpvotedIds.contains(report.id);

    // 1. Update Local State (for immediate UI feedback)
    setState(() {
      if (isUpvoting) {
        _localUpvotedIds.add(report.id);
      } else {
        _localUpvotedIds.remove(report.id);
      }
    });

    // 2. Write to Firestore
    try {
      await docRef.set({
        'upvotes': FieldValue.increment(isUpvoting ? 1 : -1)
      }, SetOptions(merge: true)); // Merge ensures we don't overwrite other fields
    } catch (e) {
      debugPrint("Error updating upvote: $e");
      // Revert local state on error
      setState(() {
        if (isUpvoting) {
          _localUpvotedIds.remove(report.id);
        } else {
          _localUpvotedIds.add(report.id);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update vote: $e')),
        );
      }
    }
  }

  Color _getTypeColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('garbage') || t.contains('sanitation')) return Colors.brown.shade100;
    if (t.contains('pothole') || t.contains('road')) return Colors.red.shade100;
    if (t.contains('light') || t.contains('electric')) return Colors.yellow.shade100;
    return Colors.blue.shade100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Nearby Issues',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No reports found.'));
          }

          final reports = snapshot.data!.docs.map((doc) {
            final report = ComplaintReport.fromFirestore(doc);
            // Sync with local session state
            report.hasUserUpvoted = _localUpvotedIds.contains(report.id);
            return report;
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              return _buildComplaintCard(reports[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildComplaintCard(ComplaintReport report) {
    final timeAgo = _getTimeAgo(report.timestamp);
    final reporterDisplay = report.isAnonymous ? 'Anonymous' : report.userId;
    final locationStr = '${report.location.latitude.toStringAsFixed(4)}, ${report.location.longitude.toStringAsFixed(4)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: report.imageUrl != null
                ? ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                report.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
              ),
            )
                : const Center(
              child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTypeColor(report.type),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    report.type,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Location Info
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      locationStr,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Footer (Reporter & Time)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'By: $reporterDisplay',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Bar (Upvote)
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _handleUpvote(report),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: report.hasUserUpvoted ? Colors.blue.shade50 : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: report.hasUserUpvoted ? Colors.blue.shade200 : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          report.hasUserUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                          size: 18,
                          color: report.hasUserUpvoted ? Colors.blue : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${report.upvotes}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: report.hasUserUpvoted ? Colors.blue : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return DateFormat('MMM d').format(dateTime);
  }
}