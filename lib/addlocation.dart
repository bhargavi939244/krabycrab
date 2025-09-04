// lib/add_location_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_badge_icon.dart';

class AddLocationPage extends StatefulWidget {
  const AddLocationPage({Key? key}) : super(key: key);

  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final _formKey = GlobalKey<FormState>();

  final _streetCtrl  = TextEditingController();
  final _cityCtrl    = TextEditingController();
  final _stateCtrl   = TextEditingController();
  final _zipCtrl     = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'United States');

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prefillIfAny();
  }

  @override
  void dispose() {
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _prefillIfAny() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!snap.exists) {
      // force to United States even if nothing yet
      _countryCtrl.text = 'United States';
      if (mounted) setState(() {});
      return;
    }

    final data = snap.data() as Map<String, dynamic>;
    final addr = (data['address'] as Map?) ?? {};

    _streetCtrl.text  = (addr['street']  ?? '') as String;
    _cityCtrl.text    = (addr['city']    ?? '') as String;
    _stateCtrl.text   = (addr['state']   ?? '') as String;
    _zipCtrl.text     = (addr['pincode'] ?? '') as String;

    // lock to United States regardless of existing value
    _countryCtrl.text = 'United States';

    if (mounted) setState(() {});
  }

  String? _usaZipError(String zipRaw) {
    final zip = zipRaw.trim();
    if (zip.isEmpty) return 'Please enter ZIP code';
    final rx = RegExp(r'^\d{5}(-\d{4})?$'); // 12345 or 12345-6789
    if (!rx.hasMatch(zip)) return 'Enter ZIP like 12345 or 12345-6789';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'address': {
          'street':  _streetCtrl.text.trim(),
          'city':    _cityCtrl.text.trim(),
          'state':   _stateCtrl.text.trim(),
          'pincode': _zipCtrl.text.trim(),     // stored as pincode field (ZIP)
          'country': 'United States',          // force US
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location saved')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _input(
    String label, {
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator ??
            (v) => (v == null || v.trim().isEmpty) ? 'Please enter $label' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final btnChild = _saving
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
        : const Text('Save Location');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Location"),
        backgroundColor: Colors.red,
        actions: const [CartBadgeIcon()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _input('Street', controller: _streetCtrl),
              _input('City', controller: _cityCtrl),
              _input('State', controller: _stateCtrl),
              _input(
                'ZIP Code',
                controller: _zipCtrl,
                // allow digits and optional hyphen
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))],
                validator: (v) => _usaZipError(v ?? ''),
              ),
              _input(
                'Country',
                controller: _countryCtrl,
                enabled: false, // locked to United States
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: btnChild,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
