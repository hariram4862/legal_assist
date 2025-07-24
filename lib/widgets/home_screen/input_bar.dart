import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';

class InputBar extends StatefulWidget {
  final TextEditingController promptController;
  final List<PlatformFile> pickedFiles;
  final bool isRecording;
  final VoidCallback onMicTap;
  final VoidCallback onPickFiles;
  final VoidCallback onSend;
  final VoidCallback onShowPickedFiles;

  const InputBar({
    super.key,
    required this.promptController,
    required this.pickedFiles,
    required this.isRecording,
    required this.onMicTap,
    required this.onPickFiles,
    required this.onSend,
    required this.onShowPickedFiles,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 100, // fixed height for up to 4 lines
              ),
              child: Scrollbar(
                thumbVisibility: true,
                controller: _scrollController,
                child: TextField(
                  controller: widget.promptController,
                  scrollController: _scrollController,
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: 4,
                  style: GoogleFonts.poppins(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: "Ask Theta",
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (widget.pickedFiles.isNotEmpty)
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.insert_drive_file,
                    color: Colors.black,
                  ),
                  onPressed: widget.onShowPickedFiles,
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.red,
                    child: Text(
                      '${widget.pickedFiles.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.black),
            onPressed: widget.onPickFiles,
            tooltip: "Attach file",
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.black),
            onPressed: widget.onSend,
            tooltip: "Send message",
          ),
          IconButton(
            icon: Icon(
              widget.isRecording ? Icons.mic_off : Icons.mic,
              color: widget.isRecording ? Colors.red : Colors.black,
            ),
            onPressed: widget.onMicTap,
            tooltip: widget.isRecording ? "Stop recording" : "Start recording",
          ),
        ],
      ),
    );
  }
}
