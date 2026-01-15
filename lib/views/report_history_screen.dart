import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gdg_hacksync/views/report_details_screen.dart';
import 'package:geocoding/geocoding.dart';
import '../models/fetchIncident.dart';
import '../utils/retrieve_user_complaints.dart';

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  final String dummyUserId = dotenv.env["USERID"] ?? "manishbaby123";
  late Future<List<ReportModel>> _reportsFuture;

  // Dark Mode Palette
  final Color _darkBg = const Color(0xFF121212);
  final Color _darkSurface = const Color(0xFF1E1E1E);
  final Color _textPrimary = Colors.white.withOpacity(0.9);
  final Color _textSecondary = Colors.white60;

  @override
  void initState() {
    super.initState();
    _reportsFuture = RetrieveUserComplaints.fetch(dummyUserId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        title: Text('My Reports',
            style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary)
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: _darkBg,
        foregroundColor: _textPrimary,
        iconTheme: IconThemeData(color: _textPrimary),
      ),
      body: FutureBuilder<List<ReportModel>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: _textSecondary)));
          }

          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_outlined, size: 64, color: Colors.white10),
                  const SizedBox(height: 16),
                  Text("No reports found", style: TextStyle(color: _textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              return _ReportCard(
                report: reports[index],
                darkSurface: _darkSurface,
                textPrimary: _textPrimary,
                textSecondary: _textSecondary,
              );
            },
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  final Color darkSurface;
  final Color textPrimary;
  final Color textSecondary;

  const _ReportCard({
    required this.report,
    required this.darkSurface,
    required this.textPrimary,
    required this.textSecondary,
  });

  Future<String> _getAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark p = placemarks[0];
        return "${p.street}, ${p.locality}";
      }
      return "Location Found";
    } catch (e) {
      return "Lat: ${lat.toStringAsFixed(2)}, Lng: ${lng.toStringAsFixed(2)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logic for Stepper Status
    int currentStep = 0; // Submitted
    if (report.userAgent != null) currentStep = 1; // Processed
    if (report.evidenceAgent?.isResolved ?? false) currentStep = 2; // Resolved

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReportDetailsScreen(report: report)),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white10, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          report.type.toUpperCase(),
                          style: TextStyle(
                            color: Colors.blueAccent.shade100,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      Text(
                        "${report.timestamp.day}/${report.timestamp.month}/${report.timestamp.year}",
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.redAccent.shade100),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FutureBuilder<String>(
                          future: _getAddress(report.location.latitude, report.location.longitude),
                          builder: (context, snap) => Text(
                            snap.data ?? "Fetching...",
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Visual Stepper
                  Row(
                    children: [
                      _buildStep("Submitted", true, true),
                      _buildLine(currentStep >= 1),
                      _buildStep("Processed", currentStep >= 1, currentStep >= 1),
                      _buildLine(currentStep >= 2),
                      _buildStep("Resolved", currentStep >= 2, currentStep >= 2),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String title, bool isActive, bool isCompleted) {
    Color stepColor = isCompleted
        ? Colors.greenAccent.shade400
        : (isActive ? Colors.blueAccent.shade200 : Colors.white12);

    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: stepColor.withOpacity(0.2),
          child: isCompleted
              ? Icon(Icons.check, size: 14, color: stepColor)
              : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: stepColor, shape: BoxShape.circle)
          ),
        ),
        const SizedBox(height: 6),
        Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? textPrimary : textSecondary,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            )
        ),
      ],
    );
  }

  Widget _buildLine(bool isPassed) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 15),
        decoration: BoxDecoration(
          color: isPassed ? Colors.greenAccent.shade400.withOpacity(0.5) : Colors.white10,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}