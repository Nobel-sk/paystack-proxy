import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => SubscriptionScreenState();
}

class SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _loading = false;
  bool _complete = false;
  String? _error;

  Future<void> _subscribe() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final response = await http.post(
        Uri.parse('https://paystack-proxy.onrender.com/subscribe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': user.email ?? '',
          'amount': 100, // Represents USD 1 in cents or kobo etc.
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        await FirebaseDatabase.instance
            .ref('users/${user.uid}/subscription')
            .set({'active': true, 'since': DateTime.now().toIso8601String()});

        if (!mounted) return;
        setState(() => _complete = true);

        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
      } else {
        setState(() => _error = data['message'] ?? 'Subscription failed');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Connection error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_complete) {
      return Scaffold(
        body: Center(
          child: Lottie.asset(
            'lib/assets/lottie/success.json',
            width: 200,
            repeat: false,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Subscribe')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'lib/assets/lottie/subscribe.json',
              width: 180,
              repeat: true,
            ),
            const SizedBox(height: 20),
            const Text(
              'Subscribe for \$1/month to access FamBite features',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _subscribe,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(),
                    )
                  : const Text('Subscribe Now!'),
            ),
          ],
        ),
      ),
    );
  }
}
