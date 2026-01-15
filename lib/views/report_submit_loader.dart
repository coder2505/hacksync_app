import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gdg_hacksync/utils/upload_user_complaint.dart'; // Ensure this path is correct

class SubmissionProgressPage extends StatefulWidget {
  final bool isAnonymous;
  final LatLng currentPosition;
  final List<XFile> imageFiles;
  final String incidentType;

  const SubmissionProgressPage({
    super.key,
    required this.isAnonymous,
    required this.currentPosition,
    required this.imageFiles,
    required this.incidentType,
  });

  @override
  State<SubmissionProgressPage> createState() => _SubmissionProgressPageState();
}

class _SubmissionProgressPageState extends State<SubmissionProgressPage> {
  // Stages: 0 = Pending, 1 = In Progress, 2 = Completed, 3 = Error
  int _uploadStatus = 0;
  int _verificationStatus = 0;
  int _auditStatus = 0;

  String? _recordId;
  Map<String, dynamic>? _verificationResult;
  Map<String, dynamic>? _auditResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Start the chain immediately when page loads
    _startSubmissionProcess();
  }

  Future<void> _startSubmissionProcess() async {
    try {
      // --- STAGE 1: Uploading ---
      setState(() => _uploadStatus = 1);

      _recordId = await UploadUserComplaint.upload(
        widget.isAnonymous,
        widget.currentPosition,
        widget.imageFiles,
        DateTime.now(),
        widget.incidentType,
        dotenv.env['USERID'] ?? "manishbaby123",
      );

      setState(() {
        _uploadStatus = 2;
        _verificationStatus = 1; // Start next stage
      });

      // --- STAGE 2: Verification Agent ---
      await _triggerUserAgentApi(_recordId!);

      // --- STAGE 3: Audit Agent ---
      setState(() {
        _verificationStatus = 2;
        _auditStatus = 1; // Start next stage
      });

      await _triggerAuditAgentApi(_recordId!);

      setState(() => _auditStatus = 2); // All Done

    } catch (e) {
      debugPrint("Process Failed: $e");
      setState(() {
        _errorMessage = e.toString();
        // Mark current running stage as error
        if (_uploadStatus == 1) _uploadStatus = 3;
        else if (_verificationStatus == 1) _verificationStatus = 3;
        else if (_auditStatus == 1) _auditStatus = 3;
      });
    }
  }

  Future<void> _triggerUserAgentApi(String recordId) async {
    final url = Uri.parse("https://impossibly-lenten-darryl.ngrok-free.dev/api/userAgent");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"recordId": recordId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _verificationResult = data;
        });
      } else {
        throw Exception("Verification Agent failed: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _triggerAuditAgentApi(String recordId) async {
    final url = Uri.parse("https://impossibly-lenten-darryl.ngrok-free.dev/api/auditAgent");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"recordId": recordId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _auditResult = data;
        });
      } else {
        throw Exception("Audit Agent failed: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    // If all stages are complete (success or error), allow going back
    bool isComplete = _auditStatus == 2 || _errorMessage != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Processing Report", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Prevent back button during process
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStep(
              title: "Uploading Evidence",
              status: _uploadStatus,
              icon: Icons.cloud_upload_outlined,
            ),
            const SizedBox(height: 16),
            _buildStep(
              title: "Verifying with AI Agent",
              status: _verificationStatus,
              icon: Icons.verified_user_outlined,
              child: _verificationStatus >= 1
                  ? _buildVerificationResult(_verificationResult, _verificationStatus == 1)
                  : null,
            ),
            const SizedBox(height: 16),
            _buildStep(
              title: "Auditing & Contractor Search",
              status: _auditStatus,
              icon: Icons.gavel_outlined,
              child: _auditStatus >= 1
                  ? _buildAuditResult(_auditResult, _auditStatus == 1)
                  : null,
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text("Error: $_errorMessage", style: TextStyle(color: Colors.red.shade800)),
                ),
              ),

            const SizedBox(height: 40),

            if (isComplete)
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true), // Return true to refresh prev screen
                style: ElevatedButton.styleFrom(
                  backgroundColor: _errorMessage == null ? Colors.green : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_errorMessage == null ? "Done" : "Close"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required String title,
    required int status, // 0: Pending, 1: Loading, 2: Done, 3: Error
    required IconData icon,
    Widget? child,
  }) {
    Color color;
    IconData statusIcon;

    switch (status) {
      case 1:
        color = Colors.blue;
        statusIcon = Icons.hourglass_top;
        break;
      case 2:
        color = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 3:
        color = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        color = Colors.grey;
        statusIcon = Icons.circle_outlined;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 1 ? Colors.blue.withOpacity(0.5) : Colors.grey.shade200,
          width: status == 1 ? 2 : 1,
        ),
        boxShadow: [
          if (status == 1)
            BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: status == 0 ? Colors.grey : Colors.black87,
                  ),
                ),
              ),
              if (status == 1)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              else
                Icon(statusIcon, color: color),
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            child,
          ]
        ],
      ),
    );
  }

  Widget _buildVerificationResult(Map<String, dynamic>? data, bool isLoading) {
    if (isLoading || data == null) {
      return _buildShimmerLines();
    }

    // Parse the JSON structure from your example
    final aiResult = data['aiResult'];
    final userAgent = aiResult?['userAgent'] ?? {};
    final visual = userAgent['visualVerification'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow("Department", userAgent['department'] ?? 'Unknown'),
        _infoRow("Detected", (visual['detectedObjects'] as List?)?.join(", ") ?? 'None'),
        _infoRow("Severity", (userAgent['severity'] ?? 'Low').toString().toUpperCase()),
        _infoRow("Confidence", "${((userAgent['confidenceScore'] ?? 0) * 100).toStringAsFixed(0)}%"),
        const SizedBox(height: 8),
        Text(
          userAgent['summary'] ?? '',
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildAuditResult(Map<String, dynamic>? data, bool isLoading) {
    if (isLoading || data == null) {
      return _buildShimmerLines();
    }

    final audit = data['audit'] ?? {};
    final agent = audit['auditAgent'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow("Contractor Found", agent['foundContractor'] == true ? "Yes" : "No"),
        if (agent['foundContractor'] == true)
          _infoRow("Name", agent['responsibleContractorName'] ?? 'Unknown'),

        _infoRow("Corruption Score", "${agent['corruptionScore'] ?? 0}"),
        _infoRow("Status", (audit['auditStatus'] ?? '').toString().replaceAll('_', ' ').toUpperCase(),
            color: (audit['auditStatus'] == 'flagged_for_action') ? Colors.red : Colors.black),

        const SizedBox(height: 8),
        Text(
          agent['auditReasoning'] ?? '',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color))),
        ],
      ),
    );
  }

  // Simple Shimmer Effect using opacity animation
  Widget _buildShimmerLines() {
    return const _ShimmerBlock();
  }
}

class _ShimmerBlock extends StatefulWidget {
  const _ShimmerBlock();

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 12, width: 200, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Container(height: 12, width: 150, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Container(height: 12, width: 180, color: Colors.grey.shade300),
        ],
      ),
    );
  }
}