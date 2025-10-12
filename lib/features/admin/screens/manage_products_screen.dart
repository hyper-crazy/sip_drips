import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sip_drips/features/admin/screens/add_edit_product_screen.dart';

/// Enum to define the available sorting options for the product list.
/// This provides a type-safe way to manage the selected sort order.
enum ProductSortOption {
  nameAsc,
  nameDesc,
  priceAsc,
  priceDesc,
}

/// A screen for administrators to view, sort, and manage all products.
class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  // State variable to hold the currently selected sorting option.
  // Defaults to sorting by name in ascending order (A-Z).
  ProductSortOption _currentSortOption = ProductSortOption.nameAsc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        backgroundColor: const Color(0xFF333333),
        foregroundColor: Colors.white,
        actions: [
          // This button provides a dropdown menu for sorting options.
          PopupMenuButton<ProductSortOption>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Sort Products',
            onSelected: (ProductSortOption option) {
              // When an option is selected, update the state to trigger a rebuild.
              setState(() {
                _currentSortOption = option;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<ProductSortOption>>[
              const PopupMenuItem<ProductSortOption>(
                value: ProductSortOption.nameAsc,
                child: Text('Name (A-Z)'),
              ),
              const PopupMenuItem<ProductSortOption>(
                value: ProductSortOption.nameDesc,
                child: Text('Name (Z-A)'),
              ),
              const PopupMenuItem<ProductSortOption>(
                value: ProductSortOption.priceAsc,
                child: Text('Price (Low to High)'),
              ),
              const PopupMenuItem<ProductSortOption>(
                value: ProductSortOption.priceDesc,
                child: Text('Price (High to Low)'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No products found. Tap the + button to add one!',
                textAlign: TextAlign.center,
              ),
            );
          }

          // A mutable copy of the documents list from Firestore.
          final products = snapshot.data!.docs;

          // --- SORTING LOGIC ---
          // The list is sorted here, before being passed to the GridView.
          products.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            switch (_currentSortOption) {
              case ProductSortOption.nameAsc:
                return (aData['name'] as String).compareTo(bData['name'] as String);
              case ProductSortOption.nameDesc:
                return (bData['name'] as String).compareTo(aData['name'] as String);
              case ProductSortOption.priceAsc:
                return (aData['price'] as num).compareTo(bData['price'] as num);
              case ProductSortOption.priceDesc:
                return (bData['price'] as num).compareTo(aData['price'] as num);
            }
          });

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              // A smaller value makes the card taller, giving more space to the image.
              childAspectRatio: 0.7,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final productDoc = products[index];
              return _ProductGridCard(productDoc: productDoc);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddEditProductScreen()),
          );
        },
        backgroundColor: const Color(0xFFFFA726),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// A custom widget representing a single product card in the admin grid.
class _ProductGridCard extends StatelessWidget {
  final DocumentSnapshot productDoc;

  const _ProductGridCard({required this.productDoc});

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const SingleChildScrollView(
            child: Text('Are you sure you want to permanently delete this product? This action cannot be undone.'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                FirebaseFirestore.instance.collection('products').doc(productDoc.id).delete();
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productData = productDoc.data() as Map<String, dynamic>;
    final productName = productData['name'] ?? 'No Name';
    final productPrice = productData['price']?.toDouble() ?? 0.0;
    final imageUrl = productData['imageUrl'] ?? '';
    final categories = List<String>.from(productData['categories'] ?? []);
    final totalRating = productData['totalRating'] ?? 0;
    final ratingCount = productData['ratingCount'] ?? 0;
    final averageRating = ratingCount > 0 ? totalRating / ratingCount : 0.0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // In a future step, this could navigate to a detail view
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.error),
                    ),
                  ),
                  if (ratingCount > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(153),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (categories.isNotEmpty)
                    Wrap(
                      spacing: 4.0,
                      runSpacing: 4.0,
                      children: categories.map((category) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                        ),
                      )).toList(),
                    ),
                  const SizedBox(height: 6),
                  // --- LAYOUT FIX APPLIED HERE ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${productPrice.toStringAsFixed(2)}',
                        style: const TextStyle(color: Color(0xFF333333), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => AddEditProductScreen(product: productDoc)),
                            );
                          } else if (value == 'delete') {
                            _showDeleteConfirmationDialog(context);
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
                        ],
                        icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

