// lib/api_services/file_service.dart
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

class FileService {
  final Dio _dio = Dio();

  // Base
  static const String _base =
      'https://voice-intelligence-app.azurewebsites.net';

  // New split routes
  static const String _promptOnly = '$_base/v1/prompt-only';
  static const String _filesOnly = '$_base/v1/files-only';
  static const String _filesPlusPrompt = '$_base/v1/files-plus-prompt';

  /// Pick files
  Future<List<PlatformFile>> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    return result?.files ?? [];
  }

  /// Returns: { reply: String, sessionId: String? }
  Future<Map<String, String?>> process({
    List<PlatformFile>? files,
    String? prompt,
    String? email,
    String? sessionId,
  }) async {
    final hasPrompt = (prompt != null && prompt.trim().isNotEmpty);
    final hasFiles = (files != null && files.isNotEmpty);

    if (!hasPrompt && !hasFiles) {
      return {"reply": "No prompt or files provided.", "sessionId": sessionId};
    }

    final formData = FormData();

    if (email != null) formData.fields.add(MapEntry('email', email));
    if (sessionId != null)
      formData.fields.add(MapEntry('session_id', sessionId));

    String url;

    if (hasPrompt && hasFiles) {
      url = _filesPlusPrompt;
      formData.fields.add(MapEntry('prompt', prompt));
      for (final f in files) {
        formData.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(f.path!, filename: f.name),
          ),
        );
      }
    } else if (hasFiles) {
      url = _filesOnly;
      for (final f in files) {
        formData.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(f.path!, filename: f.name),
          ),
        );
      }
    } else {
      url = _promptOnly;
      formData.fields.add(MapEntry('prompt', prompt!));
    }

    try {
      final resp = await _dio.post(url, data: formData, options: Options());
      final data = resp.data;

      final reply =
          (data is Map && data['response'] != null)
              ? (data['response'] as String)
              : (data?.toString() ?? 'No response');

      final newSessionId =
          (data is Map && data['session_id'] != null)
              ? data['session_id'] as String
              : (sessionId ??
                  (data is Map && data['sessionId'] != null
                      ? data['sessionId'] as String
                      : null));

      return {"reply": reply, "sessionId": newSessionId};
    } catch (e) {
      return {
        "reply": '❌ Failed to process request: $e',
        "sessionId": sessionId,
      };
    }
  }
}
