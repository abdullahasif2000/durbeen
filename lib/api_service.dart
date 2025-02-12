import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class ApiService {
  static const String baseUrl = "https://campusconnect.gece.edu.pk/ede00ce79675ee6a84b33a26243d45a0";
  final String apiKey = "z8p3JuLm6V7c9vwXG9K8TrVt5KqXxA5RfjNVu2WnNAs";

  // Combine email, role, and secret key to make hashed key
  String _generateApiKey(String email, String role) {
    String combined = "$email|$role|$apiKey";
    String generatedApiKey = sha256.convert(utf8.encode(combined)).toString();

    // Print the generated API key for debugging
    print("Generated API Key: $generatedApiKey");

    return generatedApiKey;
  }

  /// Hashes a password using MD5
  String hashPassword(String password) {
    final bytes = utf8.encode(password); // Convert password to bytes
    final hash = md5.convert(bytes); // Generate MD5 hash
    return hash.toString(); // Return hashed password
  }

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
      String apiKey = _generateApiKey(email, role);

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': apiKey, // API key header
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);
        print("API response received successfully for role: $role");

        final hashedPassword = hashPassword(password);

        for (var user in users) {
          // Check if user['Email'] is not null before processing
          if (user['Email'] != null) {
            // Convert both emails to lowercase for comparison
            if (user['Email'].toLowerCase() == email.toLowerCase() && user['Password'] == hashedPassword) {
              print("Login successful for user: ${user['Email']}");
              return user; // Return user data including role
            }
          } else {
            print("User  email is null, skipping user: $user");
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

  /// Fetches courses based on cohort and SessionID
  Future<List<Map<String, dynamic>>> fetchCourses(String cohort,
      String sessionId) async {
    final url = "$baseUrl/fetch_offered_coursesN.php?cohort=$cohort&SessionID=$sessionId";

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
      print(
          "Error fetching courses for cohort $cohort with SessionID $sessionId: $e");
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

  /// Fetch sections based on CourseID and SessionID
  Future<List<Map<String, dynamic>>> fetchSections({
    required String courseID,
    required String sessionID,
  }) async {
    final url =
        '$baseUrl/fetch_sectionsN.php?CourseID=$courseID&SessionID=$sessionID';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load sections: ${response.body}");
    }
  }

  /// fetch sections based on student
  Future<List<Map<String, dynamic>>> fetchStudentSections({
    required String sessionID,
    required String courseID,
    required String rollNumber,
  }) async {
    final url =
        '$baseUrl/fetch_student_sections.php?SessionID=$sessionID&CourseID=$courseID&RollNumber=$rollNumber';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Parse the response and return as a list of maps
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception("Failed to load student sections: ${response.body}");
      }
    } catch (e) {
      print('Error fetching student sections: $e');
      throw e;
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
          '$baseUrl/fetch_section_studentsN.php'
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

  /// Remove student from section API
  Future<bool> removeStudentFromSection({
    required String rollNumber,
    required String sessionID,
    required String courseID,
  }) async {
    // Append query parameters directly to the URL
    final url = Uri.parse(
        '$baseUrl/remove_students_from_sectionN.php?RollNumber=$rollNumber&SessionID=$sessionID&CourseID=$courseID');

    print('API Request to: $url');

    try {
      final response = await http.get(url);

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

  /// Method to mark attendance
  Future<bool> markAttendance({
    required String rollNumber,
    required String courseID,
    required String sessionID,
    required String sectionID,
    required String date,
    required String attendanceStatus,
    required String userID, // New parameter
    required String type,    // New parameter
  }) async {
    try {
      final url = Uri.parse('$baseUrl/Mark_New_Attendance.php'); // Updated endpoint

      print('Marking attendance with the following parameters:');
      print(
          'RollNumber: $rollNumber, CourseID: $courseID, SessionID: $sessionID, '
              'SectionID: $sectionID, Date: $date, AttendanceStatus: $attendanceStatus, '
              'User ID: $userID, Type: $type'); // Include new parameters in the log

      final response = await http.get(
        url.replace(queryParameters: {
          'RollNumber': rollNumber,
          'CourseID': courseID,
          'SessionID': sessionID,
          'SectionID': sectionID,
          'Date': date,
          'AttendanceStatus': attendanceStatus,
          'UserID': userID, // Add new parameter
          'Type': type,     // Add new parameter
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

  /// Method to check if attendance is already marked
  Future<bool> checkAttendanceMarked({
    required String sessionID,
    required String courseID,
    required String sectionID,
    required String date,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/fetch_attendance_admin.php');

      print('Checking attendance with the following parameters:');
      print(
          'SessionID: $sessionID, CourseID: $courseID, SectionID: $sectionID, Date: $date');

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
      print(
          'SessionID: $sessionID, CourseID: $courseID, SectionID: $sectionID, Date: $date');

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
    required String userID,
    required String type,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/UpdateAttendance.php').replace(
        queryParameters: {
          'SessionID': sessionID,
          'CourseID': courseID,
          'SectionID': sectionID,
          'Date': date,
          'RollNumber': rollNumber,
          'AttendanceStatus': attendanceStatus,
          'User  ID': userID,
          'Type': type,
        });

    print('DEBUG: Sending request to: $uri');

    try {
      final response = await http.get(uri);
      print('DEBUG: API Response Status Code: ${response.statusCode}');
      print('DEBUG: API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final int result = int.parse(response.body);
        print('DEBUG: Parsed Response: $result');

        if (result == 1) {
          print('DEBUG: Attendance updated successfully.');
        } else if (result == 0) {
          throw Exception('Failed to update attendance: Error occurred.');
        } else {
          throw Exception('Unexpected response value.');
        }
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('ERROR: $e');
      throw Exception('Failed to update attendance: $e');
    }
  }

  /// Fetch all attendance of a student
  Future<List<Map<String, dynamic>>> fetchAttendance(String sessionID,
      String rollNumber, String courseID) async {
    final url =
        '$baseUrl/fetch_attendanceN.php?RollNumber=$rollNumber&SessionID=$sessionID&CourseID=$courseID';
    print('Fetching attendance from: $url');

    try {
      final response = await http.get(Uri.parse(url));
      print('Attendance API Response: ${response.body}');

      if (response.statusCode == 200) {
        // Check if the response body is a valid JSON array
        final List<dynamic> data = jsonDecode(response.body);

        // Ensure that each item is a Map<String, dynamic>
        return data.map((item) {
          if (item is Map<String, dynamic>) {
            return item;
          } else {
            throw Exception('Invalid item type: ${item.runtimeType}');
          }
        }).toList();
      } else {
        throw Exception(
            'Failed to load attendance data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching attendance: $e');
      throw Exception('Error during API call: $e');
    }
  }

  ///fetch attendance dates
  Future<List<String>> fetchAttendanceDates(String sessionID,
      String courseID) async {
    final url = '$baseUrl/fetch_attendance_dates.php?SessionID=$sessionID&CourseID=$courseID';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Extract dates from the response
        return data.map((item) => item['Date'] as String).toList();
      } else {
        throw Exception('Failed to load attendance dates');
      }
    } catch (e) {
      print('Error fetching attendance dates: $e');
      throw e; // Rethrow the error for handling in the UI
    }
  }

  /// Fetch attendance details
  Future<List<Map<String, dynamic>>> fetchAttendanceDetails(String sessionID,
      String courseID, String date, String sectionID) async {
    // Add SectionID as a query parameter in the URL
    final url =
        '$baseUrl/fetch_attendance_details.php?SessionID=$sessionID&CourseID=$courseID&Date=$date&SectionID=$sectionID';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) =>
        {
          "id": item['id'],
          "StudentMapID": item['StudentMapID'],
          "Date": item['Date'],
          "AttendanceStatus": item['AttendanceStatus'],
          "WarningsSent": item['WarningsSent'],
          "EntryDate": item['EntryDate'],
          "RollNumber": item['RollNumber'],
          "SessionID": item['SessionID'],
          "CourseID": item['CourseID'],
          "Semester": item['Semester'],
          "StudentType": item['StudentType'],
          "SectionID": item['SectionID'],
          "Name": item['Name'],
        }).toList();
      } else {
        throw Exception('Failed to load attendance details');
      }
    } catch (e) {
      print('Error fetching attendance details: $e');
      throw e; // Rethrow the error for handling in the UI
    }
  }

  /// fetch courses based on student
  Future<List<Map<String, dynamic>>> fetchStudentCourses(String sessionID,
      String rollNumber) async {
    final url = '$baseUrl/fetchcoursesstudentN.php?RollNumber=$rollNumber&SessionID=$sessionID';
    print('API Call Initiated: $url'); // Log the API endpoint being called

    try {
      final response = await http.get(Uri.parse(url));
      print('API Response Status Code: ${response
          .statusCode}'); // Log the status code

      if (response.statusCode == 200) {
        print('API Response Body: ${response.body}'); // Log the response body
        final List data = jsonDecode(response.body);
        return data.map((course) => course as Map<String, dynamic>).toList();
      } else {
        print('API Call Failed: Status Code ${response
            .statusCode}, Response: ${response.body}');
        throw Exception('Failed to load student courses');
      }
    } catch (e) {
      print('API Call Error: $e'); // Log any errors
      throw Exception('Error during API call: $e');
    }
  }

  ///fetch courses based on faculty
  Future<List<Map<String, dynamic>>> fetchFacultyCourses(String facultyID,
      String sessionID) async {
    final url = '$baseUrl/fetch_faculty_coursesN.php?FacultyID=$facultyID&SessionID=$sessionID';
    print('API Call Initiated: $url'); // Log the API endpoint being called

    try {
      final response = await http.get(Uri.parse(url));
      print('API Response Status Code: ${response
          .statusCode}'); // Log the status code

      if (response.statusCode == 200) {
        print('API Response Body: ${response.body}'); // Log the response body
        final List data = jsonDecode(response.body);
        return data.map((course) => course as Map<String, dynamic>).toList();
      } else {
        print('API Call Failed: Status Code ${response
            .statusCode}, Response: ${response.body}');
        throw Exception('Failed to load faculty courses');
      }
    } catch (e) {
      print('API Call Error: $e'); // Log any errors
      throw Exception('Error during API call: $e');
    }
  }


  /// fetch student profile data
  Future<List<Map<String, dynamic>>> fetchStudentData() async {
    try {
      final url = '$baseUrl/studentsdataN.php';
      print('Fetching data from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
        },
      );

      // Debug the response
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);

        // Ensure data is a list of maps
        return jsonData.map((student) => student as Map<String, dynamic>)
            .toList();
      } else {
        throw Exception(
            'Failed to load student data: ${response.statusCode} - ${response
                .reasonPhrase}');
      }
    } catch (e) {
      print('ERROR: $e');
      throw Exception('Error fetching student data: $e');
    }
  }

  /// Fetch Faculty profile Data
  Future<List<Map<String, dynamic>>> fetchFacultyData() async {
    try {
      final url = '$baseUrl/facultydataN.php';
      print('Fetching data from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
        },
      );

      // Debug the response
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);

        // Ensure data is a list of maps
        return jsonData.map((faculty) => faculty as Map<String, dynamic>)
            .toList();
      } else {
        throw Exception(
            'Failed to load faculty data: ${response.statusCode} - ${response
                .reasonPhrase}');
      }
    } catch (e) {
      print('ERROR: $e');
      throw Exception('Error fetching faculty data: $e');
    }
  }

  /// fetch admin profile data
  Future<List<Map<String, dynamic>>> fetchAdminData() async {
    try {
      final url = '$baseUrl/usersdataN.php';
      print('Fetching admin data from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
        },
      );

      // Debugging the response
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);


        return jsonData.map((admin) => admin as Map<String, dynamic>).toList();
      } else {
        throw Exception(
            'Failed to load admin data: ${response.statusCode} - ${response
                .reasonPhrase}');
      }
    } catch (e) {
      print('ERROR: $e');
      throw Exception('Error fetching admin data: $e');
    }
  }

  /// change password
  Future<Map<String, dynamic>> changePassword({
    required String email,
    required String newPassword, // Remove oldPassword parameter
    required String type,
  }) async {
    // Construct the URL with query parameters
    final url = Uri.parse('$baseUrl/ForgotPassword.php?Email=$email&Password=$newPassword&Type=$type');

    try {
      print("Sending request to: $url");

      final response = await http.get(url);

      print("Response received: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        print("Response data: $responseBody");

        // Convert the response body to an integer
        int responseCode = int.tryParse(responseBody) ?? -1; // Default to -1 if parsing fails
        print("Parsed response code: $responseCode");

        if (responseCode == 1) {
          // Success case
          print("Password change successful for email: $email");
          return {
            "success": true,
            "message": "Password changed successfully",
          };
        } else if (responseCode == 0) {
          // Failure case
          print("Password change failed for email: $email. Response code: $responseCode");
          return {
            "success": false,
            "message": "Failed to change password. Please try again.",
          };
        } else {
          // Handle unexpected response
          print("Unexpected response code: $responseCode for email: $email");
          return {
            "success": false,
            "message": "Unexpected response from the server.",
          };
        }
      } else {
        print("Failed with status code: ${response.statusCode}. Response body: ${response.body}");
        return {
          "success": false,
          "message": "Failed to change password. Please try again."
        };
      }
    } catch (e) {
      print("Error occurred while changing password for email: $email. Error: $e");
      return {
        "success": false,
        "message": "An error occurred. Please check your internet connection."
      };
    }
  }
/// old password verification
  Future<Map<String, dynamic>> verifyOldPassword({
    required String email,
    required String oldPassword,
    required String role,
  }) async {
    String url;

    // Determine the URL based on the user role
    if (role.toLowerCase() == 'admin') {
      url = '${baseUrl}/usersdataN.php';
    } else if (role.toLowerCase() == 'student') {
      url = '${baseUrl}/studentsdataN.php';
    } else if (role.toLowerCase() == 'faculty') {
      url = '${baseUrl}/facultydataN.php';
    } else {
      return {'success': false, 'message': 'Invalid user role'};
    }

    print("Fetching user data from URL: $url");

    // Make the API call to fetch user data
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      print("Response received: ${response.body}");
      // Parse the response
      final List<dynamic> data = json.decode(response.body);

      // Search for the user by email
      final userData = data.firstWhere(
            (user) => user['Email'] == email,
        orElse: () => null,
      );

      if (userData != null) {
        final storedPasswordHash = userData['Password'];

        // Hash the old password input by the user
        final oldPasswordHash = md5.convert(utf8.encode(oldPassword)).toString();

        print("Old password hash: $oldPasswordHash");
        print("Stored password hash: $storedPasswordHash");

        // Compare the hashed old password with the stored password hash
        if (oldPasswordHash == storedPasswordHash) {
          print("Old password verified successfully.");
          return {'success': true, 'message': 'Old password verified successfully'};
        } else {
          print("Old password verification failed.");
          return {'success': false, 'message': 'Old password is incorrect'};
        }
      } else {
        print("User  not found for email: $email");
        return {'success': false, 'message': 'User  not found'};
      }
    } else {
      print("Failed to verify old password. Status code: ${response.statusCode}");
      return {'success': false, 'message': 'Failed to verify old password'};
    }
  }

  /// Email sending API
  Future<Map<String, dynamic>> sendEmail({
    required String email,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/EmailSender.php?Email=$email&Password=$newPassword');

    try {
      print("Sending email request to: $url");
      final response = await http.get(url);
      print("Email response received: ${response.statusCode}");

      if (response.statusCode == 200) {
        print("Email sent successfully to: $email");
        return {"success": true, "message": "An email with the new password has been sent."};
      } else {
        print("Failed to send email. Status code: ${response.statusCode}. Response body: ${response.body}");
        return {"success": false, "message": "Failed to send email. Please try again."};
      }
    } catch (e) {
      print("Error occurred while sending email to: $email. Error: $e");
      return {"success": false, "message": "An error occurred while sending the email."};
    }
  }
}