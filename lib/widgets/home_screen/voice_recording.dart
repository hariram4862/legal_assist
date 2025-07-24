import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

typedef OnTranscriptionResult = void Function(String transcribedText);

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (!await hasPermission()) return;

    final dir = await getApplicationDocumentsDirectory();
    final filePath = p.join(dir.path, 'voice.wav');
    await _recorder.start(const RecordConfig(), path: filePath);
    _isRecording = true;
  }

  Future<void> stopRecording({required OnTranscriptionResult onResult}) async {
    final path = await _recorder.stop();
    _isRecording = false;

    if (path != null) {
      final transcription = await _transcribe(path);
      if (transcription != null) {
        onResult(transcription);
      }
    }
  }

  Future<String?> _transcribe(String path) async {
    try {
      final dio = Dio();
      const url = 'https://refined-able-grouper.ngrok-free.app/transcribe';

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: 'voice.wav'),
      });

      final response = await dio.post(url, data: formData);
      if (response.statusCode == 200) {
        return response.data['text'];
      }
    } catch (e) {
      print("Transcription Error: $e");
    }
    return null;
  }

  void dispose() {
    _recorder.dispose();
  }
}

class RecordingBottomSheet extends StatefulWidget {
  final VoidCallback onStop;

  const RecordingBottomSheet({super.key, required this.onStop});

  @override
  State<RecordingBottomSheet> createState() => _RecordingBottomSheetState();
}

class _RecordingBottomSheetState extends State<RecordingBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        widget.onStop();
      },
      child: Container(
        height: 220,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(child: VibratingMic()),
      ),
    );
  }
}

class VibratingMic extends StatefulWidget {
  const VibratingMic({super.key});

  @override
  State<VibratingMic> createState() => _VibratingMicState();
}

class _VibratingMicState extends State<VibratingMic>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnim = Tween(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (_, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.mic, size: 70, color: Colors.white),
              SizedBox(height: 10),
              Text(
                'Listening... Tap to stop.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
