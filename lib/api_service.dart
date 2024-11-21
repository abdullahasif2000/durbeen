import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart'; // Import the crypto package

class ApiService {
  static const String baseUrl = "https://results.gece.edu.pk/geceapi";

  // Function to hash the password using MD5
  String hashPassword(String password) {
    var bytes = utf8.encode(password); // Convert the password to bytes
    var hash = md5.convert(bytes); // Generate the MD5 hash
    return hash.toString(); // Return the hashed password as a string
  }

  // Login method
  Future<Map<String, dynamic>?> login(String email, String password, String role) async {
    String url;
    switch (role) {
      case "Admin":
        url = "$baseUrl/usersdataN.php";
        break;
      case "Student":
        url = "$baseUrl/studentsdataN.php";
        break;
      case "Faculty":
        url = "$baseUrl/facultydataN.php";
        break;
      default:
        return null; // Invalid role
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);

        // Debugging: Print the response data to check what is being returned
        print("API response: $response");

        // Hash the password before comparing
        String hashedPassword = hashPassword(password);

        // Check if the email and hashed password match any user
        for (var user in users) {
          print("Checking user: ${user['Email']} with hashed password: $hashedPassword");
          if (user['Email'] == email && user['Password'] == hashedPassword) {
            return user; // Return user data if credentials match
          }
        }

        // If no match found
        return null; // Invalid credentials
      } else {
        throw Exception("Failed to fetch data. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}
