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
    // Map roles to their corresponding API endpoints
    final roleUrls = {
      "Admin": "$baseUrl/usersdataN.php",
      "Student": "$baseUrl/studentsdataN.php",
      "Faculty": "$baseUrl/facultydataN.php",
    };

    // Check for valid role
    if (!roleUrls.containsKey(role)) {
      print("Invalid role provided: $role");
      return null;
    }

    final url = roleUrls[role]!;

    try {
      // Fetch data from the API
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);

        print("API response received successfully for role: $role");

        // Hash the password
        final hashedPassword = hashPassword(password);

        // Search for a matching user
        for (var user in users) {
          print("Checking user: ${user['Email']} with hashed password: $hashedPassword");
          if (user['Email'] == email && user['Password'] == hashedPassword) {
            print("Login successful for user: ${user['Email']}");
            return user; // Return user data
          }
        }

        print("Invalid credentials: No matching user found.");
        return null; // Return null if no match is found
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
        print("Raw API response: $responseBody"); // Debugging

        // Decode the JSON response
        final decodedJson = json.decode(responseBody);
        print("Decoded JSON: $decodedJson"); // Debugging

        // Ensure the response is a List
        if (decodedJson is List) {
          return List<Map<String, dynamic>>.from(decodedJson); // Return as list of maps
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

}
