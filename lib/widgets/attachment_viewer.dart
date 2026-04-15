import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme_extension.dart';

class AttachmentViewer extends StatefulWidget {
  final String? initialPath;
  final Function(String?) onAttachmentSelected;
  final String label;

  const AttachmentViewer({
    super.key,
    this.initialPath,
    required this.onAttachmentSelected,
    this.label = "إرفاق مستند (صورة)",
  });

  @override
  State<AttachmentViewer> createState() => _AttachmentViewerState();
}

class _AttachmentViewerState extends State<AttachmentViewer> {
  String? _currentPath;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath;
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _currentPath = result.files.single.path;
      });
      widget.onAttachmentSelected(_currentPath);
    }
  }

  void _clear() {
    setState(() {
      _currentPath = null;
    });
    widget.onAttachmentSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              if (_currentPath != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                  onPressed: _clear,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_currentPath == null)
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: Colors.white54),
                    SizedBox(height: 4),
                    Text("انقر لإضافة صورة", style: TextStyle(fontSize: 10, color: Colors.white38)),
                  ],
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.file(
                      File(_currentPath!),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    PositionRectangle(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black54, Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 8,
                      right: 8,
                      child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                    )
                  ],
                ),
            ),
        ],
      ),
    );
  }
}

class PositionRectangle extends StatelessWidget {
  final Widget child;
  const PositionRectangle({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(child: child);
  }
}
