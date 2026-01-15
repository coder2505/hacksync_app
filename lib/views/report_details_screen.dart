import 'package:flutter/material.dart';
import '../models/fetchIncident.dart';

class ReportDetailsScreen extends StatelessWidget {
  final ReportModel report;
  const ReportDetailsScreen({super.key, required this.report});

  // Dark Mode Palette
  final Color _darkBg = const Color(0xFF121212);
  final Color _darkSurface = const Color(0xFF1E1E1E);
  final Color _cardColor = const Color(0xFF252525);
  final Color _textPrimary = const Color(0xFFF5F5F5);
  final Color _textSecondary = const Color(0xFFB0B0B0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        title: Text("Incident Timeline", style: TextStyle(color: _textPrimary)),
        elevation: 0,
        backgroundColor: _darkBg,
        foregroundColor: _textPrimary,
        iconTheme: IconThemeData(color: _textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 40, color: Colors.white10),
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
                          style: TextStyle(fontSize: 12, color: Colors.blueAccent.shade100),
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
                        padding: const EdgeInsets.only(top: 12.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                              report.evidenceAgent!.evidenceImageUrl,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover
                          ),
                        ),
                      ),
                  ],
                )
                    : Text(
                    "Still in progress...",
                    style: TextStyle(fontStyle: FontStyle.italic, color: _textSecondary)
                ),
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
        Text(report.type, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textPrimary)),
        const SizedBox(height: 4),
        Text("Report ID: ${report.id}", style: TextStyle(color: _textSecondary, fontSize: 12)),
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
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.greenAccent.shade400 : Colors.white10,
                  shape: BoxShape.circle,
                  border: Border.all(color: _darkBg, width: 3),
                ),
                child: isCompleted ? const Icon(Icons.check, size: 12, color: Colors.black) : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                      width: 2,
                      color: isCompleted ? Colors.greenAccent.shade400.withOpacity(0.5) : Colors.white10
                  ),
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
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textPrimary)),
                    if (time != null)
                      Text(
                        "${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
                        style: TextStyle(color: _textSecondary, fontSize: 11),
                      ),
                  ],
                ),
                Text(subtitle, style: TextStyle(color: _textSecondary, fontSize: 13)),
                if (content != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: _textPrimary.withOpacity(0.8), fontSize: 13, height: 1.4),
          children: [
            TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(List<String> urls) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: urls.map((url) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 80, height: 80, color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white24),
          ),
        ),
      )).toList(),
    );
  }
}