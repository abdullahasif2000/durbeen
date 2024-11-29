
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

  /// Handles user login for different roles
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

        final hashedPassword = hashPassword(password);

        for (var user in users) {
          if (user['Email'] == email && user['Password'] == hashedPassword) {
            print("Login successful for user: ${user['Email']}");
            return user;
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
        throw Exception("Failed to fetch cohorts. Status Code: ${response.statusCode}");
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
          print("Unexpected JSON structure. Expected a List, got: $decodedJson");
          throw Exception("Unexpected response format");
        }
      } else {
        print("Failed to fetch courses. Status code: ${response.statusCode}");
        throw Exception("Failed to fetch courses. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching courses for cohort $cohort: $e");
      throw Exception("Error fetching courses: $e");
    }
  }

  /// Fetches students based on cohort
  Future<List<Map<String, dynamic>>> fetchStudentsByCohort(String cohort) async {
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
          print("Unexpected JSON structure. Expected a List, got: $decodedJson");
          throw Exception("Unexpected response format");
        }
      } else {
        print("Failed to fetch students. Status code: ${response.statusCode}");
        throw Exception("Failed to fetch students. Status Code: ${response.statusCode}");
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
        throw Exception("Failed to fetch sessions. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching sessions: $e");
      throw Exception("Error fetching sessions: $e");
    }
  }
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
        throw Exception("Failed to create section. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error creating section: $e");
    }
  }
}
