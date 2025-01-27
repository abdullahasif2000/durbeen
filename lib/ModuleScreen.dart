import 'package:flutter/material.dart';
import 'SelectCohortScreen.dart';
import 'api_service.dart';
import 'LoginScreen.dart';
import 'CreateSectionScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AttendanceOptionScreen.dart';
import 'UserProfile.dart';

class ModuleScreen extends StatefulWidget {
  final String role;

  const ModuleScreen({super.key, required this.role});

  @override
  _ModuleScreenState createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  String? selectedSession;
  String? userRole;  // Variable to store the user role
  List<Map<String, dynamic>> sessions = [];

  @override
  void initState() {
    super.initState();
    _fetchSessions();
    _loadSession();
    _loadUserRole();  // Load the user role on initialization
  }

  Future<void> _fetchSessions() async {
    try {
      final List<dynamic> data = await ApiService().fetchSessions();

      // Find the session where 'Current' is 1
      final currentSession = data.firstWhere(
            (session) => session['Current'] == '1',
        orElse: () => {'SessionID': '', 'Description': '', 'Current': '0'}, // Return a default map
      );

      // If a current session is found, set it as the selected session
      if (currentSession['SessionID'] != '') {
        setState(() {
          selectedSession = currentSession['SessionID']; // Use SessionID for selectedSession
        });

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('SessionID', selectedSession ?? ''); // Save the selected session
        debugPrint('Default selected SessionID: $selectedSession');
      }

      // Map the session data for the dropdown
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

  void _selectSession(String? sessionId) async {
    setState(() {
      selectedSession = sessionId;
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('SessionID', sessionId ?? '');
    debugPrint('Saved SessionID: $sessionId');

    Navigator.pop(context);
  }

  void _loadSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedSession = prefs.getString('SessionID');
    });
  }

  void _loadUserRole() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedRole = prefs.getString('User  Role');  // Get the user role
    setState(() {
      userRole = storedRole;  // Update the state with the stored role
    });
  }

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

  void _logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get the current profile image path before clearing other data
    final String? profileImagePath = prefs.getString('profileImagePath');

    // Clear all keys except 'profileImagePath'
    await prefs.clear();

    // Restore the profile image path
    if (profileImagePath != null) {
      await prefs.setString('profileImagePath', profileImagePath);
    }

    debugPrint('All SharedPreferences data cleared except profileImagePath.');

    // Navigate to the LoginScreen
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

    // Filter modules based on role
    final List<Map<String, dynamic>> filteredModules = modules.where((module) {
      if (widget.role == "Faculty" && module["title"] == "Grades") {
        return false; // Hide "Grades" for Faculty
      }
      if ((widget.role == "Student" || widget.role == "Faculty") && module["title"] == "Mapping") {
        return false; // Hide "Mapping" for Student and Faculty
      }
      return true; // Keep other modules
    }).toList();

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

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.orange, // The color of the header area
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Center the logo image
                  Center(
                    child: Image.asset(
                      'assets/images/CampusConnect largeWhite.png',
                      height: 100, // Adjust height as needed
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Display the user role directly in the header area
                  if (userRole != null)
                    Text(
                      userRole!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // Other drawer items...
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
            ListTile(
              title: const Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserProfile()),
                );
              },
            ),

            // Logout option
            ListTile(
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
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
          itemCount: filteredModules.length, // Updated to use filtered modules
          itemBuilder: (context, index) {
            final module = filteredModules[index];

            return GestureDetector(
              onTap: () {
                if (module["title"] == "Courses") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectCohortScreen(
                        source: 'Courses', // Pass the source as 'Courses'
                      ),
                    ),
                  );
                } else if (module["title"] == "Mapping" && widget.role != "Admin") {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Access Denied: Admins only'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else if (module["title"] == "Mapping" && widget.role == "Admin") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SelectCohortScreen(source: 'Mapping'),
                    ),
                  );
                } else if (module["title"] == "Attendance") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AttendanceOptionScreen(role: widget.role),
                    ),
                  );
                } else {
                  // Placeholder action for other modules
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tapped on ${module["title"]}')),
                  );
                }
              },

              child: Card(
                elevation: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(module["icon"], size: 50, color: Colors.orange),
                    const SizedBox(height: 10),
                    Text(
                      module["title"],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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