import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sip_drips/features/admin/screens/admin_panel_screen.dart';
import 'package:sip_drips/features/home/screens/custom_search_delegate.dart';

/// The main screen displayed to authenticated users, showing available products.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAdmin = false;
  String _selectedCategory = 'All'; // State for the selected category filter.

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  /// Fetches the current user's role to conditionally display admin UI.
  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (mounted && userDoc.exists && userDoc.data()?['isAdmin'] == true) {
          setState(() {
            _isAdmin = true;
          });
        }
      } catch (e) {
        debugPrint("Error checking admin status: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFF7F0),
          ),
        ),
        title: Row(
          children: [
            const Text(
              'SipDrips',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  showSearch(
                    context: context,
                    delegate: CustomSearchDelegate(),
                  );
                },
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Icon(Icons.search, color: Colors.grey[500], size: 20),
                      ),
                      const SizedBox(width: 8),
                      Text('Search products...', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.grey[700]),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFFF7F0),
      body: Column(
        children: [
          // Dynamic Promotional Banner Carousel
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('banners').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox(height: 150);
                }
                final banners = snapshot.data!.docs;
                return CarouselSlider(
                  options: CarouselOptions(
                    height: 150.0,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 5),
                    enlargeCenterPage: true,
                    viewportFraction: 0.85,
                  ),
                  items: banners.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final imageUrl = data['imageUrl'] ?? '';
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[200]),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // --- CUSTOM CATEGORY FILTER BAR ---
          _buildCategoryFilterBar(),

          // Product Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No products available right now.'));
                }

                // --- FILTERING LOGIC APPLIED HERE ---
                final allProducts = snapshot.data!.docs;
                final filteredProducts = _selectedCategory == 'All'
                    ? allProducts
                    : allProducts.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  // Checks if the product's 'categories' list contains the selected category.
                  return (data['categories'] as List<dynamic>).contains(_selectedCategory);
                }).toList();

                if (filteredProducts.isEmpty) {
                  return Center(child: Text('No products found in $_selectedCategory.'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0), // Added top padding
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final productDoc = filteredProducts[index];
                    return _UserProductGridCard(productDoc: productDoc);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
          );
        },
        backgroundColor: const Color(0xFF333333),
        foregroundColor: Colors.white,
        tooltip: 'Admin Panel',
        child: const Icon(Icons.admin_panel_settings),
      )
          : null,
    );
  }

  /// Builds the horizontal, scrollable list of custom category filter buttons.
  Widget _buildCategoryFilterBar() {
    return SizedBox(
      height: 50,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(height: 50); // Return an empty box while loading to prevent layout shifts
          }

          var categories = snapshot.data!.docs;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length + 1, // Add 1 for the "All" category
            itemBuilder: (context, index) {
              // Determine the category name for the current item.
              final String categoryName = (index == 0)
                  ? 'All'
                  : (categories[index - 1].data() as Map<String, dynamic>)['name'];

              final bool isSelected = _selectedCategory == categoryName;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = categoryName;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFFA726) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        categoryName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF333333),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// A custom card widget for the user-facing product grid.
class _UserProductGridCard extends StatelessWidget {
  final DocumentSnapshot productDoc;
  const _UserProductGridCard({required this.productDoc});

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
                    errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.error)),
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
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
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
                  Text(
                    '\$${productPrice.toStringAsFixed(2)}',
                    style: const TextStyle(color: Color(0xFF333333), fontSize: 16, fontWeight: FontWeight.bold),
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

