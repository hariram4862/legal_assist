import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart'; // Add shimmer package in pubspec.yaml
import 'package:open_filex/open_filex.dart';

Future<void> showPickedFilesDialog(
  BuildContext context,
  List<PlatformFile> files,
  void Function(List<PlatformFile>) onFilesUpdated,
) {
  return showDialog(
    context: context,
    builder: (context) {
      return _AnimatedPickedFilesDialog(
        files: files,
        onFilesUpdated: onFilesUpdated,
      );
    },
  );
}

class _AnimatedPickedFilesDialog extends StatefulWidget {
  final List<PlatformFile> files;
  final void Function(List<PlatformFile>) onFilesUpdated;

  const _AnimatedPickedFilesDialog({
    required this.files,
    required this.onFilesUpdated,
  });

  @override
  State<_AnimatedPickedFilesDialog> createState() =>
      _AnimatedPickedFilesDialogState();
}

class _AnimatedPickedFilesDialogState
    extends State<_AnimatedPickedFilesDialog> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<PlatformFile> _localFiles;
  final bool _isUploading = false; // Simulated state
  Future<void> _pickAdditionalFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _localFiles.addAll(result.files);
        for (
          var i = _localFiles.length - result.files.length;
          i < _localFiles.length;
          i++
        ) {
          _listKey.currentState?.insertItem(i);
        }
      });
      widget.onFilesUpdated(List.from(_localFiles));
    }
  }

  @override
  void initState() {
    super.initState();
    _localFiles = List.from(widget.files);
  }

  void _removeFile(int index) {
    final removedFile = _localFiles.removeAt(index);

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildItem(removedFile, index, animation),
      duration: const Duration(milliseconds: 300),
    );

    widget.onFilesUpdated(List.from(_localFiles)); // ✅ notify parent

    if (_localFiles.isEmpty) Navigator.of(context).pop();
  }

  Widget _buildItem(PlatformFile file, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: InkWell(
        onTap: () async {
          final path = file.path;
          if (path != null) {
            final result = await OpenFilex.open(path);
            if (result.type != ResultType.done) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Unable to open this file.")),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("File path is unavailable.")),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Picked Files",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            tooltip: "Pick More Files",
            onPressed: _pickAdditionalFiles,
          ),
        ],
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
      ],
    );
  }
}
