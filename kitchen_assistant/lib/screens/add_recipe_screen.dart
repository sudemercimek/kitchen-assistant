import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<TextEditingController> _ingredients = [TextEditingController()];
  final List<TextEditingController> _steps = [TextEditingController()];

  Uint8List? _selectedBytes;
  String? _imageUrl;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedBytes = result.files.single.bytes;
      });
    }
  }

  Future<void> _createRecipe() async {
    if (_selectedBytes == null || _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image and enter a title.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('recipe_images/$fileName.jpg');
      final uploadTask = await ref.putData(_selectedBytes!);
      _imageUrl = await uploadTask.ref.getDownloadURL();

      final ingredients = _ingredients.map((c) => c.text).where((e) => e.isNotEmpty).toList();
      final steps = _steps.map((c) => c.text).where((e) => e.isNotEmpty).toList();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) throw Exception('User not logged in.');

      final recipeData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': _imageUrl,
        'ingredients': ingredients,
        'steps': steps,
        'likes': 0,
        'comments': [],
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('recipes').add(recipeData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe successfully added!')),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving recipe: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
// sayfa tasarımı
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE8D8),
      appBar: AppBar(
        title: const Text('Add Recipe'),
        backgroundColor: const Color(0xFFEFE8D8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[300],
                ),
                child: _selectedBytes != null
                    ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_selectedBytes!, fit: BoxFit.cover))
                    : const Icon(Icons.image, size: 60, color: Colors.teal),
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField('Title', _titleController),
            _buildTextField('Description', _descriptionController, maxLines: 3),
            _buildListField('Ingredients', _ingredients),
            _buildListField('Steps', _steps),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _createRecipe,
              icon: const Icon(Icons.cloud_upload),
              label: _isLoading ? const CircularProgressIndicator() : const Text('Create Recipe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          fillColor: Colors.white,
          filled: true,
        ),
      ),
    );
  }

  Widget _buildListField(String label, List<TextEditingController> controllers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...controllers.map((c) => _buildTextField('', c)),
        TextButton(
          onPressed: () {
            setState(() => controllers.add(TextEditingController()));
          },
          child: const Text('+ Add More', style: TextStyle(color: Colors.purple)),
        ),
      ],
    );
  }
}
