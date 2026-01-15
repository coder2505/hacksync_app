import 'package:flutter/material.dart';
import 'package:gdg_hacksync/views/heat_map.dart';
import 'package:gdg_hacksync/views/map_navigation.dart';
import 'package:gdg_hacksync/views/report_a_complaint.dart';
import 'package:gdg_hacksync/views/report_history_screen.dart';
import 'package:gdg_hacksync/views/social_screen.dart';
import 'package:gdg_hacksync/views/user_profile_page.dart';

class UserHomescreen extends StatefulWidget {
  const UserHomescreen({super.key});

  @override
  State<UserHomescreen> createState() => _UserHomescreenState();
}

class _UserHomescreenState extends State<UserHomescreen> {
  // Dark Mode Palette
  final Color _darkBg = const Color(0xFF121212);
  final Color _darkSurface = const Color(0xFF1E1E1E);
  final Color _textPrimary = Colors.white.withOpacity(0.9);
  final Color _textSecondary = Colors.white60;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Text(
                "Welcome back,",
                style: TextStyle(
                  fontSize: 18,
                  color: _textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                "Manish",
                style: TextStyle(
                  fontSize: 36,
                  color: _textPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 40),

              // Action Grid (2 Rows, 2 Columns)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
                children: [
                  _buildActionCard(
                    title: "Profile",
                    icon: Icons.person,
                    color: Colors.greenAccent.withOpacity(0.1),
                    iconColor: Colors.greenAccent.shade100,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => UserProfilePage(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    title: "Report History",
                    icon: Icons.history,
                    color: Colors.blueAccent.withOpacity(0.1),
                    iconColor: Colors.blueAccent.shade100,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => ReportHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    title: "Heat Map",
                    icon: Icons.map_outlined,
                    color: Colors.orangeAccent.withOpacity(0.1),
                    iconColor: Colors.orangeAccent.shade100,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => HeatMap(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    title: "Issues Around You",
                    icon: Icons.warning_amber_rounded,
                    color: Colors.redAccent.withOpacity(0.1),
                    iconColor: Colors.redAccent.shade100,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => SocialScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                      title: "Plan your trip",
                      icon: Icons.map,
                      color: Colors.cyanAccent.withOpacity(0.1),
                      iconColor: Colors.cyanAccent.shade100,
                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => SimpleNavScreen(),
                          ),
                        );
                      }
                  )
                ],
              ),

              const SizedBox(height: 30),

              // Notification/Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _darkSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_outlined,
                      color: Colors.amberAccent.shade100,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        "Your recent report on 'Water Leakage' is being reviewed.",
                        style: TextStyle(
                          fontSize: 14,
                          color: _textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      ),
      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => ReportAComplaint(),
            ),
          );
        },
        backgroundColor: Colors.redAccent.shade200,
        elevation: 8,
        icon: const Icon(Icons.add_circle_outline, color: Colors.black87),
        label: const Text(
          "Report a new issue",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}