import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyCtrl = TextEditingController();

  bool _creating = false;
  String _role = 'child';
  bool _loading = false;
  bool _registered = false;
  String? _familyId;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final nav = Navigator.of(context); // capture context before async gap
    final scaffold = ScaffoldMessenger.of(context);

    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser!;
    final db = FirebaseDatabase.instance;
    final fid = _creating
        ? db.ref('families').push().key!
        : _familyCtrl.text.trim();

    if (!_creating) {
      final exists = (await db.ref('families/$fid').get()).exists;
      if (!exists) {
        scaffold.showSnackBar(
          const SnackBar(content: Text('Family ID not found')),
        );
        setState(() => _loading = false);
        return;
      }
    }

    await db.ref('users/${user.uid}').set({
      'role': _role,
      'familyId': fid,
      'subscription': {'active': false},
    });
    await db.ref('families/$fid/users/${user.uid}').set(true);

    setState(() {
      _familyId = fid;
      _loading = false;
      _registered = true;
    });

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) nav.pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    if (_registered) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset('lib/assets/lottie/success.json'),
              const SizedBox(height: 16),
              if (_role == 'parent' && _familyId != null) ...[
                const Text('Your Family ID:', style: TextStyle(fontSize: 16)),
                SelectableText(
                  _familyId!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final scaffold = ScaffoldMessenger.of(
                      context,
                    ); // Capture first
                    final id = _familyId;
                    if (id != null) {
                      await Clipboard.setData(ClipboardData(text: id));
                      if (mounted) {
                        scaffold.showSnackBar(
                          const SnackBar(content: Text('Family ID copied!')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Family ID'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('FamBite Registration')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Lottie.asset('lib/assets/lottie/register.json', width: 150),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(value: 'child', child: Text('Child')),
                      DropdownMenuItem(value: 'parent', child: Text('Parent')),
                    ],
                    onChanged: (v) => setState(() => _role = v!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _creating,
                        onChanged: (v) => setState(() => _creating = v!),
                      ),
                      const Text('Create new family'),
                    ],
                  ),
                  if (!_creating)
                    TextFormField(
                      controller: _familyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Existing Family ID',
                      ),
                      validator: (v) =>
                          v != null && v.isNotEmpty ? null : 'Enter family ID',
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Continue'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
