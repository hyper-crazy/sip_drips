import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// A screens for administrators to view and manage all users in the system.
///
/// Displays a real-time list of users from the Firestore 'users' collection.
class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  /// Toggles the 'isBanned' status for a given user in Firestore.
  Future<void> _toggleBanStatus(String userId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isBanned': !currentStatus,
      });
    } catch (e) {
      // Log any errors that occur during the Firestore update.
      debugPrint("Error toggling ban status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: const Color(0xFF333333),
        foregroundColor: Colors.white,
      ),
      // StreamBuilder listens for real-time updates from the Firestore collection.
      body: StreamBuilder<QuerySnapshot>(
        // Specifies the stream to listen to: the 'users' collection.
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          // Handles the loading state while waiting for data.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handles any errors that occur during data fetching.
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Handles the case where the collection is empty.
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          // Extracts the list of user documents from the snapshot.
          final users = snapshot.data!.docs;

          // Builds a scrollable list of users.
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              // Get the data and document ID for the current user
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;
              final userName = userData['name'];
              final userEmail = userData['email'];
              final isAdmin = userData['isAdmin'] ?? false;
              final isBanned = userData['isBanned'] ?? false;
              final currentAdminId = FirebaseAuth.instance.currentUser?.uid;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                // Change the tile color if the user is banned
                color: isBanned ? Colors.grey[300] : Colors.white,
                child: ListTile(
                  leading: Icon(
                    isAdmin ? Icons.shield_sharp : Icons.person_sharp,
                  ),
                  title: Text(
                    userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userEmail),
                      Text(
                        isAdmin
                            ? 'Admin'
                            : (isBanned ? 'Banned' : 'Regular User'),
                        style: TextStyle(
                          color: isAdmin
                              ? Colors.blue
                              : (isBanned ? Colors.red : Colors.grey),
                          fontWeight: isBanned
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  // Conditionally render the trailing widget.
                  // If the user is a regular user (and not the current admin), an IconButton is shown.
                  // Otherwise, null is returned, and no widget is rendered.
                  trailing: (!isAdmin && userDoc.id != currentAdminId)
                      ? IconButton(
                    icon: Icon(
                      isBanned
                          ? Icons.check_circle_sharp
                          : Icons.block_sharp,
                      color: isBanned ? Colors.green : Colors.red,
                    ),
                    tooltip: isBanned ? 'Unban User' : 'Ban User',
                    onPressed: () => _toggleBanStatus(userDoc.id, isBanned),
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
