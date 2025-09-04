import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'checkout_page.dart';

class UserDetailsPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalPriceUSD;

  const UserDetailsPage({
    Key? key,
    required this.cartItems,
    required this.totalPriceUSD,
  }) : super(key: key);

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController(); // single-line address

  bool _loadingSaved = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  String _formatAddress(Map<String, dynamic>? addr) {
    if (addr == null || addr.isEmpty) return '';
    final parts = <String>[
      (addr['street'] ?? '').toString(),
      (addr['city'] ?? '').toString(),
      (addr['state'] ?? '').toString(),
      (addr['pincode'] ?? '').toString(),
      (addr['country'] ?? '').toString(),
    ].where((s) => s.trim().isNotEmpty);
    return parts.join(', ');
  }

  Future<void> _useSavedDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to load saved details.')),
      );
      return;
    }
    setState(() => _loadingSaved = true);
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        _emailCtrl.text = user.email ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No saved details found.')),
        );
        return;
      }
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? user.displayName ?? '').toString();
      final email = (data['email'] ?? user.email ?? '').toString();
      final phone = (data['phone'] ?? '').toString();
      final addrMap = (data['address'] as Map?)?.cast<String, dynamic>();
      final addr = _formatAddress(addrMap);

      setState(() {
        if (name.isNotEmpty) _nameCtrl.text = name;
        if (email.isNotEmpty) _emailCtrl.text = email;
        if (phone.isNotEmpty) _phoneCtrl.text = phone;
        if (addr.isNotEmpty) _addressCtrl.text = addr;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved details applied')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load saved details: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingSaved = false);
    }
  }

  String? _required(String? v, String field) {
    if (v == null || v.trim().isEmpty) return 'Please enter your $field';
    return null;
  }

  String? _validateEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Please enter your email';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(s);
    return ok ? null : 'Enter a valid email';
  }

  String? _validatePhone(String? v) {
    final s = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (s.isEmpty) return 'Please enter your phone number';
    if (s.length == 10) return null; // US 10-digit
    if (s.length == 11 && s.startsWith('1')) return null; // 1 + 10
    return 'Enter a valid US phone number';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("Enter Delivery Details"), backgroundColor: Colors.red),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: _loadingSaved
                          ? const SizedBox(
                              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.person_pin_circle_outlined),
                      label: const Text('Use saved details'),
                      onPressed: _loadingSaved ? null : _useSavedDetails,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: (v) => _required(v, 'name'),
              ),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
              ),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: "Address"),
                maxLines: 2,
                validator: (v) => _required(v, 'address'),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text("Proceed to Checkout"),
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;

                  Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CheckoutPage(
      cartItems: widget.cartItems,
      totalPriceUSD: widget.totalPriceUSD,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      // For Delivery:
      address: _addressCtrl.text.trim(),
      orderType: OrderType.delivery, // <--- ADD THIS
      // For Takeaway, you would pass:
      // selectedStore: selectedStoreName,
      // orderType: OrderType.takeaway,
    ),
  ),
);

                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
