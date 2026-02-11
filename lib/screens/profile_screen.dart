import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart'; // Import for User type

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );
    final user = await firestoreService.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      // Fallback to Auth User if Firestore user is null but Auth is logged in
      final authUser = authService.currentUser;
      if (authUser != null) {
        _user = User(
          id: authUser.uid,
          name: authUser.displayName ?? 'New User',
          avatarUrl:
              authUser.photoURL ??
              'https://ui-avatars.com/api/?name=New+User&background=random',
          nationality: 'Global 🌍',
        );
      } else {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("User not found."),
                ElevatedButton(
                  onPressed: () => authService.signOut(),
                  child: const Text("Logout"),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: Color(0xFF1A1F36),
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF1A1F36)),
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.orange[50], // Light orange bg
                    backgroundImage:
                        _user!.avatarUrl.isNotEmpty &&
                            !_user!.avatarUrl.contains('ui-avatars')
                        ? NetworkImage(_user!.avatarUrl)
                        : null,
                    child:
                        (_user!.avatarUrl.isEmpty ||
                            _user!.avatarUrl.contains('ui-avatars'))
                        ? Text(
                            _user!.name.isNotEmpty
                                ? _user!.name[0].toLowerCase()
                                : 'u',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange[400], // Orange text
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user!.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${_user!.name.toLowerCase().replaceAll(' ', '')}65', // Mock handle
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // Light blue bg
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.public,
                          size: 14,
                          color: Color(0xFF3B82F6),
                        ), // Globe icon
                        const SizedBox(width: 4),
                        Text(
                          _user!.nationality
                              .replaceAll(RegExp(r'[^\w\s]'), '')
                              .trim(), // Remove emoji for clean look like "USA"
                          style: const TextStyle(
                            color: Color(0xFF3B82F6), // Blue text
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bio Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      'Tap to add a bio...',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                    const Spacer(),
                    Icon(Icons.edit, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // My Posts Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: const Color(0xFFF9FAFB), // Slight bg change for section
              child: const Text(
                'My Posts (0)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1F36),
                ),
              ),
            ),

            // Empty State
            Container(
              height: 300,
              color: const Color(0xFFF9FAFB),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 48,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No posts yet',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
