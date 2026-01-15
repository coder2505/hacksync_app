import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gdg_hacksync/views/report_details_screen.dart';
import 'package:geocoding/geocoding.dart';
import '../models/fetchIncident.dart';
import '../utils/retrieve_user_complaints.dart'; // This contains the model and fetcher

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  final String dummyUserId = dotenv.env["USERID"] ?? "manishbaby123";
  late Future<List<ReportModel>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = RetrieveUserComplaints.fetch(dummyUserId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Reports', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<List<ReportModel>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return const Center(child: Text("No reports found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              return _ReportCard(report: reports[index]);
            },
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  const _ReportCard({required this.report});

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
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
                      Text(
                        report.type.toUpperCase(),
                        style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        "${report.timestamp.day}/${report.timestamp.month}/${report.timestamp.year}",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.red),
                      const SizedBox(width: 4),
                      Expanded(
                        child: FutureBuilder<String>(
                          future: _getAddress(report.location.latitude, report.location.longitude),
                          builder: (context, snap) => Text(
                            snap.data ?? "Fetching...",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Simple Visual Stepper
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
    return Column(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: isCompleted ? Colors.green : (isActive ? Colors.blue : Colors.grey[300]),
          child: isCompleted
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
        ),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 10, color: isActive ? Colors.black87 : Colors.grey)),
      ],
    );
  }

  Widget _buildLine(bool isPassed) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 15),
        color: isPassed ? Colors.green : Colors.grey[300],
      ),
    );
  }
}