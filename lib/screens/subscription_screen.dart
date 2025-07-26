import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;

  Future<void> _subscribe() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('You must be logged in');
      return;
    }

    setState(() => _loading = true);

    final url = Uri.parse('https://paystack-proxy.onrender.com/subscribe');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'email': _emailController.text.trim(),
      'amount': 100,
      'userId': user.uid,
    });

    try {
      final res = await http.post(url, headers: headers, body: body);
      final data = jsonDecode(res.body);

      if (data['status'] == true) {
        final authUrl = data['data']['authorization_url'];
        await launchUrl(
          Uri.parse(authUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showError('Failed: ${data['message']}');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Lottie.asset('lib/assets/lottie/subscribe.json', height: 180),
            const Text(
              'Subscribe to unlock full access for \$1/month',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _emailController,
                enabled: !_loading,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    v != null && v.contains('@') ? null : 'Enter a valid email',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _subscribe,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Subscribe'),
            ),
          ],
        ),
      ),
    );
  }
}
