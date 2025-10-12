import 'package:flutter/material.dart';
import 'package:sip_drips/features/admin/screens/manage_users_screen.dart';
import 'package:sip_drips/features/admin/screens/manage_products_screen.dart';
import 'package:sip_drips/features/admin/screens/manage_banners_screen.dart';

/// The main dashboard for admin-specific actions.
///
/// Provides navigation to various management screens like user and product management.
class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: const Color(0xFF333333),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // A card-style list tile for navigating to the user management page.
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.people_sharp),
              title: const Text('Manage Users'),
              subtitle: const Text('View, ban, or delete users'),
              trailing: const Icon(Icons.keyboard_arrow_right_sharp),
              onTap: () {
                // Navigates to the screen for managing all registered users.
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ManageUsersScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          //A card-style list tile for navigating to the product management page.
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Manage Products'),
              subtitle: const Text('Add, edit, or delete products'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ManageProductsScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          //A card-style list tile for navigating to the banner management page.
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.view_carousel_outlined),
              title: const Text('Manage Banners'),
              subtitle: const Text('Add or remove promotional ads'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ManageBannersScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
