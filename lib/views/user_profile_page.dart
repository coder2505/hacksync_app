import 'package:flutter/material.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  // Dark Mode Palette
  final Color _darkBg = const Color(0xFF121212);
  final Color _darkSurface = const Color(0xFF1E1E1E);
  final Color _textPrimary = Colors.white.withOpacity(0.9);
  final Color _textSecondary = Colors.white60;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _darkSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("Profile", style: TextStyle(color: _textPrimary)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopBanner(),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Your Reputation"),
                  const SizedBox(height: 16),
                  _buildCredibilityScore(),
                  const SizedBox(height: 32),
                  _buildSectionTitle("Community Impact"),
                  const SizedBox(height: 16),
                  _buildImpactStats(),
                  const SizedBox(height: 32),
                  _buildSectionTitle("Account Activity"),
                  const SizedBox(height: 16),
                  _buildActivityGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _darkSurface,
        border: const Border(bottom: BorderSide(color: Colors.white10, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      child: Row(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.blueAccent.withOpacity(0.2),
            child: const Icon(Icons.person, size: 50, color: Colors.blueAccent),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Manish",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amberAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 16, color: Colors.amberAccent.shade100),
                      const SizedBox(width: 4),
                      Text(
                        "Verified Contributor",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amberAccent.shade100,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredibilityScore() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: 0.85,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent.shade400),
                ),
              ),
              Text(
                "850",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _textPrimary),
              )
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Credibility Score",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  "Top 5% of reporters in Metro City. Keep reporting to maintain your rank.",
                  style: TextStyle(fontSize: 12, color: _textSecondary),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildImpactStats() {
    return Column(
      children: [
        _buildStatCard(
          "Flagged Projects Value",
          "₹1.2 Cr",
          Icons.currency_rupee,
          Colors.orangeAccent.shade100,
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          "Issues Resolved",
          "42",
          Icons.check_circle_outline,
          Colors.blueAccent.shade100,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: _textSecondary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          Icon(icon, size: 40, color: color.withOpacity(0.2)),
        ],
      ),
    );
  }

  Widget _buildActivityGrid() {
    return Row(
      children: [
        _buildSmallStat("Total Reports", "156"),
        const SizedBox(width: 16),
        _buildSmallStat("Upvotes", "2.4k"),
      ],
    );
  }

  Widget _buildSmallStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: _darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textPrimary)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: _textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _textPrimary,
      ),
    );
  }
}