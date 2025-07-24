import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';

typedef WakeWordDetectedCallback = void Function();

class WakeWordService {
  final FlutterTts _tts = FlutterTts();
  PorcupineManager? _porcupineManager;

  Future<void> init({
    required String accessKey,
    required String keywordAssetPath,
    required WakeWordDetectedCallback onWakeWordDetected,
  }) async {
    // Request mic permission
    if (!await Permission.microphone.isGranted) {
      await Permission.microphone.request();
    }

    _porcupineManager = await PorcupineManager.fromKeywordPaths(
      accessKey,
      [keywordAssetPath],
      (int _) async {
        await _tts.setLanguage("en-IN");
        await _tts.setSpeechRate(0.45);
        await _tts.setVolume(1.0);

        await _tts.speak("Hi Vishal, start speaking...");

        _tts.setCompletionHandler(() {
          onWakeWordDetected();
        });
      },
    );
  }

  Future<void> start() async {
    await _porcupineManager?.start();
  }

  Future<void> stop() async {
    await _porcupineManager?.stop();
  }

  Future<void> dispose() async {
    await _porcupineManager?.delete();
  }
}
