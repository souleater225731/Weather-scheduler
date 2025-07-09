import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;

  final nameController = TextEditingController();
  final birthdayController = TextEditingController();
  final numberController = TextEditingController();
  final instagramController = TextEditingController();
  final emailController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = 'keyro@example.com'; // Replace with real user ID/email

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      nameController.text = data['name'] ?? '';
      birthdayController.text = data['birthday'] ?? '';
      numberController.text = data['number'] ?? '';
      instagramController.text = data['instagram'] ?? '';
      emailController.text = data['email'] ?? '';
    }
  }

  Future<void> _saveUserProfile() async {
    await _firestore.collection('users').doc(userId).set({
      'name': nameController.text,
      'birthday': birthdayController.text,
      'number': numberController.text,
      'instagram': instagramController.text,
      'email': emailController.text,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section
            Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 20,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: const [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 60, color: Colors.blue),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Keyro Sibug',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Editable Info Fields (no password)
            ProfileItemField(
              icon: Icons.person_outline,
              controller: nameController,
              enabled: isEditing,
              hintText: 'Enter your full name',
            ),
            ProfileItemField(
              icon: Icons.cake_outlined,
              controller: birthdayController,
              enabled: isEditing,
              hintText: 'Enter your birthday (e.g. Jan 1, 2000)',
            ),
            ProfileItemField(
              icon: Icons.phone_outlined,
              controller: numberController,
              enabled: isEditing,
              hintText: 'Enter your phone number',
            ),
            ProfileItemField(
              icon: Icons.camera_alt_outlined,
              controller: instagramController,
              enabled: isEditing,
              hintText: 'Enter your Instagram username',
            ),
            ProfileItemField(
              icon: Icons.mail_outline,
              controller: emailController,
              enabled: isEditing,
              hintText: 'Enter your email address',
            ),

            const SizedBox(height: 32),

            // Edit/Save Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() => isEditing = !isEditing);
                    if (!isEditing) {
                      await _saveUserProfile();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile saved successfully!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: const Color(0xFF1976D2),
                  ),
                  child: Text(
                    isEditing ? 'Save Profile' : 'Edit Profile',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Reusable input field widget
class ProfileItemField extends StatelessWidget {
  final IconData icon;
  final TextEditingController controller;
  final bool enabled;
  final String hintText;

  const ProfileItemField({
    super.key,
    required this.icon,
    required this.controller,
    required this.enabled,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 32),
      leading: Icon(icon, color: Colors.blue),
      title: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
