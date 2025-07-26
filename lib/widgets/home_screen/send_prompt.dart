import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

class FileService {
  final Dio _dio = Dio();
  final String _queryUrl =
      'https://refined-able-grouper.ngrok-free.app/query_or_upload';
  final String _saveUrl =
      'https://refined-able-grouper.ngrok-free.app/add_message';

  /// Pick one or more files from the device
  Future<List<PlatformFile>> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    return result?.files ?? [];
  }

  /// Send files and/or prompt to backend
  Future<String> process({
    List<PlatformFile>? files,
    String? prompt,
    String? email,
    String? sessionId,
  }) async {
    final formData = FormData();

    // Add files if provided
    if (files != null && files.isNotEmpty) {
      for (var file in files) {
        formData.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(file.path!, filename: file.name),
          ),
        );
      }
    }

    // Add prompt if provided
    if (prompt != null && prompt.trim().isNotEmpty) {
      formData.fields.add(MapEntry('prompt', prompt));
    }

    try {
      final response = await _dio.post(
        _queryUrl,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final reply = response.data['response'] ?? '✅ Request completed.';
      // final uploadResults = response.data['upload_results'];

      // Save message only if prompt was sent
      if (prompt != null && prompt.trim().isNotEmpty) {
        final savePayload = {
          'email': email ?? 'unknown',
          'prompt': prompt,
          'response': reply,
          if (sessionId != null) 'session_id': sessionId,
        };
        await _dio.post(_saveUrl, data: FormData.fromMap(savePayload));
      }

      return reply;
    } catch (e) {
      return '❌ Failed to process request: $e';
    }
  }
}
