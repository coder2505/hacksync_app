import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gdg_hacksync/utils/upload_user_complaint.dart';

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
  int _duplicateStatus = 0;
  int _auditStatus = 0;
  int _predictiveStatus = 0; // NEW STAGE

  String? _recordId;
  Map<String, dynamic>? _verificationResult;
  Map<String, dynamic>? _duplicateResult;
  Map<String, dynamic>? _auditResult;
  Map<String, dynamic>? _predictiveResult; // NEW RESULT
  String? _errorMessage;

  // Dark Mode Palette
  final Color _darkBg = const Color(0xFF121212);
  final Color _darkSurface = const Color(0xFF1E1E1E);
  final Color _textPrimary = Colors.white.withOpacity(0.9);
  final Color _textSecondary = Colors.white60;

  @override
  void initState() {
    super.initState();
    _startSubmissionProcess();
  }

  Future<void> _startSubmissionProcess() async {
    try {
      // --- STAGE 1: Upload ---
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
        _verificationStatus = 1;
      });

      // --- STAGE 2: Verification ---
      await _triggerUserAgentApi(_recordId!);

      setState(() {
        _verificationStatus = 2;
        _duplicateStatus = 1;
      });

      // --- STAGE 3: Duplicate Detection ---
      await _triggerDuplicateAgentApi(_recordId!);

      setState(() {
        _duplicateStatus = 2;
        _auditStatus = 1;
      });

      // --- STAGE 4: Audit ---
      await _triggerAuditAgentApi(_recordId!);

      setState(() {
        _auditStatus = 2;
        _predictiveStatus = 1; // Start Predictive Stage
      });

      // --- STAGE 5: Predictive Analysis (NEW) ---
      await _triggerPredictiveAgentApi(_recordId!);

      setState(() => _predictiveStatus = 2);

    } catch (e) {
      debugPrint("Process Failed: $e");
      setState(() {
        _errorMessage = e.toString();
        // Mark the active stage as error
        if (_uploadStatus == 1) _uploadStatus = 3;
        else if (_verificationStatus == 1) _verificationStatus = 3;
        else if (_duplicateStatus == 1) _duplicateStatus = 3;
        else if (_auditStatus == 1) _auditStatus = 3;
        else if (_predictiveStatus == 1) _predictiveStatus = 3;
      });
    }
  }

  // --- API CALLS ---

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
        setState(() => _verificationResult = data);
      } else {
        throw Exception("Verification Agent failed: ${response.statusCode}");
      }
    } catch (e) { rethrow; }
  }

  Future<void> _triggerDuplicateAgentApi(String recordId) async {
    final url = Uri.parse("https://impossibly-lenten-darryl.ngrok-free.dev/api/duplicateDetectionAgent");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"recordId": recordId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() => _duplicateResult = data);
      } else {
        throw Exception("Duplicate Detection Agent failed: ${response.statusCode}");
      }
    } catch (e) { rethrow; }
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
        setState(() => _auditResult = data);
      } else {
        throw Exception("Audit Agent failed: ${response.statusCode}");
      }
    } catch (e) { rethrow; }
  }

  Future<void> _triggerPredictiveAgentApi(String recordId) async {
    final url = Uri.parse("https://impossibly-lenten-darryl.ngrok-free.dev/api/predictiveAgent");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"recordId": recordId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() => _predictiveResult = data);
      } else {
        throw Exception("Predictive Agent failed: ${response.statusCode}");
      }
    } catch (e) { rethrow; }
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    bool isComplete = _predictiveStatus == 2 || _errorMessage != null;

    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        title: Text("Processing Report", style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: _darkBg,
        elevation: 0,
        automaticallyImplyLeading: false,
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
              title: "Checking for Duplicates",
              status: _duplicateStatus,
              icon: Icons.copy_all_outlined,
              child: _duplicateStatus >= 1
                  ? _buildDuplicateResult(_duplicateResult, _duplicateStatus == 1)
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
            const SizedBox(height: 16),
            // NEW PREDICTIVE STEP
            _buildStep(
              title: "Future Risk & Cost Analysis",
              status: _predictiveStatus,
              icon: Icons.analytics_outlined,
              child: _predictiveStatus >= 1
                  ? _buildPredictiveResult(_predictiveResult, _predictiveStatus == 1)
                  : null,
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Text("Error: $_errorMessage", style: TextStyle(color: Colors.redAccent.shade100, fontSize: 13)),
                ),
              ),

            const SizedBox(height: 40),

            if (isComplete)
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _errorMessage == null ? Colors.greenAccent.shade700 : Colors.white10,
                  foregroundColor: _errorMessage == null ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(_errorMessage == null ? "Done" : "Close", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required String title,
    required int status,
    required IconData icon,
    Widget? child,
  }) {
    Color color;
    IconData statusIcon;

    switch (status) {
      case 1:
        color = Colors.blueAccent;
        statusIcon = Icons.hourglass_top;
        break;
      case 2:
        color = Colors.greenAccent;
        statusIcon = Icons.check_circle;
        break;
      case 3:
        color = Colors.redAccent;
        statusIcon = Icons.error;
        break;
      default:
        color = Colors.white24;
        statusIcon = Icons.circle_outlined;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 1 ? Colors.blueAccent.withOpacity(0.5) : Colors.white10,
          width: status == 1 ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: status == 0 ? _textSecondary : _textPrimary,
                  ),
                ),
              ),
              if (status == 1)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent))
              else
                Icon(statusIcon, color: color, size: 20),
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            child,
          ]
        ],
      ),
    );
  }

  // --- RESULT WIDGETS ---

  Widget _buildVerificationResult(Map<String, dynamic>? data, bool isLoading) {
    if (isLoading || data == null) return const _ShimmerBlock();

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
        const SizedBox(height: 10),
        Text(
          userAgent['summary'] ?? '',
          style: TextStyle(fontSize: 12, color: _textSecondary, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildDuplicateResult(Map<String, dynamic>? data, bool isLoading) {
    if (isLoading || data == null) return const _ShimmerBlock();

    final detection = data['duplicateDetection'] ?? {};
    final isDuplicate = detection['isDuplicate'] == true;
    final message = detection['reasoning'] ?? detection['message'] ?? 'Check completed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(
            "Duplicate Found",
            isDuplicate ? "YES" : "NO",
            color: isDuplicate ? Colors.redAccent : Colors.greenAccent
        ),
        if (isDuplicate)
          _infoRow("Original Report", detection['originalReportId'] ?? 'Unknown'),

        const SizedBox(height: 10),
        Text(
          message,
          style: TextStyle(fontSize: 12, color: _textSecondary),
        ),
      ],
    );
  }

  Widget _buildAuditResult(Map<String, dynamic>? data, bool isLoading) {
    if (isLoading || data == null) return const _ShimmerBlock();

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
            color: (audit['auditStatus'] == 'flagged_for_action') ? Colors.redAccent.shade100 : _textPrimary),

        const SizedBox(height: 10),
        Text(
          agent['auditReasoning'] ?? '',
          style: TextStyle(fontSize: 12, color: _textSecondary),
        ),
      ],
    );
  }

  Widget _buildPredictiveResult(Map<String, dynamic>? data, bool isLoading) {
    if (isLoading || data == null) return const _ShimmerBlock();

    final prediction = data['prediction'] ?? {};
    final agent = prediction['predictiveAgent'] ?? {};
    final cost = agent['costAnalysis'] ?? {};

    final savings = cost['savings'] ?? 0;
    final condition = agent['currentCondition'] ?? 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _infoRow("Condition", condition.toString().toUpperCase(), color: Colors.orangeAccent)),
            Expanded(child: _infoRow("Timeline", agent['predictedFailureTimeline'] ?? 'N/A')),
          ],
        ),
        const SizedBox(height: 12),
        // Cost Savings Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Potential Savings:", style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text(
                "₹${(savings / 1000000).toStringAsFixed(1)}M",
                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          agent['actionableInsight'] ?? '',
          style: TextStyle(fontSize: 12, color: _textSecondary, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: _textSecondary)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color ?? _textPrimary)),
        ],
      ),
    );
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
      opacity: Tween<double>(begin: 0.2, end: 0.6).animate(_controller),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 10, width: 200, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 10),
          Container(height: 10, width: 140, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 10),
          Container(height: 10, width: 170, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }
}