import 'package:fam_bite/widgets/user_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen({super.key});

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  DatabaseReference? _itemsRef;
  // ignore: unused_field
  String? _familyId;

  @override
  void initState() {
    super.initState();
    _loadFamily();
  }

  Future<void> _loadFamily() async {
    final user = FirebaseAuth.instance.currentUser!;
    final db = FirebaseDatabase.instance;
    final userSnap = await db.ref('users/${user.uid}').get();
    final userData = userSnap.value as Map?;
    final familyId = userData?['familyId'];

    if (familyId == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No family assigned')));
      }
      return;
    }

    if (mounted) {
      setState(() {
        _familyId = familyId;
        _itemsRef = db.ref('grocery_lists/$familyId/items');
      });
    }
  }

  Future<void> _toggleItem(String itemId, bool currentStatus) async {
    await _itemsRef?.child(itemId).update({'bought': !currentStatus});
  }

  @override
  Widget build(BuildContext context) {
    if (_itemsRef == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Grocery List')),
      drawer: const UserDrawer(),
      body: StreamBuilder<DatabaseEvent>(
        stream: _itemsRef!.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No items yet'));
          }

          final items = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          return Column(
            children: [
              Lottie.asset('lib/assets/lottie/checkout.json', height: 130),
              Expanded(
                child: ListView(
                  children: items.entries.map((entry) {
                    final id = entry.key;
                    final item = Map<String, dynamic>.from(entry.value);
                    final name = item['name'] ?? '';
                    final bought = item['bought'] ?? false;
                    final addedBy = item['addedBy'] ?? '';

                    return ListTile(
                      title: Text(name),
                      subtitle: Text('Added by: $addedBy'),
                      trailing: Icon(
                        bought
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: bought ? Colors.green : null,
                      ),
                      onTap: () => _toggleItem(id, bought),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
