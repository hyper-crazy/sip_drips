import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// A screen that provides a form for administrators to add a new banner
/// or edit an existing one.
class AddBannerScreen extends StatefulWidget {
  /// An optional banner document. If provided, the screen is in 'edit' mode.
  final DocumentSnapshot? banner;

  const AddBannerScreen({super.key, this.banner});

  @override
  State<AddBannerScreen> createState() => _AddBannerScreenState();
}

class _AddBannerScreenState extends State<AddBannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imageUrlController = TextEditingController();
  bool _isLoading = false;
  // A getter to easily check if the screen is in editing mode.
  bool get _isEditing => widget.banner != null;

  @override
  void initState() {
    super.initState();
    // If editing an existing banner, pre-fill the text field with its URL.
    if (_isEditing) {
      final bannerData = widget.banner!.data() as Map<String, dynamic>;
      _imageUrlController.text = bannerData['imageUrl'] ?? '';
    }
  }

  @override
  void dispose() {
    _imageUrlController.dispose();
    super.dispose();
  }

  /// Validates the form and saves or updates the banner data in Firestore.
  Future<void> _submitForm() async {
    if (_isLoading) return;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final bannerData = {
        'imageUrl': _imageUrlController.text.trim(),
        'createdAt': _isEditing
            ? (widget.banner!.data() as Map<String, dynamic>)['createdAt']
            : Timestamp.now(),
      };

      try {
        if (_isEditing) {
          // If editing, update the existing document.
          await FirebaseFirestore.instance
              .collection('banners')
              .doc(widget.banner!.id)
              .update(bannerData);
        } else {
          // If adding, create a new document.
          await FirebaseFirestore.instance
              .collection('banners')
              .add(bannerData);
        }

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save banner: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Banner' : 'Add New Banner'),
        backgroundColor: const Color(0xFF333333),
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child:
              Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _submitForm,
              tooltip: 'Save Banner',
            ),
        ],
      ),
      backgroundColor: const Color(0xFFFFF7F0), // Match app theme
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Image URL Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(25), // <-- CORRECTED
                      spreadRadius: 2,
                      blurRadius: 10,
                    )
                  ],
                ),
                child: TextFormField(
                  controller: _imageUrlController,
                  decoration: InputDecoration(
                    labelText: 'Banner Image URL',
                    hintText: 'Paste any image URL here',
                    prefixIcon: Icon(Icons.link, color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                  ),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an image URL.';
                    }
                    if (!value.startsWith('http')) {
                      return 'Please enter a valid URL.';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

