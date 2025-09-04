import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:5000"; // backend URL

  static Future<Map<String, dynamic>> verifyFace(File? selfie, File? documentPhoto) async {
    if (selfie == null || documentPhoto == null) {
      throw Exception("Files are null");
    }

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/verify-face"),
    );

    request.files.add(await http.MultipartFile.fromPath("file1", selfie.path));
    request.files.add(await http.MultipartFile.fromPath("file2", documentPhoto.path));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return json.decode(responseData);
    } else {
      throw Exception("Face verification failed: $responseData");
    }
  }
}
