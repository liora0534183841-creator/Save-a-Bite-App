import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:developer' as dev;

class StorageRepository {
  final String _cloudName = "dnu9tli0x";
  final String _uploadPreset = "save_a_bite_preset";
  // Uploads a file to Cloudinary and returns the secure URL.
  Future<String?> uploadFile(File file, String folderPath, String fileName) async {
    try {
      dev.log("Starting file upload to Cloudinary", name: "StorageRepository");

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
      );

      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folderPath;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        String url = responseData['secure_url'];
        dev.log("File uploaded successfully to Cloudinary: $url", name: "StorageRepository");
        return url;
      } else {
        dev.log("Cloudinary server error response: ${response.body}", name: "StorageRepository");
        return null;
      }
    } catch (e, stack) {
      dev.log("File upload failed", name: "StorageRepository", error: e, stackTrace: stack);
      rethrow; 
    }
  }
}