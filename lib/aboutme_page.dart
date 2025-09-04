// lib/aboutme_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart';
import 'orders_page.dart';
import 'cart_badge_icon.dart';
import 'addlocation.dart';

class AboutmePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AboutmePage({Key? key, required this.userData}) : super(key: key);

  @override
  _AboutmePageState createState() => _AboutmePageState();
}

class _AboutmePageState extends State<AboutmePage> {
  // ---------- Auth helpers ----------
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await user.delete();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account successfully deleted.')),
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting account: ${e.message}')),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ---------- Address format ----------
  String _formatAddress(Map<String, dynamic>? addr) {
    if (addr == null || addr.isEmpty) return 'Not provided';
    final parts = <String>[
      (addr['street']  ?? '').toString(),
      (addr['city']    ?? '').toString(),
      (addr['state']   ?? '').toString(),
      (addr['pincode'] ?? '').toString(),
      (addr['country'] ?? '').toString(),
    ].where((s) => s.trim().isNotEmpty);
    final text = parts.join(', ');
    return text.isEmpty ? 'Not provided' : text;
  }

  // ---------- Phone helpers (US) ----------
  String _prettyPhone(String input) {
    // Show (555) 123-4567 for +1XXXXXXXXXX or 10-digit raw
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11 && digits.startsWith('1')) {
      final d = digits.substring(1);
      return '(${d.substring(0,3)}) ${d.substring(3,6)}-${d.substring(6)}';
    }
    if (digits.length == 10) {
      return '(${digits.substring(0,3)}) ${digits.substring(3,6)}-${digits.substring(6)}';
    }
    return input; // fallback
  }

  String? _validateUsPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Please enter your mobile number';
    if (digits.length == 10) return null;
    if (digits.length == 11 && digits.startsWith('1')) return null;
    return 'Enter a valid 10-digit US number';
  }

  String _normalizeToE164(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) return '+1$digits';
    if (digits.length == 11 && digits.startsWith('1')) return '+$digits';
    // If it doesn't match, store trimmed as-is (shouldn’t happen after validator)
    return value.trim();
  }

  Future<void> _showEditPhoneDialog(String initialPhone) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController(
      text: initialPhone == 'Not provided' ? '' : initialPhone,
    );

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Mobile Number'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: 'e.g. 555-123-4567',
            ),
            validator: (v) => _validateUsPhone(v ?? ''),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please sign in first.')),
                );
                Navigator.pop(context);
                return;
              }
              final normalized = _normalizeToE164(ctrl.text);
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .set({
                  'phone': normalized,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mobile number updated')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ---------- Small UI helpers ----------
  Widget _infoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool showChevron = false,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.red),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing ?? (showChevron ? const Icon(Icons.arrow_forward_ios, size: 16) : null),
        onTap: onTap,
      ),
    );
  }

  Widget _option({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.red),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in to view your profile.')));
    }

    final docStream =
        FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [CartBadgeIcon()],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docStream,
        builder: (context, snapshot) {
          Map<String, dynamic> fsData = {};
          if (snapshot.hasData && snapshot.data!.exists) {
            fsData = snapshot.data!.data() as Map<String, dynamic>;
          }

          final displayName = (fsData['name'] ??
                  widget.userData['name'] ??
                  user.displayName ??
                  (user.email?.split('@').first ?? 'Guest User'))
              .toString();

          final email =
              (fsData['email'] ?? widget.userData['email'] ?? user.email ?? 'No email provided')
                  .toString();

          final storedPhone = (fsData['phone'] ?? widget.userData['phone'] ?? '').toString();
          final phoneForUI =
              storedPhone.isEmpty ? 'Not provided' : _prettyPhone(storedPhone);

          final addressMap = (fsData['address'] as Map?)?.cast<String, dynamic>();
          final addressText =
              addressMap != null ? _formatAddress(addressMap) : (widget.userData['address'] ?? 'Not provided');

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFFEADCF0),
                    child: Icon(Icons.person, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 24),

                  // Phone (editable)
                  _infoCard(
                    icon: Icons.phone,
                    title: 'Mobile Number',
                    subtitle: phoneForUI,
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.red),
                      onPressed: () => _showEditPhoneDialog(storedPhone.isEmpty ? '' : storedPhone),
                    ),
                  ),

                  // Address — tap to add/update (opens AddLocationPage)
                  _infoCard(
                    icon: Icons.location_on,
                    title: 'Address',
                    subtitle: addressText,
                    showChevron: true,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddLocationPage()),
                      );
                    },
                  ),

                  _option(
                    icon: Icons.assignment,
                    title: 'My Orders',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FirebaseAuth.instance.currentUser != null
                              ? const OrdersPage()
                              : const LoginPage(),
                        ),
                      );
                    },
                  ),
                  _option(
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    onTap: () {},
                  ),
                  _option(
                    icon: Icons.logout,
                    title: 'Log Out',
                    onTap: () => _logout(context),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => _showDeleteAccountDialog(context),
                    child: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
