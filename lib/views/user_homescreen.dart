import 'package:flutter/material.dart';
import 'package:gdg_hacksync/views/report_a_complaint.dart';

class UserHomescreen extends StatefulWidget {
  const UserHomescreen({super.key});

  @override
  State<UserHomescreen> createState() => _UserHomescreenState();
}

class _UserHomescreenState extends State<UserHomescreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              const Text(
                "Welcome back,",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Text(
                "Manish",
                style: TextStyle(
                  fontSize: 36,
                  color: Colors.black,
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
                    title: "Report History",
                    icon: Icons.history,
                    color: Colors.blue.shade50,
                    iconColor: Colors.blue.shade700,
                    onTap: () {},
                  ),
                  _buildActionCard(
                    title: "Issues Around You",
                    icon: Icons.near_me,
                    color: Colors.green.shade50,
                    iconColor: Colors.green.shade700,
                    onTap: () {},
                  ),
                  _buildActionCard(
                    title: "Heat Map",
                    icon: Icons.map_outlined,
                    color: Colors.orange.shade50,
                    iconColor: Colors.orange.shade700,
                    onTap: () {},
                  ),
                  _buildActionCard(
                    title: "Top Complained Projects",
                    icon: Icons.warning_amber_rounded,
                    color: Colors.red.shade50,
                    iconColor: Colors.red.shade900,
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Notification/Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_outlined,
                      color: Colors.amber.shade800,
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Text(
                        "Your recent report on 'Water Leakage' is being reviewed.",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
              builder: (context) => const ReportAComplaint(),
            ),
          );
        },
        backgroundColor: Colors.red.shade700,
        elevation: 4,
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: const Text(
          "Report a new issue",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  color: Colors.white.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: iconColor.withOpacity(0.9),
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
