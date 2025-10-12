import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // A package for date formatting.

/// A screen that provides a form for users to edit their profile information.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _profilePicController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDate;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  /// Loads the current user's data to pre-fill the form fields.
  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        _nameController.text = userData['name'] ?? '';
        _profilePicController.text = userData['profilePicUrl'] ?? '';
        _phoneController.text = userData['phone'] ?? '';

        setState(() {
          _selectedGender = userData['gender'];
          if (userData['birthdate'] != null) {
            _selectedDate = (userData['birthdate'] as Timestamp).toDate();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _profilePicController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Displays a feedback message to the user.
  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  /// Handles the logic for saving the updated profile data.
  Future<void> _saveProfile() async {
    if (_isLoading) return;
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      try {
        final updatedData = {
          'name': _nameController.text.trim(),
          'profilePicUrl': _profilePicController.text.trim(),
          'phone': _phoneController.text.trim(),
          'gender': _selectedGender,
          'birthdate': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
        };
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updatedData);
        _showSnackBar('Profile updated successfully!', isError: false);
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        _showSnackBar('Failed to update profile. Please try again.');
      } finally {
        if (mounted) setState(() { _isLoading = false; });
      }
    }
  }

  /// Shows a date picker dialog to select the user's birthdate.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F0),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFFFFF7F0),
        elevation: 0,
        titleTextStyle: const TextStyle(color: Color(0xFF333333), fontSize: 22, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Color(0xFF333333)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Name cannot be empty.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _profilePicController,
                decoration: const InputDecoration(labelText: 'Profile Picture URL', hintText: 'Paste image URL'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number', hintText: '+880...'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty && !value.startsWith('+880')) {
                    return 'Phone number must start with +880';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: ['Male', 'Female'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Birthdate'),
                  child: Text(
                    _selectedDate == null ? 'Select your birthdate' : DateFormat('dd MMMM, yyyy').format(_selectedDate!),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA726),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

