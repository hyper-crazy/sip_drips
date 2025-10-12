import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sip_drips/features/profile/screens/edit_profile_screen.dart';

/// The screen where users can view their profile information and access
/// account-related options like order history and settings.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Loading...';
  String _userEmail = 'Loading...';
  String _profilePicUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Fetches the current user's document from Firestore and updates the state.
  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() { _isLoading = false; });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _userName = userData['name'] ?? 'No Name';
          _userEmail = userData['email'] ?? 'No Email';
          _profilePicUrl = userData['profilePicUrl'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  /// Displays a feedback message to the user.
  void _showSnackBar(String message, {bool isError = true, int duration = 4}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: duration),
      ),
    );
  }

  /// Shows a dialog for the user to securely change their email address.
  void _showChangeEmailDialog() {
    final formKey = GlobalKey<FormState>();
    final newEmailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isDialogLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change Email'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: newEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'New Email Address'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter a new email.';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) return 'Please enter a valid email.';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Current Password'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Please enter your password.' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isDialogLoading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() { isDialogLoading = true; });
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      // --- FIX APPLIED HERE ---
                      // Capture context-dependent variables before the async gap.
                      final rootNavigator = Navigator.of(context, rootNavigator: true);
                      final dialogNavigator = Navigator.of(dialogContext);

                      final cred = EmailAuthProvider.credential(email: user.email!, password: passwordController.text);
                      try {
                        await user.reauthenticateWithCredential(cred);
                        await user.verifyBeforeUpdateEmail(newEmailController.text.trim());

                        _showSnackBar('Verification email sent. Please verify and log in again.', isError: false, duration: 3);
                        await Future.delayed(const Duration(seconds: 3));

                        await FirebaseAuth.instance.signOut();
                        rootNavigator.popUntil((route) => route.isFirst);

                      } on FirebaseAuthException catch (e) {
                        dialogNavigator.pop();
                        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                          _showSnackBar('Incorrect password. Please try again.');
                        } else {
                          _showSnackBar(e.message ?? 'An error occurred.');
                        }
                      } finally {
                        if (mounted) setDialogState(() { isDialogLoading = false; });
                      }
                    }
                  },
                  child: isDialogLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Shows a dialog for the user to securely change their password.
  void _showChangePasswordDialog() {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isDialogLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Current Password'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Please enter your current password.' : null,
                    ),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'New Password'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter a new password.';
                        if (v.length < 6) return 'Password must be at least 6 characters.';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Confirm New Password'),
                      validator: (v) {
                        if (v != newPasswordController.text) return 'Passwords do not match.';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isDialogLoading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() { isDialogLoading = true; });
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      // --- FIX APPLIED HERE ---
                      final rootNavigator = Navigator.of(context, rootNavigator: true);
                      final dialogNavigator = Navigator.of(dialogContext);

                      final cred = EmailAuthProvider.credential(email: user.email!, password: currentPasswordController.text);
                      try {
                        await user.reauthenticateWithCredential(cred);
                        await user.updatePassword(newPasswordController.text);

                        _showSnackBar('Password changed successfully. Please log in again.', isError: false, duration: 3);
                        await Future.delayed(const Duration(seconds: 3));

                        await FirebaseAuth.instance.signOut();
                        rootNavigator.popUntil((route) => route.isFirst);

                      } on FirebaseAuthException catch (e) {
                        dialogNavigator.pop();
                        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                          _showSnackBar('Incorrect password. Please try again.');
                        } else {
                          _showSnackBar(e.message ?? 'An error occurred.');
                        }
                      } finally {
                        if (mounted) setDialogState(() { isDialogLoading = false; });
                      }
                    }
                  },
                  child: isDialogLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F0),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFFFFF7F0),
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Color(0xFF333333),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadUserData,
        child: ListView(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),
            const Divider(),
            _buildSectionTitle('General'),
            _buildProfileOption(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                );
                _loadUserData();
              },
            ),
            _buildProfileOption(icon: Icons.history_outlined, title: 'Order History', onTap: () {}),
            _buildProfileOption(icon: Icons.reviews_outlined, title: 'My Reviews', onTap: () {}),
            _buildProfileOption(icon: Icons.location_on_outlined, title: 'Address Book', onTap: () {}),
            const Divider(),
            _buildSectionTitle('Security'),
            _buildProfileOption(icon: Icons.email_outlined, title: 'Change Email', onTap: _showChangeEmailDialog),
            _buildProfileOption(icon: Icons.password_outlined, title: 'Change Password', onTap: _showChangePasswordDialog),
            const Divider(),
            _buildProfileOption(
              icon: Icons.logout,
              title: 'Logout',
              color: Colors.red[700],
              onTap: () {
                FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFFFA726),
            backgroundImage: _profilePicUrl.isNotEmpty
                ? CachedNetworkImageProvider(_profilePicUrl)
                : null,
            child: _profilePicUrl.isEmpty
                ? Text(
              _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
              style: const TextStyle(fontSize: 36, color: Colors.white),
            )
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _userEmail,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[800]),
      title: Text(title, style: TextStyle(fontSize: 16, color: color ?? Colors.grey[800])),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
      onTap: onTap,
    );
  }
}
