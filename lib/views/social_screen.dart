import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Model for complaint report
class ComplaintReport {
  final String id;
  final String title;
  final String description;
  final String category;
  final String address;
  final double latitude;
  final double longitude;
  final String reporterName;
  final DateTime createdAt;
  final String status; // "Open", "In Progress", "Resolved"
  final String imageUrl;
  int upvotes;
  bool hasUserUpvoted;

  ComplaintReport({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.reporterName,
    required this.createdAt,
    required this.status,
    required this.imageUrl,
    this.upvotes = 0,
    this.hasUserUpvoted = false,
  });
}

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  // Hardcoded complaint reports
  late List<ComplaintReport> reports;

  @override
  void initState() {
    super.initState();
    reports = [
      ComplaintReport(
        id: '1',
        title: 'Pothole on Main Street',
        description: 'Large pothole causing traffic hazards near the intersection',
        category: 'Road Damage',
        address: '123 Main Street, Downtown',
        latitude: 40.7128,
        longitude: -74.0060,
        reporterName: 'John Doe',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'Open',
        imageUrl:
            'https://via.placeholder.com/400x300?text=Pothole',
        upvotes: 24,
        hasUserUpvoted: false,
      ),
      ComplaintReport(
        id: '2',
        title: 'Broken Street Light',
        description: 'Street lamp not functioning at night, poses safety risk',
        category: 'Infrastructure',
        address: '456 Oak Avenue, Westside',
        latitude: 40.7180,
        longitude: -74.0020,
        reporterName: 'Sarah Smith',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        status: 'In Progress',
        imageUrl:
            'https://via.placeholder.com/400x300?text=Broken+Light',
        upvotes: 18,
        hasUserUpvoted: false,
      ),
      ComplaintReport(
        id: '3',
        title: 'Graffiti on Park Wall',
        description: 'Unauthorized graffiti covering the entire community park wall',
        category: 'Vandalism',
        address: '789 Park Lane, Central Park',
        latitude: 40.7649,
        longitude: -73.9776,
        reporterName: 'Mike Johnson',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        status: 'Open',
        imageUrl:
            'https://via.placeholder.com/400x300?text=Graffiti',
        upvotes: 31,
        hasUserUpvoted: false,
      ),
      ComplaintReport(
        id: '4',
        title: 'Garbage Overflow',
        description: 'Trash bins overflowing, attracting pests and animals',
        category: 'Sanitation',
        address: '321 Elm Street, Eastside',
        latitude: 40.7282,
        longitude: -73.7949,
        reporterName: 'Emily Chen',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        status: 'Resolved',
        imageUrl:
            'https://via.placeholder.com/400x300?text=Garbage',
        upvotes: 12,
        hasUserUpvoted: true,
      ),
      ComplaintReport(
        id: '5',
        title: 'Water Pipe Leakage',
        description: 'Water main leak causing flooding on residential block',
        category: 'Utilities',
        address: '555 River Road, North District',
        latitude: 40.8088,
        longitude: -73.9482,
        reporterName: 'Robert Wilson',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: 'In Progress',
        imageUrl:
            'https://via.placeholder.com/400x300?text=Water+Leak',
        upvotes: 45,
        hasUserUpvoted: false,
      ),
      ComplaintReport(
        id: '6',
        title: 'Overgrown Vegetation',
        description: 'Sidewalk blocked by overgrown tree branches and vines',
        category: 'Maintenance',
        address: '888 Forest Drive, Green Zone',
        latitude: 40.6895,
        longitude: -74.0119,
        reporterName: 'Lisa Anderson',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        status: 'Open',
        imageUrl:
            'https://via.placeholder.com/400x300?text=Vegetation',
        upvotes: 8,
        hasUserUpvoted: false,
      ),
    ];
  }

  void _toggleUpvote(int index) {
    setState(() {
      if (reports[index].hasUserUpvoted) {
        reports[index].upvotes--;
      } else {
        reports[index].upvotes++;
      }
      reports[index].hasUserUpvoted = !reports[index].hasUserUpvoted;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Road Damage':
        return Colors.red.shade100;
      case 'Infrastructure':
        return Colors.yellow.shade100;
      case 'Vandalism':
        return Colors.purple.shade100;
      case 'Sanitation':
        return Colors.brown.shade100;
      case 'Utilities':
        return Colors.blue.shade100;
      case 'Maintenance':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
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
        centerTitle: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return _buildComplaintCard(report, index);
        },
      ),
    );
  }

  Widget _buildComplaintCard(ComplaintReport report, int index) {
    final timeAgo = _getTimeAgo(report.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              color: Colors.grey.shade300,
            ),
            child: Stack(
              children: [
                // Placeholder image
                Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey.shade600,
                  ),
                ),
                // Status badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(report.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      report.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(report.category),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    report.category,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Title
                Text(
                  report.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Description
                Text(
                  report.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        report.address,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Meta info row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reported by',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          report.reporterName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Upvote Section
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleUpvote(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: report.hasUserUpvoted
                          ? Colors.blue.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: report.hasUserUpvoted
                            ? Colors.blue.shade300
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          report.hasUserUpvoted
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined,
                          size: 18,
                          color: report.hasUserUpvoted
                              ? Colors.blue.shade700
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${report.upvotes}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: report.hasUserUpvoted
                                ? Colors.blue.shade700
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: BorderSide(color: Colors.grey.shade300),
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
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}

