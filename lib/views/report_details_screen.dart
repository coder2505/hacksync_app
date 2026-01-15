import 'package:flutter/material.dart';

import '../models/fetchIncident.dart';

class ReportDetailsScreen extends StatelessWidget {
  final ReportModel report;
  const ReportDetailsScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Incident Timeline"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 40),
            _buildTimelineTile(
              title: "Report Submitted",
              subtitle: "Incident logged by ${report.isAnonymous ? 'Anonymous' : 'User'}",
              time: report.timestamp,
              isCompleted: true,
              content: _buildImageGrid(report.photoUrls),
            ),
            if (report.userAgent != null)
              _buildTimelineTile(
                title: "AI Analysis Complete",
                subtitle: "Agent: ${report.userAgent!.department} Department",
                time: report.userAgent!.processedAt,
                isCompleted: true,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow("Issue", report.userAgent!.issueType),
                    _infoRow("Severity", report.userAgent!.severity),
                    _infoRow("Summary", report.userAgent!.summary),
                    if (report.userAgent!.visualVerification != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Detected: ${report.userAgent!.visualVerification!.detectedObjects.join(', ')}",
                          style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                        ),
                      ),
                  ],
                ),
              ),
            if (report.auditAgent != null)
              _buildTimelineTile(
                title: "Contractor Audited",
                subtitle: report.auditAgent!.foundContractor ? "Contractor Assigned" : "Searching for Contractor",
                isCompleted: true,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow("Name", report.auditAgent!.responsibleContractorName),
                    _infoRow("Audit", report.auditAgent!.auditReasoning),
                    _infoRow("Corruption Score", "${report.auditAgent!.corruptionScore}%"),
                  ],
                ),
              ),
            if (report.evidenceAgent != null)
              _buildTimelineTile(
                title: report.evidenceAgent!.isResolved ? "Issue Resolved" : "Awaiting Verification",
                subtitle: report.evidenceAgent!.isResolved ? "Final fix verified by Evidence Agent" : "Work in progress",
                time: report.evidenceAgent!.verifiedAt,
                isCompleted: report.evidenceAgent!.isResolved,
                isLast: true,
                content: report.evidenceAgent!.isResolved
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow("Quality", report.evidenceAgent!.fixQuality),
                    _infoRow("Notes", report.evidenceAgent!.afterImageDescription),
                    if (report.evidenceAgent!.evidenceImageUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(report.evidenceAgent!.evidenceImageUrl, height: 150, width: double.infinity, fit: BoxFit.cover),
                        ),
                      ),
                  ],
                )
                    : const Text("Still in progress...", style: TextStyle(fontStyle: FontStyle.italic)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(report.type, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Report ID: ${report.id}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildTimelineTile({
    required String title,
    required String subtitle,
    DateTime? time,
    required bool isCompleted,
    Widget? content,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.grey[300],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: isCompleted ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: isCompleted ? Colors.green : Colors.grey[200]),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (time != null)
                      Text(
                        "${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                  ],
                ),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                if (content != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: content,
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 13),
          children: [
            TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(List<String> urls) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: urls.map((url) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(url, width: 70, height: 70, fit: BoxFit.cover),
      )).toList(),
    );
  }
}