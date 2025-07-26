import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser!;
    final snap = await FirebaseDatabase.instance.ref('users/${user.uid}').get();
    final data = snap.value as Map?;

    if (mounted) {
      setState(() {
        _userData = {
          'email': user.email,
          'familyId': data?['familyId'],
          'role': data?['role'],
          'subscription': data?['subscription']?['active'] == true,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    child: Icon(Icons.person, size: 50),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow('Email', _userData!['email']),
                  _buildInfoRow('Role', _userData!['role']),
                  _buildInfoRow('Family ID', _userData!['familyId']),
                  _buildInfoRow(
                    'Subscription',
                    _userData!['subscription'] ? 'Active ✅' : 'Not Active ❌',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: Text(label),
      subtitle: Text(value ?? 'Unavailable'),
    );
  }
}
