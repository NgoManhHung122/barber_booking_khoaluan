import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:barber_booking_app/services/constants.dart';

class CloudinaryService {
  static Future<String?> uploadImage(File image) async {
    final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/${Constants.cloudName}/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = Constants.uploadPreset
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        image.path,
        filename: basename(image.path),
      ));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      return responseData;
    }
    return null;
  }
}