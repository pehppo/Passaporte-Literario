import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'CLOUDINARY_CLOUD_NAME';
  static const String _uploadPreset = 'CLOUDINARY_UPLOAD_PRESET';

  static Future<String> uploadImage(File file, {String? publicId}) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset;
    
    if (publicId != null && publicId.isNotEmpty) {
      request.fields['public_id'] = publicId;
    }

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Falha no upload: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final url = data['secure_url'] as String?;
    
    if (url == null) {
      throw Exception('Cloudinary não retornou uma URL válida.');
    }

    return url;
  }
}