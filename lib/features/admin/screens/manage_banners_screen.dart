import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sip_drips/features/admin/screens/add_banner_screen.dart';

/// A screen for administrators to view, edit, and delete promotional banners.
class ManageBannersScreen extends StatelessWidget {
  const ManageBannersScreen({super.key});

  /// Displays a confirmation dialog before deleting a banner.
  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, String docId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text(
              'Are you sure you want to delete this banner? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                // Perform the delete operation in Firestore.
                FirebaseFirestore.instance
                    .collection('banners')
                    .doc(docId)
                    .delete();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Banners'),
        backgroundColor: const Color(0xFF333333),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('banners').snapshots(),
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
                'No banners found. Tap the + button to add one.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final banners = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final bannerDoc = banners[index];
              final bannerData = bannerDoc.data() as Map<String, dynamic>;
              final imageUrl = bannerData['imageUrl'] ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // The banner image.
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[200]),
                        errorWidget: (context, url, error) => const Center(
                          child: Text('Invalid Image URL'),
                        ),
                      ),
                    ),
                    // Overlay with Edit and Delete buttons.
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          // Edit Button
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withAlpha(128)), // <-- CORRECTED
                            onPressed: () {
                              // Navigate to the edit screen, passing the banner data.
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddBannerScreen(banner: bannerDoc),
                                ),
                              );
                            },
                            tooltip: 'Edit Banner',
                          ),
                          const SizedBox(width: 8),
                          // Delete Button
                          IconButton(
                            icon: const Icon(Icons.delete_forever,
                                color: Colors.white),
                            style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withAlpha(128)), // <-- CORRECTED
                            onPressed: () {
                              _showDeleteConfirmationDialog(
                                  context, bannerDoc.id);
                            },
                            tooltip: 'Delete Banner',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the add screen.
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddBannerScreen()),
          );
        },
        backgroundColor: const Color(0xFFFFA726),
        child: const Icon(Icons.add),
      ),
    );
  }
}

