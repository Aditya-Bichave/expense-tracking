import re

f = 'lib/features/groups/presentation/pages/create_group_page.dart'
with open(f, 'r') as file:
    content = file.read()

import_image_picker = "import 'dart:io';\nimport 'package:image_picker/image_picker.dart';"
if 'package:image_picker/image_picker.dart' not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_image_picker)

if 'File? _selectedPhoto;' not in content:
    content = content.replace("bool _isInitialized = false;", "bool _isInitialized = false;\n  File? _selectedPhoto;\n  final ImagePicker _picker = ImagePicker();")

    pick_method = """
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedPhoto = File(pickedFile.path);
      });
    }
  }
"""
    content = content.replace("void dispose() {", pick_method + "\n  @override\n  void dispose() {")

    image_ui = """
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: kit.colors.surfaceContainerHigh,
                      backgroundImage: _selectedPhoto != null ? FileImage(_selectedPhoto!) : null,
                      child: _selectedPhoto == null ? Icon(Icons.add_a_photo, color: kit.colors.textSecondary) : null,
                    ),
                  ),
                  kit.spacing.gapLg,
"""
    content = content.replace("AppTextField(\n                    controller: _nameController,", image_ui + "                  AppTextField(\n                    controller: _nameController,")

    content = content.replace("userId: authState.user.id,", "userId: authState.user.id,\n                                        photoFile: _selectedPhoto,")

with open(f, 'w') as file:
    file.write(content)
