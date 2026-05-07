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
    this.label = "إرفاق مستند",
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
      type: FileType.any, // Allow any file type for professional use
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

  bool _isImage(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png') || ext.endsWith('.gif') || ext.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    final bool isNetwork = _currentPath != null && _currentPath!.startsWith('http');

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
                    Icon(Icons.upload_file_outlined, color: Colors.white54),
                    SizedBox(height: 4),
                    Text("انقر لإضافة ملف أو صورة", style: TextStyle(fontSize: 10, color: Colors.white38)),
                  ],
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 120,
                width: double.infinity,
                color: Colors.black26,
                child: _isImage(_currentPath!)
                    ? (isNetwork
                        ? Image.network(_currentPath!, fit: BoxFit.cover)
                        : Image.file(File(_currentPath!), fit: BoxFit.cover))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.insert_drive_file, color: Colors.white70, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            _currentPath!.split('/').last.split('\\').last,
                            style: const TextStyle(fontSize: 10, color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

