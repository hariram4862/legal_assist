import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart'; // Add shimmer package in pubspec.yaml

Future<void> showPickedFilesDialog(
  BuildContext context,
  List<PlatformFile> files,
  void Function(int index) onDelete,
) {
  return showDialog(
    context: context,
    builder: (context) {
      return _AnimatedPickedFilesDialog(files: files, onDelete: onDelete);
    },
  );
}

class _AnimatedPickedFilesDialog extends StatefulWidget {
  final List<PlatformFile> files;
  final void Function(int index) onDelete;

  const _AnimatedPickedFilesDialog({
    required this.files,
    required this.onDelete,
  });

  @override
  State<_AnimatedPickedFilesDialog> createState() =>
      _AnimatedPickedFilesDialogState();
}

class _AnimatedPickedFilesDialogState
    extends State<_AnimatedPickedFilesDialog> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<PlatformFile> _localFiles;
  bool _isUploading = false; // Simulated state

  @override
  void initState() {
    super.initState();
    _localFiles = List.from(widget.files);
  }

  void _removeFile(int index) {
    final removedFile = _localFiles.removeAt(index);
    widget.onDelete(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildItem(removedFile, index, animation),
      duration: const Duration(milliseconds: 300),
    );

    if (_localFiles.isEmpty) Navigator.of(context).pop();
  }

  Widget _buildItem(PlatformFile file, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file, color: Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    file.extension ?? "unknown",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            if (_isUploading)
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.white,
                child: const Icon(Icons.cloud_upload, size: 20),
              )
            else
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                onPressed: () => _removeFile(index),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        "Picked Files",
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.black,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: AnimatedList(
          key: _listKey,
          initialItemCount: _localFiles.length,
          itemBuilder: (context, index, animation) {
            final file = _localFiles[index];
            return _buildItem(file, index, animation);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("Close", style: GoogleFonts.poppins(color: Colors.black)),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isUploading = !_isUploading;
            });
          },
          child: Text(
            _isUploading ? "Stop Shimmer" : "Simulate Upload",
            style: GoogleFonts.poppins(color: Colors.black),
          ),
        ),
      ],
    );
  }
}
