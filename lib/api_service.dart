import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class ApiService {
  static const String baseUrl = "https://results.gece.edu.pk/geceapi";

  /// Hashes a password using MD5
  String hashPassword(String password) {
    final bytes = utf8.encode(password); // Convert password to bytes
    final hash = md5.convert(bytes); // Generate MD5 hash
    return hash.toString(); // Return hashed password
  }
/// role based login
  Future<Map<String, dynamic>?> login(String email, String password, String role) async {
    final roleUrls = {
      "Admin": "$baseUrl/usersdataN.php",
      "Student": "$baseUrl/studentsdataN.php",
      "Faculty": "$baseUrl/facultydataN.php",
    };

    if (!roleUrls.containsKey(role)) {
      print("Invalid role provided: $role");
      return null;
    }

    final url = roleUrls[role]!;

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);
        print("API response received successfully for role: $role");

        final hashedPassword = hashPassword(password); // Ensure you have this method

        for (var user in users) {
          if (user['Email'] == email && user['Password'] == hashedPassword) {
            print("Login successful for user: ${user['Email']}");
            return user; // Return user data including role
          }
        }

        print("Invalid credentials: No matching user found.");
        return null;
      } else {
        print("Failed to fetch data. Status code: ${response.statusCode}");
        throw Exception("Failed to fetch data. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error during login: $e");
      throw Exception("Error during login: $e");
    }
  }


  /// Fetches available cohorts from the API
  Future<List<dynamic>> fetchCohorts() async {
    final url = "$baseUrl/fetch_cohortsN.php";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final cohorts = json.decode(response.body);
        if (cohorts is List) {
          print("Cohorts fetched successfully: $cohorts");
          return cohorts;
        } else {
          print("Unexpected response format: $cohorts");
          throw Exception("Unexpected response format");
        }
      } else {
        print("Failed to fetch cohorts. Status code: ${response.statusCode}");
        throw Exception(
            "Failed to fetch cohorts. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching cohorts: $e");
      throw Exception("Error fetching cohorts: $e");
    }
  }

  /// Fetches courses based on cohort
  Future<List<Map<String, dynamic>>> fetchCourses(String cohort) async {
    final url = "$baseUrl/fetch_offered_coursesN.php?cohort=$cohort";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print("Raw API response: $responseBody");

        final decodedJson = json.decode(responseBody);
        print("Decoded JSON: $decodedJson");

        if (decodedJson is List) {
          return List<Map<String, dynamic>>.from(decodedJson);
        } else {
          print(
              "Unexpected JSON structure. Expected a List, got: $decodedJson");
          throw Exception("Unexpected response format");
        }
      } else {
        print("Failed to fetch courses. Status code: ${response.statusCode}");
        throw Exception(
            "Failed to fetch courses. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching courses for cohort $cohort: $e");
      throw Exception("Error fetching courses: $e");
    }
  }

  /// Fetches students based on cohort
  Future<List<Map<String, dynamic>>> fetchStudentsByCohort(
      String cohort) async {
    final url = "$baseUrl/fetch_students_by_cohortN.php?cohort=$cohort";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print("Raw API response for students: $responseBody");

        final decodedJson = json.decode(responseBody);
        print("Decoded JSON for students: $decodedJson");

        if (decodedJson is List) {
          return List<Map<String, dynamic>>.from(decodedJson);
        } else {
          print(
              "Unexpected JSON structure. Expected a List, got: $decodedJson");
          throw Exception("Unexpected response format");
        }
      } else {
        print("Failed to fetch students. Status code: ${response.statusCode}");
        throw Exception(
            "Failed to fetch students. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching students for cohort $cohort: $e");
      throw Exception("Error fetching students: $e");
    }
  }

  /// Fetches available academic sessions from the API
  Future<List<Map<String, dynamic>>> fetchSessions() async {
    final url = "$baseUrl/Academic_Sessions.php";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print("Fetched sessions successfully");

        // Convert to a list of maps with the required keys
        return List<Map<String, dynamic>>.from(data.map((session) {
          return {
            'SessionID': session['SessionID'],
            'Description': session['Description'],
            'Current': session['Current'],
          };
        }));
      } else {
        print("Failed to fetch sessions. Status code: ${response.statusCode}");
        throw Exception(
            "Failed to fetch sessions. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching sessions: $e");
      throw Exception("Error fetching sessions: $e");
    }
  }

  /// Creates a new section
  Future<Map<String, dynamic>> createNewSection({
    required String courseID,
    required String sectionName,
    required String sessionID,
  }) async {
    final url = "$baseUrl/create_new_sectionN.php";
    final params = {
      'CourseID': courseID,
      'SectionName': sectionName,
      'SessionID': sessionID,
    };

    final uri = Uri.parse(url).replace(queryParameters: params);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
            "Failed to create section. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error creating section: $e");
    }
  }

  // Fetch sections based on CourseID and SessionID
  Future<List<Map<String, dynamic>>> fetchSections({
    required String courseID,
    required String sessionID,
  }) async {
    final url =
        'https://results.gece.edu.pk/geceapi/fetch_sectionsN.php?CourseID=$courseID&SessionID=$sessionID';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load sections: ${response.body}");
    }
  }


  /// Deletes a section based on SectionID
  Future<Map<String, dynamic>> deleteSection(String sectionID) async {
    final url = "$baseUrl/delete_this_sectionN.php";
    final params = {
      'SectionID': sectionID,
    };

    final uri = Uri.parse(url).replace(queryParameters: params);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
            "Failed to delete section. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error deleting section: $e");
    }
  }

  /// Adds a student to a section
  Future<bool> addStudentToSection({
    required String sessionID,
    required String courseID,
    required String sectionID,
    required String rollNumber,
  }) async {
    final url = "$baseUrl/add_students_to_sectionN.php";
    final params = {
      'SessionID': sessionID,
      'CourseID': courseID,
      'SectionID': sectionID,
      'rollNumber': rollNumber,
    };

    final uri = Uri.parse(url).replace(queryParameters: params);
    print("Sending API request to $url with params: $params");

    try {
      final response = await http.get(uri);
      print("API Response: ${response.body}");

      if (response.statusCode == 200) {
        // API response is a single integer as string ("1" for success)
        return response.body.trim() == "1";
      } else {
        throw Exception(
            "Failed to add student to section. Status Code: ${response
                .statusCode}");
      }
    } catch (e) {
      print("Error adding student to section: $e");
      throw Exception("Error adding student to section: $e");
    }
  }
  /// fetch mapped student details
  Future<List<Map<String, dynamic>>> fetchMappedStudents({
    required String SessionID,
    required String CourseID,
    required String SectionID,
  }) async {
    final body = {
      'SessionID': SessionID,
      'CourseID': CourseID,
      'SectionID': SectionID,
    };

    print('Sending request to: $baseUrl/fetch_section_studentsN.php');
    print('Request body: $body');

    try {
      final response = await http.get(
        Uri.parse(
          'https://results.gece.edu.pk/geceapi/fetch_section_studentsN.php'
              '?SessionID=$SessionID&CourseID=$CourseID&SectionID=$SectionID',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      print('Status Code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((student) => student as Map<String, dynamic>).toList();
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to fetch mapped students');
      }
    } catch (e) {
      print('Exception caught: $e');
      throw Exception('An error occurred while fetching mapped students');
    }
  }
// Remove student from section API
  Future<bool> removeStudentFromSection({
    required String rollNumber,
    required String sessionID,
    required String courseID,
  }) async {
    // Append query parameters directly to the URL
    final url = Uri.parse('$baseUrl/remove_students_from_sectionN.php?RollNumber=$rollNumber&SessionID=$sessionID&CourseID=$courseID');

    print('API Request to: $url');

    try {
      final response = await http.get(url);  // Use GET instead of POST

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check for 'status' key in response
        if (data['status'] == 'success') {
          return true;
        } else {
          print('API error: ${data['status']}');
          return false;
        }
      } else {
        print('Error: Status code ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error in removeStudentFromSection API: $e');
      return false;
    }
  }
  // Method to mark attendance
  Future<bool> markAttendance({
    required String rollNumber,
    required String courseID,
    required String sessionID,
    required String sectionID,
    required String date,
    required String attendanceStatus,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/mark_new_attendanceN.php');

      print('Marking attendance with the following parameters:');
      print('RollNumber: $rollNumber, CourseID: $courseID, SessionID: $sessionID, '
          'SectionID: $sectionID, Date: $date, AttendanceStatus: $attendanceStatus');

      final response = await http.get(
        url.replace(queryParameters: {
          'RollNumber': rollNumber,
          'CourseID': courseID,
          'SessionID': sessionID,
          'SectionID': sectionID,
          'Date': date,
          'AttendanceStatus': attendanceStatus,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          print('Attendance successfully marked for $rollNumber');
          return true;
        } else {
          print('Failed to mark attendance: ${result['message']}');
          throw Exception('Failed to mark attendance: ${result['message']}');
        }
      } else {
        throw Exception('Failed to connect to API');
      }
    } catch (e) {
      print('Error marking attendance: $e');
      throw Exception('Error marking attendance: $e');
    }
  }
// Method to check if attendance is already marked
  Future<bool> checkAttendanceMarked({
    required String sessionID,
    required String courseID,
    required String sectionID,
    required String date,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/fetch_attendance_admin.php');

      print('Checking attendance with the following parameters:');
      print('SessionID: $sessionID, CourseID: $courseID, SectionID: $sectionID, Date: $date');

      final response = await http.get(
        url.replace(queryParameters: {
          'SessionID': sessionID,
          'CourseID': courseID,
          'SectionID': sectionID,
          'Date': date,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // If the response is "NA", no attendance is marked
        if (response.body == '"NA"') {
          print('No attendance records found for the date: $date');
          return false; // No attendance marked
        }

        // Decode the response body properly
        final decodedResponse = jsonDecode(response.body);

        // Check if the decoded response is a list
        if (decodedResponse is List) {
          if (decodedResponse.isEmpty) {
            print('No attendance records found for the date: $date');
            return false; // No attendance marked
          } else {
            print('Attendance already marked for the date: $date');
            return true; // Attendance has been marked
          }
        } else {
          // If the decoded response is not a list, throw an error
          throw Exception('Invalid response format, expected a list');
        }
      } else {
        throw Exception('Failed to connect to API');
      }
    } catch (e) {
      print('Error checking attendance: $e');
      throw Exception('Error checking attendance: $e');
    }
  }
  /// fetch admin Attendance
  Future<List<Map<String, dynamic>>> fetchAttendanceRecords({
    required String sessionID,
    required String courseID,
    required String sectionID,
    required String date,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/fetch_attendance_admin.php');

      print('Checking attendance with the following parameters:');
      print('SessionID: $sessionID, CourseID: $courseID, SectionID: $sectionID, Date: $date');

      final response = await http.get(
        url.replace(queryParameters: {
          'SessionID': sessionID,
          'CourseID': courseID,
          'SectionID': sectionID,
          'Date': date,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body == '"NA"') {
          print('No attendance records found for the date: $date');
          return []; // Return an empty list
        }

        final decodedResponse = jsonDecode(response.body);

        if (decodedResponse is List) {
          return List<Map<String, dynamic>>.from(decodedResponse);
        } else {
          throw Exception('Invalid response format, expected a list');
        }
      } else {
        throw Exception('Failed to connect to API');
      }
    } catch (e) {
      print('Error fetching attendance: $e');
      throw Exception('Error fetching attendance: $e');
    }
  }
  /// Update Attendance Records
  Future<void> updateAttendanceStatus({
    required String sessionID,
    required String courseID,
    required String sectionID,
    required String date,
    required String rollNumber,
    required String attendanceStatus,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/update_attendanceN.php').replace(queryParameters: {
      'SessionID': sessionID,
      'CourseID': courseID,
      'SectionID': sectionID,
      'Date': date,
      'RollNumber': rollNumber,
      'AttendanceStatus': attendanceStatus,
    });

    try {
      final response = await http.get(uri);
      print('DEBUG: API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: Parsed Response: $data');

        if (data['status'] == 'success') {
          print('DEBUG: Attendance updated successfully.');
        } else {
          throw Exception('Failed to update attendance: ${data['status']}');
        }
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('ERROR: $e');
      throw Exception('Failed to update attendance: $e');
    }
  }
}
