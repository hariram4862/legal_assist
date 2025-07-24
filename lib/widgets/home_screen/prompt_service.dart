import 'package:dio/dio.dart';

class PromptService {
  final Dio _dio = Dio();

  Future<String> sendPrompt(
    String prompt,
    String? email,
    String? sessionId,
  ) async {
    const url = 'https://refined-able-grouper.ngrok-free.app/respond';
    const addMessageUrl =
        'https://refined-able-grouper.ngrok-free.app/add_message';

    try {
      final response = await _dio.post(
        url,
        data: FormData.fromMap({'prompt': prompt}),
      );
      final reply = response.data['response'] ?? 'No response';

      final payload = {
        'email': email ?? 'unknown',
        'prompt': prompt,
        'response': reply,
        if (sessionId != null) 'session_id': sessionId,
      };

      final sessionResp = await _dio.post(
        addMessageUrl,
        data: FormData.fromMap(payload),
      );

      if (sessionResp.data['session_id'] != null) {
        return reply; // optionally store session ID externally
      }

      return reply;
    } catch (e) {
      return '⚠️ Error: $e';
    }
  }
}
