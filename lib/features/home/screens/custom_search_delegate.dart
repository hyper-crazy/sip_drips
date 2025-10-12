import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A custom search delegate to provide a full-screen search experience.
///
/// This class handles the UI and logic for searching products, showing
/// suggestions as the user types, and displaying the final results.
class CustomSearchDelegate extends SearchDelegate<String> {
  // --- UI Customization ---

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFFFF7F0), // Theme background color
        iconTheme: IconThemeData(color: Colors.grey[700]),
        titleTextStyle: TextStyle(color: const Color(0xFF333333), fontSize: 18),
        toolbarTextStyle: TextStyle(color: const Color(0xFF333333), fontSize: 18),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  // --- Search Actions & Leading Icon ---

  /// Defines the "back" button on the left of the AppBar.
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        // Closes the search delegate and returns to the previous screen.
        close(context, '');
      },
    );
  }

  /// Defines actions on the right of the AppBar, like a "clear" button.
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      // Show a clear button only if there is text in the search query.
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = ''; // Clears the search text.
            showSuggestions(context); // Rebuilds suggestions.
          },
        ),
    ];
  }

  // --- Search Results & Suggestions ---

  /// Builds the final results page after a user submits a search.
  @override
  Widget buildResults(BuildContext context) {
    // For this app, the results and suggestions are the same.
    return _buildSearchResults();
  }

  /// Builds the suggestions list that appears as the user types.
  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  /// A helper widget to fetch and display search results from Firestore.
  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name'].toString().toLowerCase();
          // Filter products where the name contains the search query.
          return name.contains(query.toLowerCase());
        }).toList();

        if (results.isEmpty) {
          return Center(
            child: Text('No products found for "$query"'),
          );
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final productDoc = results[index];
            final productData = productDoc.data() as Map<String, dynamic>;
            final imageUrl = productData['imageUrl'] ?? '';

            return ListTile(
              leading: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
                  : const Icon(Icons.image_not_supported),
              title: Text(productData['name'] ?? 'No Name'),
              subtitle: Text('\$${(productData['price'] ?? 0.0).toStringAsFixed(2)}'),
              onTap: () {
                // When a suggestion is tapped, close the search.
                // In a future step, this could navigate to the product detail page.
                close(context, productData['name']);
              },
            );
          },
        );
      },
    );
  }
}
