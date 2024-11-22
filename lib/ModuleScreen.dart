import 'package:flutter/material.dart';
import 'SelectCohortScreen.dart';

class ModuleScreen extends StatelessWidget {
  final String role;

  const ModuleScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    // Debugging: Print the user's role
    print("User role: $role");

    // All available modules
    final List<Map<String, dynamic>> modules = [
      {"title": "Attendance", "icon": Icons.check_circle_outline},
      {"title": "Courses", "icon": Icons.book},
      {"title": "Grades", "icon": Icons.grade},
      {"title": "Announcements", "icon": Icons.announcement},
      {"title": "Complaint & Feedback", "icon": Icons.feedback},
      {"title": "Mapping", "icon": Icons.map},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Campus Connect',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
        ),
        backgroundColor: Colors.orange[700],
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: modules.length,
          itemBuilder: (context, index) {
            final module = modules[index];
            return GestureDetector(
              onTap: () {
                if (module["title"] == "Mapping" && role != "Admin") {
                  // Show access denied for non-admins tapping on Mapping
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Access Denied: Admins only'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else if (module["title"] == "Mapping" && role == "Admin") {
                  // Navigate to SelectCohortScreen for admin
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SelectCohortScreen(),
                    ),
                  );
                } else {
                  // Placeholder action for other modules
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Tapped on ${module["title"]}')),
                  );
                }
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      module["icon"],
                      size: 40,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      module["title"],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
