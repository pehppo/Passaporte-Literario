import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;


class CloudinaryService {

  static const String cloudName = 'dtottvkil';
  static const String uploadPreset = 'pass-liter';

  static Future<String> uploadImage(File file) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Cloudinary upload failed: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final url = (data['secure_url'] ?? data['url']) as String?;
    if (url == null) throw Exception('Cloudinary did not return a URL');
    return url;
  }
}
