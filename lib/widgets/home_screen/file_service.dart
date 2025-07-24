import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

class FileService {
  Future<List<PlatformFile>> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    return result?.files ?? [];
  }

  Future<void> uploadFiles(List<PlatformFile> files) async {
    final dio = Dio();
    final url = 'https://refined-able-grouper.ngrok-free.app/upload_files';

    final formData = FormData();

    for (var file in files) {
      formData.files.add(
        MapEntry(
          'files',
          await MultipartFile.fromFile(file.path!, filename: file.name),
        ),
      );
    }

    try {
      final response = await dio.post(
        url,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      print('✅ Upload success: ${response.data}');
    } catch (e) {
      print('❌ Upload failed: $e');
    }
  }
}
