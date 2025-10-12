import 'package:flutter/material.dart';
import 'package:sip_drips/features/cart/screens/cart_screen.dart';
import 'package:sip_drips/features/home/screens/home_screen.dart';
import 'package:sip_drips/features/profile/screens/profile_screen.dart';

/// The main screen that holds the bottom navigation bar and manages the
/// primary pages of the application.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // A state variable to keep track of the currently selected tab index.
  int _selectedIndex = 0;

  // A list of the primary screens that the navigation bar will switch between.
  // The order of screens here MUST match the order of the navigation bar items.
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  /// This function is called when a navigation bar item is tapped.
  /// It updates the state with the new index, causing the UI to rebuild
  /// and show the corresponding screen from the _widgetOptions list.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body of the Scaffold displays the currently selected screen.
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      // The bottom navigation bar.
      bottomNavigationBar: BottomNavigationBar(
        // The list of navigation items (tabs).
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home), // A different icon for the active tab
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex, // Highlights the current tab.
        selectedItemColor: const Color(0xFFFFA726), // Our app's accent color
        unselectedItemColor: Colors.grey[600], // Color for inactive tabs
        onTap: _onItemTapped, // The function to call when a tab is tapped.
        showUnselectedLabels: false, // Hides labels for inactive tabs for a cleaner look
      ),
    );
  }
}