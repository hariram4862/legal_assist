import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:legal_assist/widgets/home_screen/prompt_service.dart';
import 'package:legal_assist/widgets/home_screen/file_service.dart';
import 'package:legal_assist/widgets/home_screen/input_bar.dart';
import 'package:legal_assist/widgets/home_screen/message_list.dart';
import 'package:legal_assist/widgets/home_screen/picked_files_dialog.dart';
import 'package:legal_assist/widgets/home_screen/voice_recording.dart';
import 'package:legal_assist/widgets/home_screen/drawer.dart';
import 'package:legal_assist/api_services/wake_word_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _promptController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final List<PlatformFile> _pickedFiles = [];
  String? _currentSessionId;
  bool _isDarkTheme = false;

  final WakeWordService _wakeWordService = WakeWordService();
  final User? user = FirebaseAuth.instance.currentUser;
  final AudioService _audioService = AudioService();

  bool get _isRecording => _audioService.isRecording;

  @override
  void initState() {
    super.initState();
    _initWakeWord();
  }

  @override
  void dispose() {
    _wakeWordService.dispose();
    _audioService.dispose();
    super.dispose();
  }

  Future<String> _copyAssetToFile(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${assetPath.split("/").last}');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  }

  Future<void> _initWakeWord() async {
    const accessKey =
        "XlQqVt2hpmn/tchr14/SjjnLks1T7b6mJ3j2rDJhin01i3PdJ8pPlQ==";
    final keywordPath = await _copyAssetToFile(
      'assets/hey-theta_en_android_v3_0_0.ppn',
    );
    await _wakeWordService.init(
      accessKey: accessKey,
      keywordAssetPath: keywordPath,
      onWakeWordDetected: () {
        if (!_isRecording) _startRecording();
      },
    );
    await _wakeWordService.start();
  }

  Future<void> _startRecording() async {
    await _audioService.startRecording();
    if (!mounted) return;
    setState(() {});
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordingBottomSheet(onStop: _stopRecording),
    );
  }

  Future<void> _stopRecording() async {
    await _audioService.stopRecording(
      onResult: (text) => setState(() => _promptController.text = text),
    );
    setState(() {});
  }

  Future<void> _handleSend() async {
    final prompt = _promptController.text.trim();
    final hasPrompt = prompt.isNotEmpty;
    final hasFiles = _pickedFiles.isNotEmpty;

    if (hasPrompt || hasFiles) {
      if (hasPrompt) {
        setState(() {
          _messages.add({'role': 'user', 'text': prompt});
          _promptController.clear();
          _messages.add({'role': 'bot', 'text': '...typing...'});
        });

        final reply = await PromptService().sendPrompt(
          prompt,
          user?.email,
          _currentSessionId,
        );

        setState(() {
          _messages.removeLast();
          _messages.add({'role': 'bot', 'text': reply});
        });
      }

      if (hasFiles) {
        await FileService().uploadFiles(_pickedFiles);
        setState(() => _pickedFiles.clear());
      }
    }
  }

  void _toggleRecording() {
    _isRecording ? _stopRecording() : _startRecording();
  }

  Future<void> _pickFile() async {
    final files = await FileService().pickFiles();
    setState(() => _pickedFiles.addAll(files));
  }

  void _showPickedFilesDialog() {
    showPickedFilesDialog(context, _pickedFiles, (_) {
      setState(() {}); // Trigger rebuild after dialog removes item
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'Voice Intelligence',

          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        actions: [
          //  Icon(Icons.add_circle_outline_sharp
          // icon: const Icon(Icons.autorenew_rounded),
          IconButton(
            icon: Image.asset(
              'assets/images/new_chat_icon.png',
              height: 25,
              width: 25,
            ),
            onPressed:
                () => setState(() {
                  _currentSessionId = null;
                  _messages.clear();
                  _promptController.clear();
                  _pickedFiles.clear();
                }),
          ),
        ],
      ),
      drawer: CustomDrawer(
        isDarkTheme: _isDarkTheme,
        onThemeToggle: (val) => setState(() => _isDarkTheme = val),
        user: user,
        onSessionSelected:
            (sessionId, messages) => setState(() {
              _currentSessionId = sessionId;
              _messages.clear();
              _messages.addAll(messages);
            }),
      ),
      body: Column(
        children: [
          if (_currentSessionId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.history, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Session ID: $_currentSessionId",
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child:
                _messages.isEmpty && _currentSessionId == null
                    ? const Center(
                      child: Text(
                        'Start a new conversation.\nType or speak your prompt!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    )
                    : MessageList(messages: _messages),
          ),
          InputBar(
            promptController: _promptController,
            pickedFiles: _pickedFiles,
            isRecording: _isRecording,
            onSend: _handleSend,
            onMicTap: _toggleRecording,
            onPickFiles: _pickFile,
            onShowPickedFiles: _showPickedFilesDialog,
          ),
        ],
      ),
    );
  }
}
