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
  final bool isTranscribing;

  const InputBar({
    super.key,
    required this.promptController,
    required this.pickedFiles,
    required this.isRecording,
    required this.onMicTap,
    required this.onPickFiles,
    required this.onSend,
    required this.onShowPickedFiles,
    required this.isTranscribing,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final ScrollController _scrollController = ScrollController();
  bool _showExtendedIcons = false;

  Widget buildIconButton({
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    required IconData icon,
    Color color = Colors.black,
    String? tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Tooltip(
          message: tooltip ?? '',
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleIconPanel() {
    setState(() {
      _showExtendedIcons = !_showExtendedIcons;
    });

    // Optional auto-hide after delay
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showExtendedIcons = false;
        });
      }
    });
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
              constraints: const BoxConstraints(maxHeight: 100),
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

          // Conditionally show extended icons
          if (_showExtendedIcons) ...[
            Transform.translate(
              offset: const Offset(0, -4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  buildIconButton(
                    onTap:
                        widget.pickedFiles.isEmpty
                            ? widget.onPickFiles
                            : widget.onShowPickedFiles, // ⬅️ logic switch here
                    icon: Icons.attach_file,
                  ),
                  if (widget.pickedFiles.isNotEmpty)
                    Positioned(
                      right: 6,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.only(
                          top: 0.8,
                          left: 0.5,
                          right: 0.5,
                          bottom: 0,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 13.5,
                          minHeight: 13.5,
                        ),
                        child: Text(
                          '${widget.pickedFiles.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -4),
              child: buildIconButton(onTap: widget.onMicTap, icon: Icons.mic),
            ),
          ],

          // Long press-enabled Send button
          Transform.translate(
            offset: const Offset(0, -4), // Adjust this value to shift up
            child: buildIconButton(
              onTap: widget.onSend,
              onLongPress: _toggleIconPanel,
              icon: Icons.send,
            ),
          ),
        ],
      ),
    );
  }
}
