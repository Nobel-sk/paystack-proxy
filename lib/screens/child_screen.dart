import 'package:fam_bite/widgets/user_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ChildScreen extends StatefulWidget {
  const ChildScreen({super.key});

  @override
  State<ChildScreen> createState() => _ChildScreenState();
}

class _ChildScreenState extends State<ChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  bool _loading = false;

  Future<void> _submitItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final db = FirebaseDatabase.instance;

      final userSnap = await db.ref('users/${user.uid}').get();
      final userData = userSnap.value as Map?;
      final familyId = userData?['familyId'];

      if (familyId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not assigned to a family.')),
          );
        }
        return;
      }

      final itemRef = db.ref('grocery_lists/$familyId/items').push();
      await itemRef.set({
        'name': _itemController.text.trim(),
        'addedBy': user.uid,
        'addedAt': DateTime.now().toIso8601String(),
        'bought': false,
      });

      _itemController.clear();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Item submitted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bill your parent")),
      drawer: const UserDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Lottie.asset('lib/assets/lottie/checkout.json', height: 150),
              const SizedBox(height: 12),
              const Text('Submit grocery items to your parent'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _itemController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter an item' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loading ? null : _submitItem,
                icon: const Icon(Icons.send),
                label: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
