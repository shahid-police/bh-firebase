import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class AddProductPage extends StatefulWidget {
  static String routeName = "addproduct";
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _karatController = TextEditingController();
  final TextEditingController _categoryIdController = TextEditingController();
  final TextEditingController _subcategoryIdController = TextEditingController();
  final TextEditingController _sellerIdController = TextEditingController();

  bool _inStock = true;
  List<XFile> _images = [];
  bool _uploading = false;

  Future<void> _pickImages() async {
    final ImagePicker _picker = ImagePicker();
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _images = pickedFiles;
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> downloadUrls = [];
    for (XFile image in _images) {
      final ref = FirebaseStorage.instance.ref().child('product_images/${DateTime.now().millisecondsSinceEpoch}_${image.name}');
      final uploadTask = await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();
      downloadUrls.add(url);
    }
    return downloadUrls;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select at least one image')));
      return;
    }

    setState(() => _uploading = true);

    try {
      final imageUrls = await _uploadImages();

      await FirebaseFirestore.instance.collection('products').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'categoryId': _categoryIdController.text.trim(),
        'subcategoryId': _subcategoryIdController.text.trim(),
        'inStock': _inStock,
        'weight': double.parse(_weightController.text.trim()),
        'karat': _karatController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'sellerId': _sellerIdController.text.trim(),
        'likeCount': 0,
        'images': imageUrls,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product added successfully')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_nameController, 'Product Name'),
              _buildTextField(_descriptionController, 'Description', maxLines: 3),
              _buildTextField(_priceController, 'Price', keyboardType: TextInputType.number),
              _buildTextField(_weightController, 'Weight', keyboardType: TextInputType.number),
              _buildTextField(_karatController, 'Karat'),
              _buildTextField(_categoryIdController, 'Category ID'),
              _buildTextField(_subcategoryIdController, 'Subcategory ID'),
              _buildTextField(_sellerIdController, 'Seller ID'),
              SwitchListTile(
                title: Text('In Stock'),
                value: _inStock,
                onChanged: (val) => setState(() => _inStock = val),
              ),
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: Icon(Icons.image),
                label: Text('Pick Images (${_images.length})'),
              ),
              SizedBox(height: 20),
              _uploading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _submitForm,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
      ),
    );
  }
}
