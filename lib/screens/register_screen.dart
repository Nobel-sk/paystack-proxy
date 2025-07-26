import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _familyCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _newFamily = false;
  String _role = 'child';

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text.trim(),
          );

      final uid = userCred.user!.uid;
      final db = FirebaseDatabase.instance;
      final familyId = _newFamily
          ? db.ref('families').push().key!
          : _familyCtrl.text.trim();

      await db.ref('users/$uid').set({
        'familyId': familyId,
        'role': _role,
        'subscription': {'active': false},
      });

      await db.ref('families/$familyId/users/$uid').set(true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to register')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register to FamBite')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
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
                onChanged: (val) => setState(() => _role = val!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _newFamily,
                    onChanged: (val) => setState(() => _newFamily = val!),
                  ),
                  const Text("Create new family"),
                ],
              ),
              if (!_newFamily)
                TextFormField(
                  controller: _familyCtrl,
                  decoration: const InputDecoration(labelText: 'Family ID'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Invalid email' : null,
              ),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) =>
                    v == null || v.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
