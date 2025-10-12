import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A screen that provides a form for adding or editing products,
/// with a popup dialog for managing categories dynamically.
class AddEditProductScreen extends StatefulWidget {
  final DocumentSnapshot? product;
  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  final List<String> _selectedCategories = [];
  String _imageUrlPreview = '';
  bool _isLoading = false;
  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _imageUrlController.addListener(_updateImagePreview);

    if (_isEditing) {
      final productData = widget.product!.data() as Map<String, dynamic>;
      _nameController.text = productData['name'] ?? '';
      _descriptionController.text = productData['description'] ?? '';
      _priceController.text = (productData['price'] ?? 0.0).toString();
      _imageUrlController.text = productData['imageUrl'] ?? '';
      _imageUrlPreview = productData['imageUrl'] ?? '';
      if (productData['categories'] != null) {
        _selectedCategories.addAll(List<String>.from(productData['categories']));
      }
    }
  }

  void _updateImagePreview() {
    setState(() { _imageUrlPreview = _imageUrlController.text; });
  }

  @override
  void dispose() {
    _imageUrlController.removeListener(_updateImagePreview);
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_isLoading) return;
    if (_formKey.currentState!.validate()) {
      if (_selectedCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one category.'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() { _isLoading = true; });

      try {
        final Map<String, dynamic> productData = {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': double.parse(_priceController.text.trim()),
          'imageUrl': _imageUrlController.text.trim(),
          'categories': _selectedCategories,
        };

        if (_isEditing) {
          await FirebaseFirestore.instance.collection('products').doc(widget.product!.id).update(productData);
        } else {
          // Add creation-specific fields for new products
          productData['createdAt'] = Timestamp.now();
          productData['totalRating'] = 0;
          productData['ratingCount'] = 0;
          await FirebaseFirestore.instance.collection('products').add(productData);
        }
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save product: $e')));
        }
      } finally {
        if (mounted) setState(() { _isLoading = false; });
      }
    }
  }

  /// Opens the category management dialog.
  void _openManageCategories() {
    showDialog(
      context: context,
      builder: (_) => const _ManageCategoriesDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F0),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add New Product'),
        backgroundColor: const Color(0xFF333333),
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _submitForm,
              tooltip: 'Save Product',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePreview(),
              const SizedBox(height: 24),
              _buildTextFormField(controller: _nameController, label: 'Product Name', icon: Icons.label_outline, validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required.' : null),
              const SizedBox(height: 16),
              _buildTextFormField(controller: _descriptionController, label: 'Product Description', icon: Icons.description_outlined, maxLines: 3, validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required.' : null),
              const SizedBox(height: 16),
              _buildTextFormField(controller: _priceController, label: 'Price', icon: Icons.attach_money, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))], validator: (v) { if (v == null || v.trim().isEmpty) return 'Price is required.'; if (double.tryParse(v) == null) return 'Enter a valid price.'; return null; }),
              const SizedBox(height: 24),

              const Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [ BoxShadow(color: Colors.grey.withAlpha(25), spreadRadius: 2, blurRadius: 10) ],
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('categories').orderBy('name').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final availableCategories = snapshot.data!.docs.map((doc) => (doc.data() as Map<String, dynamic>)['name'] as String).toList();

                    return Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        ...availableCategories.map((category) {
                          final isSelected = _selectedCategories.contains(category);
                          return ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCategories.add(category);
                                } else {
                                  _selectedCategories.remove(category);
                                }
                              });
                            },
                            selectedColor: const Color(0xFFFFA726),
                            labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF333333)),
                            backgroundColor: Colors.grey[200],
                            shape: StadiumBorder(side: BorderSide(color: isSelected ? const Color(0xFFFFA726) : Colors.grey[400]!)),
                          );
                        }),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 18.0),
                          label: const Text('Manage'),
                          onPressed: _openManageCategories,
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),
              _buildTextFormField(controller: _imageUrlController, label: 'Image URL (Optional)', hint: 'Paste Cloudinary URL', icon: Icons.link, keyboardType: TextInputType.url, validator: (value) { if (value != null && value.trim().isNotEmpty && !value.startsWith('http')) { return 'Please enter a valid URL or leave it blank.'; } return null; }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [ BoxShadow(color: Colors.grey.withAlpha(25), spreadRadius: 2, blurRadius: 10) ],
        ),
        clipBehavior: Clip.antiAlias,
        child: _imageUrlPreview.trim().isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text('Image preview appears here', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        )
            : CachedNetworkImage(
          imageUrl: _imageUrlPreview,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 8),
                Text('Invalid or empty URL', style: TextStyle(color: Colors.red[700])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [ BoxShadow(color: Colors.grey.withAlpha(25), spreadRadius: 2, blurRadius: 10) ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        validator: validator,
      ),
    );
  }
}

/// A self-contained dialog widget for managing categories.
class _ManageCategoriesDialog extends StatefulWidget {
  const _ManageCategoriesDialog();

  @override
  State<_ManageCategoriesDialog> createState() => _ManageCategoriesDialogState();
}

class _ManageCategoriesDialogState extends State<_ManageCategoriesDialog> {
  final _categoryController = TextEditingController();

  void _addCategory() {
    final categoryName = _categoryController.text.trim();
    if (categoryName.isNotEmpty) {
      FirebaseFirestore.instance.collection('categories').add({'name': categoryName});
      _categoryController.clear();
    }
  }

  void _deleteCategory(String docId) {
    FirebaseFirestore.instance.collection('categories').doc(docId).delete();
  }

  void _editCategory(String docId, String currentName) {
    final editController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Category Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = editController.text.trim();
              if (newName.isNotEmpty) {
                FirebaseFirestore.instance.collection('categories').doc(docId).update({'name': newName});
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Categories'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'New Category Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFFFFA726)),
                    iconSize: 40,
                    onPressed: _addCategory,
                    tooltip: 'Add Category',
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('categories').orderBy('name').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final categories = snapshot.data!.docs;
                  if (categories.isEmpty) return const Center(child: Text('No categories yet.'));

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final categoryDoc = categories[index];
                      final categoryName = (categoryDoc.data() as Map<String, dynamic>)['name'];

                      return ListTile(
                        title: Text(categoryName),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.grey[600]),
                              onPressed: () => _editCategory(categoryDoc.id, categoryName),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red[700]),
                              onPressed: () => _deleteCategory(categoryDoc.id),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

