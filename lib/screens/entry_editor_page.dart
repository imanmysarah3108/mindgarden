import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/entry.dart';
import '../utils/constants.dart';

class EntryEditorPage extends StatefulWidget {
  final Entry? entry;

  const EntryEditorPage({super.key, this.entry});

  @override
  State<EntryEditorPage> createState() => _EntryEditorPageState();
}

class _EntryEditorPageState extends State<EntryEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  File? _imageFile;
  String? _currentImageUrl;
  List<String> _tags = [];
  final _tagController = TextEditingController();
  String? _selectedColorHex;

  final List<Color> _availableColors = [
    const Color(0xFFFADADD), // Light Pink
    const Color(0xFFC4E4F4), // Light Blue
    const Color(0xFFD4F4D4), // Light Green
    const Color(0xFFFFFACD), // Lemon Chiffon
    const Color(0xFFE6E6FA), // Lavender
  ];

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
      _selectedDate = widget.entry!.entryDate;
      _currentImageUrl = widget.entry!.imageUrl;
      _tags = widget.entry!.tags ?? [];
      _selectedColorHex = widget.entry!.color;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _currentImageUrl = null;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _currentImageUrl = null;
    });
  }

  void _addTag() {
    final tagText = _tagController.text.trim();
    if (tagText.isNotEmpty && !_tags.contains(tagText)) {
      setState(() {
        _tags.add(tagText);
      });
      _tagController.clear();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  Future<void> _saveEntry() async {
    final title = _titleController.text;
    final content = _contentController.text;
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content cannot be empty.')),
      );
      return;
    }

    String? finalImageUrl = _currentImageUrl;
    if (_imageFile != null) {
      try {
        final userId = supabase.auth.currentUser!.id;
        final fileName = '${userId}/${DateTime.now().millisecondsSinceEpoch}${p.extension(_imageFile!.path)}';
        await supabase.storage.from('entry_images').upload(
              fileName,
              _imageFile!,
              fileOptions: const FileOptions(upsert: true),
            );
        finalImageUrl = supabase.storage.from('entry_images').getPublicUrl(fileName);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e')),
        );
        return;
      }
    }

    final entryData = {
      'user_id': supabase.auth.currentUser!.id,
      'title': title,
      'content': content,
      'entry_date': _selectedDate.toIso8601String(),
      'image_url': finalImageUrl,
      'tags': _tags,
      'color': _selectedColorHex,
    };

    try {
      if (widget.entry == null) {
        await supabase.from('entries').insert(entryData);
      } else {
        await supabase.from('entries').update(entryData).eq('id', widget.entry!.id);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save entry: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'New Entry' : 'Edit Entry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveEntry,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 10,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
                ),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Change Date'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildImagePicker(),
            const SizedBox(height: 16),
            _buildColorPicker(),
            const SizedBox(height: 16),
            _buildTagEditor(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Image', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_imageFile == null && _currentImageUrl == null)
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Insert Image'),
          )
        else
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: (_imageFile != null
                        ? FileImage(_imageFile!)
                        : NetworkImage(_currentImageUrl!)) as ImageProvider,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                onPressed: _removeImage,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: Wrap(
            spacing: 8,
            children: _availableColors.map((color) {
              final hex = _colorToHex(color);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColorHex = hex;
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: _selectedColorHex == hex
                        ? Border.all(color: Colors.black, width: 2)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTagEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: _tags.map((tag) => Chip(
            label: Text(tag),
            onDeleted: () => _removeTag(tag),
          )).toList(),
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagController,
                decoration: const InputDecoration(labelText: 'Add a tag'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addTag,
            ),
          ],
        ),
      ],
    );
  }
}