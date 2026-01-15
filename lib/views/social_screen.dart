import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Model for complaint report matching the Schema
class ComplaintReport {
  final String id;
  final String type;
  final GeoPoint location;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isAnonymous;
  final String userId;
  final int upvotes;
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
      upvotes: data['upvotes'] ?? 0,
    );
  }
}

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final Set<String> _localUpvotedIds = {};

  // Dark Mode Palette
  final Color _darkBg = const Color(0xFF121212);
  final Color _darkSurface = const Color(0xFF1E1E1E);
  final Color _textPrimary = Colors.white.withOpacity(0.9);
  final Color _textSecondary = Colors.white60;

  Future<void> _handleUpvote(ComplaintReport report) async {
    final docRef = FirebaseFirestore.instance.collection('reports').doc(report.id);
    final isUpvoting = !_localUpvotedIds.contains(report.id);

    setState(() {
      if (isUpvoting) {
        _localUpvotedIds.add(report.id);
      } else {
        _localUpvotedIds.remove(report.id);
      }
    });

    try {
      await docRef.set({
        'upvotes': FieldValue.increment(isUpvoting ? 1 : -1)
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating upvote: $e");
      setState(() {
        if (isUpvoting) {
          _localUpvotedIds.remove(report.id);
        } else {
          _localUpvotedIds.add(report.id);
        }
      });
    }
  }

  Color _getTypeColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('garbage') || t.contains('sanitation')) return Colors.orangeAccent.shade100;
    if (t.contains('pothole') || t.contains('road')) return Colors.redAccent.shade100;
    if (t.contains('light') || t.contains('electric')) return Colors.amberAccent.shade100;
    return Colors.blueAccent.shade100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _darkBg,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Nearby Issues',
          style: TextStyle(
            color: _textPrimary,
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
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: _textSecondary)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No reports found.', style: TextStyle(color: _textSecondary)));
          }

          final reports = snapshot.data!.docs.map((doc) {
            final report = ComplaintReport.fromFirestore(doc);
            report.hasUserUpvoted = _localUpvotedIds.contains(report.id);
            return report;
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    final accentColor = _getTypeColor(report.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      color: _darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white10, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Stack(
            children: [
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: report.imageUrl != null
                    ? ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    report.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50, color: Colors.white24),
                  ),
                )
                    : const Center(
                  child: Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.white24),
                ),
              ),
              // Floating Category Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    report.type,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Info
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: accentColor),
                    const SizedBox(width: 8),
                    Text(
                      locationStr,
                      style: TextStyle(fontSize: 13, color: _textPrimary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Reporter & Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 14, color: _textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          reporterDisplay,
                          style: TextStyle(fontSize: 12, color: _textSecondary),
                        ),
                      ],
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(fontSize: 12, color: _textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Bar (Upvote)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: InkWell(
              onTap: () => _handleUpvote(report),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: report.hasUserUpvoted
                      ? Colors.blueAccent.withOpacity(0.15)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: report.hasUserUpvoted
                        ? Colors.blueAccent.withOpacity(0.5)
                        : Colors.white10,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      report.hasUserUpvoted ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                      size: 18,
                      color: report.hasUserUpvoted ? Colors.blueAccent.shade100 : _textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${report.upvotes}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: report.hasUserUpvoted ? Colors.blueAccent.shade100 : _textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Support this issue',
                      style: TextStyle(
                        fontSize: 12,
                        color: report.hasUserUpvoted ? Colors.blueAccent.shade100 : _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
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

