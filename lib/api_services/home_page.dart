// import 'dart:io';
// import 'package:dio/dio.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class ApiService {
//   final Dio _dio = Dio();

//   final String _transcribeUrl =
//       'https://refined-able-grouper.ngrok-free.app/transcribe';
//   final String _respondUrl =
//       'https://refined-able-grouper.ngrok-free.app/respond';
//   final String _addMessageUrl =
//       'https://refined-able-grouper.ngrok-free.app/add_message';

//   Future<String> transcribeAudio(File audioFile) async {
//     final formData = FormData.fromMap({
//       'file': await MultipartFile.fromFile(
//         audioFile.path,
//         filename: 'voice.wav',
//       ),
//     });

//     final response = await _dio.post(_transcribeUrl, data: formData);
//     return response.data['text'];
//   }

//   Future<Map<String, dynamic>> sendPrompt(
//     String prompt,
//     String? sessionId,
//   ) async {
//     final user = FirebaseAuth.instance.currentUser;
//     final response = await _dio.post(
//       _respondUrl,
//       data: FormData.fromMap({'prompt': prompt}),
//     );

//     final reply = response.data['response'] ?? 'No response';

//     final addResp = await _dio.post(
//       _addMessageUrl,
//       data: FormData.fromMap({
//         'email': user?.email ?? 'unknown',
//         'prompt': prompt,
//         'response': reply,
//         if (sessionId != null) 'session_id': sessionId,
//       }),
//     );

//     return {'reply': reply, 'session_id': addResp.data['session_id']};
//   }
// }
