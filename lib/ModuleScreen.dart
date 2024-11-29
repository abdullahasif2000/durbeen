import 'package:flutter/material.dart';
import 'SelectCohortScreen.dart';
import 'api_service.dart';
import 'LoginScreen.dart';
import 'CreateSectionScreen.dart';  // Import CreateSectionScreen
import 'package:shared_preferences/shared_preferences.dart';

class ModuleScreen extends StatefulWidget {
  final String role;

  const ModuleScreen({super.key, required this.role});

  @override
  _ModuleScreenState createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  String? selectedSession; // Variable to store the selected session
  List<Map<String, dynamic>> sessions = []; // To hold the session data

  @override
  void initState() {
    super.initState();
    if (widget.role == "Admin") {
      _fetchSessions(); // Fetch available sessions only if role is Admin
    }
    _loadSession(); // Load the session ID if already saved
  }

  // Fetch the available sessions from the API
  Future<void> _fetchSessions() async {
    try {
      final List<dynamic> data = await ApiService().fetchSessions();
      setState(() {
        sessions = data.map((session) {
          return {
            'id': session['SessionID'],
            'description': session['Description'],
            'current': session['Current']
          };
        }).toList();
      });
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching sessions: $e')),
      );
    }
  }

  // Handle session selection from the dropdown
  void _selectSession(String? sessionId) async {
    setState(() {
      selectedSession = sessionId;
    });

    // Save session to SharedPreferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('sessionID', sessionId ?? ''); // Save the selected session

    Navigator.pop(context); // Close the drawer after selection
  }

  // Retrieve session ID from SharedPreferences
  void _loadSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedSession = prefs.getString('sessionID');
    });
  }

  // Navigate to CreateSectionScreen and pass the session ID
  void _goToCreateSection() {
    if (selectedSession != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateSectionScreen(
            cohort: "Cohort Example", // Use the appropriate cohort
            selectedCourses: [], // Pass selected courses as needed
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a session first')),
      );
    }
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      // Drawer widget to show session options for admin and logout option
      drawer: widget.role == "Admin"
          ? Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.orange,
              ),
              child: Text(
                'Admin Options',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Session selector dropdown in the drawer
            ListTile(
              title: const Text('Select Session'),
              trailing: DropdownButton<String>(
                value: selectedSession,
                hint: const Text("Choose Session"),
                icon: const Icon(Icons.arrow_downward),
                onChanged: (String? newValue) {
                  _selectSession(newValue);
                },
                items: sessions.map<DropdownMenuItem<String>>((session) {
                  return DropdownMenuItem<String>(
                    value: session['id'],
                    child: Text(session['description']),
                  );
                }).toList(),
              ),
            ),

            // Logout option
            ListTile(
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      )
          : null,
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
                if (module["title"] == "Mapping" && widget.role != "Admin") {
                  // Show access denied for non-admins tapping on Mapping
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Access Denied: Admins only'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else if (module["title"] == "Mapping" && widget.role == "Admin") {
                  // Navigate to SelectCohortScreen for admin
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SelectCohortScreen(),
                    ),
                  );
                } else {
                  // Navigate to CreateSectionScreen for other modules
                  if (module["title"] == "Courses") {
                    _goToCreateSection();
                  } else {
                    // Placeholder action for other modules
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tapped on ${module["title"]}')),
                    );
                  }
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
