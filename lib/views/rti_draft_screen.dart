import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/fetchIncident.dart'; // Import your model

class RTIDraftScreen extends StatefulWidget {
  final ReportModel report;
  const RTIDraftScreen({super.key, required this.report});

  @override
  State<RTIDraftScreen> createState() => _RTIDraftScreenState();
}

class _RTIDraftScreenState extends State<RTIDraftScreen> {
  final TextEditingController _draftController = TextEditingController();
  bool _isLoading = true;
  String _statusMessage = "Initializing AI...";

  // Dark Mode Palette (consistent with your app)
  final Color _darkBg = const Color(0xFF121212);
  final Color _cardColor = const Color(0xFF252525);
  final Color _textPrimary = const Color(0xFFF5F5F5);
  final Color _textSecondary = const Color(0xFFB0B0B0);

  @override
  void initState() {
    super.initState();
    _generateRTIDraft();
  }

  Future<void> _generateRTIDraft() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Analyzing report details...";
    });

    try {
      // 1. Construct the prompt with report data
      final prompt = _buildPrompt(widget.report);

      // 2. Call Ollama API
      // REPLACE with your actual Ollama URL (e.g., http://10.0.2.2:11434/api/generate for Android Emulator)
      final url = Uri.parse("https://8d8e1077e8b2.ngrok-free.app/api/generate");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "model": "llama3.2", // or "mistral", "gemma", etc.
          "prompt": prompt,
          "stream": false
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final generatedText = data['response'];

        setState(() {
          _draftController.text = generatedText;
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to generate draft: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _draftController.text = "Error generating draft. Please try again or write manually.\n\nError: $e";
      });
    }
  }

  String _buildPrompt(ReportModel r) {
    return """
    You are a legal assistant helping a citizen draft a Right to Information (RTI) application in India.
    
    Using the following incident report details, write a formal RTI application addressed to the Public Information Officer (PIO) of the relevant department.
    
    INCIDENT DETAILS:
    - Incident Type: ${r.type}
    - Location Lat/Long: ${r.location.latitude}, ${r.location.longitude}
    - Date Reported: ${r.timestamp}
    - Department Identified: ${r.userAgent?.department ?? 'General Municipal Corp'}
    - Severity: ${r.userAgent?.severity ?? 'Unknown'}
    - Contractor Name (if found): ${r.auditAgent?.responsibleContractorName ?? 'Unknown'}
    - AI Verification Summary: ${r.userAgent?.summary ?? 'N/A'}
    
    REQUESTED INFORMATION:
    1. Certified copy of the work order/contract for the maintenance of this location.
    2. Name and designation of the official responsible for supervising this work.
    3. Reason why the issue persists despite the severity being marked as ${r.userAgent?.severity}.
    4. Timeline for when this issue will be permanently resolved.

    FORMAT:
    - Formal letter format.
    - Subject: Application under Right to Information Act, 2005.
    - Leave placeholders like [Your Name], [Your Address] for the user to fill.
    """;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        title: Text("RTI Draft", style: TextStyle(color: _textPrimary)),
        backgroundColor: _darkBg,
        elevation: 0,
        iconTheme: IconThemeData(color: _textPrimary),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                // Add clipboard logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Copied to clipboard")),
                );
              },
            )
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Text(_statusMessage, style: TextStyle(color: _textSecondary)),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "This is an AI-generated draft. Please review and fill in your personal details before submitting.",
                      style: TextStyle(color: Colors.blueAccent.shade100, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _draftController,
                  maxLines: null, // Expands as needed
                  expands: true,
                  style: TextStyle(color: _textPrimary, fontSize: 14, height: 1.5),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Draft will appear here...",
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Implement Export to PDF or Share logic here
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Export as PDF"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}