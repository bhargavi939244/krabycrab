// lib/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'homepage.dart';
import 'menu_page.dart';
import 'global.dart' as globals;

enum PaymentMethod { cod, card }
enum OrderType { delivery, takeaway }

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalPriceUSD;

  // keep these final (props), we’ll edit copies in State
  final String name;
  final String phone;
  final String email;
  final String? address;          // optional for takeaway
  final String? selectedStore;    // only for takeaway
  final OrderType orderType;

  const CheckoutPage({
    Key? key,
    required this.cartItems,
    required this.totalPriceUSD,
    required this.name,
    required this.phone,
    required this.email,
    this.address,
    this.selectedStore,
    required this.orderType,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _currency = NumberFormat.simpleCurrency(name: 'USD');
  PaymentMethod _method = PaymentMethod.cod;
  bool _placing = false;

  // Editable copies of the user details (fix for “can’t assign to final”)
  late String _name;
  late String _email;
  late String _phone;
  String? _address; // only relevant for delivery

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _email = widget.email;
    _phone = widget.phone;
    _address = widget.address;
  }

  // ---------- Edit bottom sheet ----------
  Future<void> _showEditDetailsSheet() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl  = TextEditingController(text: _name);
    final emailCtrl = TextEditingController(text: _email);
    final phoneCtrl = TextEditingController(text: _phone);
    final addrCtrl  = TextEditingController(text: _address);

    String? requiredField(String? v, String field) {
      if (v == null || v.trim().isEmpty) return 'Please enter your $field';
      return null;
    }

    String? validateEmail(String? v) {
      final s = (v ?? '').trim();
      if (s.isEmpty) return 'Please enter your email';
      final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(s);
      return ok ? null : 'Enter a valid email';
    }

    String? validatePhone(String? v) {
      final s = (v ?? '').replaceAll(RegExp(r'\D'), '');
      if (s.isEmpty) return 'Please enter your phone number';
      if (s.length == 10) return null;
      if (s.length == 11 && s.startsWith('1')) return null;
      return 'Enter a valid US phone number';
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Text(
                  widget.orderType == OrderType.delivery
                      ? 'Edit Delivery Details'
                      : 'Edit Takeaway Details',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => requiredField(v, 'name'),
                ),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: validateEmail,
                ),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  validator: validatePhone,
                ),
                if (widget.orderType == OrderType.delivery)
                  TextFormField(
                    controller: addrCtrl,
                    decoration: const InputDecoration(labelText: 'Address'),
                    maxLines: 2,
                    validator: (v) => requiredField(v, 'address'),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, foregroundColor: Colors.white),
                    child: const Text('Save'),
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      setState(() {
                        _name = nameCtrl.text.trim();
                        _email = emailCtrl.text.trim();
                        _phone = phoneCtrl.text.trim();
                        if (widget.orderType == OrderType.delivery) {
                          _address = addrCtrl.text.trim();
                        }
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- Mock card sheet ----------
  Future<Map<String, dynamic>?> _showMockCardSheet() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    final expCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();

    String? req(String? v, String f) {
      if (v == null || v.trim().isEmpty) return 'Enter $f';
      return null;
    }

    String? cardNum(String? v) {
      final s = (v ?? '').replaceAll(RegExp(r'\s'), '');
      if (s.length < 12 || s.length > 19) return 'Enter a valid card number';
      return null;
    }

    String? exp(String? v) {
      final s = (v ?? '').trim();
      if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(s)) return 'MM/YY';
      return null;
    }

    String? cvv(String? v) {
      final s = (v ?? '').trim();
      if (s.length < 3 || s.length > 4) return '3–4 digits';
      return null;
    }

    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const Text('Card Payment (Mock)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name on card'),
                  validator: (v) => req(v, 'name'),
                ),
                TextFormField(
                  controller: numberCtrl,
                  decoration: const InputDecoration(labelText: 'Card number'),
                  keyboardType: TextInputType.number,
                  validator: cardNum,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: expCtrl,
                        decoration: const InputDecoration(labelText: 'MM/YY'),
                        keyboardType: TextInputType.datetime,
                        validator: exp,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: cvvCtrl,
                        decoration: const InputDecoration(labelText: 'CVV'),
                        keyboardType: TextInputType.number,
                        validator: cvv,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final cleaned = numberCtrl.text.trim().replaceAll(' ', '');
                      Navigator.pop<Map<String, dynamic>>(ctx, {
                        'last4': cleaned.substring((cleaned.length - 4).clamp(0, cleaned.length)),
                        'brand': 'VISA', // mock
                      });
                    },
                    child: const Text('Pay'),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- Place order (Firestore) ----------
  Future<void> _placeOrder() async {
    if (_placing) return;
    setState(() => _placing = true);

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'guest';

    Map<String, dynamic> payment = {
      'method': _method == PaymentMethod.cod ? 'cod' : 'card',
      'status': _method == PaymentMethod.cod ? 'pending' : 'paid',
      'txnId': null,
    };

    if (_method == PaymentMethod.card) {
      final res = await _showMockCardSheet();
      if (res == null) {
        setState(() => _placing = false);
        return; // cancelled
      }
      payment['txnId'] = 'MOCK-${DateTime.now().millisecondsSinceEpoch}';
      payment['card'] = {'brand': res['brand'], 'last4': res['last4']};
    }

    final items = widget.cartItems.map((e) {
      return {
        'title': (e['title'] ?? e['name'] ?? 'Item').toString(),
        'quantity': (e['quantity'] is int) ? e['quantity'] : 1,
        'priceUSD': (e['priceUSD'] is num) ? (e['priceUSD'] as num).toDouble() : 0.0,
        'image': e['image'],
        if (e['isOffer'] == true) 'isOffer': true,
      };
    }).toList();

    final orderDoc = {
      'userId': uid,
      'items': items,
      'totalUSD': widget.totalPriceUSD,
      'status': 'pending',
      'payment': payment,
      'customer': {
        'name': _name,
        'phone': _phone,
        'email': _email,
        if (widget.orderType == OrderType.delivery) 'address': _address,
        if (widget.orderType == OrderType.takeaway) 'store': widget.selectedStore,
      },
      'orderType': widget.orderType.toString().split('.').last,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      final fs = FirebaseFirestore.instance;
      final ref = await fs.collection('orders').add(orderDoc);
      final orderId = ref.id;

      if (uid != 'guest') {
        await fs
            .collection('users')
            .doc(uid)
            .collection('orders')
            .doc(orderId)
            .set(orderDoc);
      }

      if (!mounted) return;

      // Clear cart and badge
      globals.cartItems.clear();
      globals.cartItemCount.value = 0;

      // Success dialog → go to Menu
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(_method == PaymentMethod.cod
              ? 'Order Placed (COD)'
              : 'Payment Successful'),
          content: Text(_method == PaymentMethod.cod
              ? 'Your order has been placed. Pay cash on delivery.'
              : 'Your payment has been processed successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MenuPage()),
                  (route) => false,
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.cartItems;

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout"), backgroundColor: Colors.red),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Order Summary ----------
            const Text("Order Summary",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  var item = items[index];
                  final title = (item['title'] ?? item['name'] ?? 'Item') as String;
                  final price = (item['priceUSD'] is num)
                      ? (item['priceUSD'] as num).toDouble()
                      : 0.0;
                  final qty = (item['quantity'] is int) ? item['quantity'] as int : 1;
                  return ListTile(
                    title: Text(title),
                    subtitle: Text("\$${price.toStringAsFixed(2)} x $qty"),
                    trailing: Text(
                      _currency.format(price * qty),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            const Divider(),

            // ---------- Delivery / Takeaway details ----------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    widget.orderType == OrderType.delivery ? "Deliver to:" : "Pickup at:",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    widget.orderType == OrderType.delivery
                        ? '$_name\n$_email\n$_phone\n${_address ?? ""}'
                        : 'Store: ${widget.selectedStore ?? ""}\n$_name\n$_email\n$_phone',
                  ),
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit, color: Colors.red),
                  onPressed: _showEditDetailsSheet,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ---------- Payment Method ----------
            const Text("Payment Method",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            RadioListTile<PaymentMethod>(
              value: PaymentMethod.cod,
              groupValue: _method,
              onChanged: (v) => setState(() => _method = v!),
              title: const Text('Cash on Delivery'),
              subtitle: const Text('Pay with cash when your order arrives'),
            ),
            RadioListTile<PaymentMethod>(
              value: PaymentMethod.card,
              groupValue: _method,
              onChanged: (v) => setState(() => _method = v!),
              title: const Text('Credit / Debit Card'),
              subtitle: const Text('Mock payment for now'),
            ),
            const SizedBox(height: 6),

            // ---------- Total + Place Order ----------
            Row(
              children: [
                const Expanded(
                  child: Text('Total',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                Text(
                  _currency.format(widget.totalPriceUSD),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _method == PaymentMethod.card ? Colors.green : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _placing ? null : _placeOrder,
                child: _placing
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_method == PaymentMethod.card ? 'Pay Now' : 'Place Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
