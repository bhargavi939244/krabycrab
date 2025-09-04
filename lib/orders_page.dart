import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'cart_badge_icon.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  // Filters
  String _statusFilter = 'ALL'; // ALL | pending | in progress | confirmed | completed | cancelled
  String _yearFilter = 'ALL';   // ALL | 2025 | 2024 | ...

  // Build a year list: ALL + current year back to 5 years
  List<String> get _yearOptions {
    final nowY = DateTime.now().year;
    final years = <String>['ALL'];
    for (int y = 0; y < 5; y++) {
      years.add((nowY - y).toString());
    }
    return years;
  }

  Query _buildQuery(String uid) {
    final base = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('orders');

    // Year filter (server-side)
    if (_yearFilter != 'ALL') {
      final y = int.tryParse(_yearFilter)!;
      final start = DateTime(y, 1, 1);
      final end = DateTime(y + 1, 1, 1);
      return base
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end))
          .orderBy('createdAt', descending: true);
    }

    // No year filter
    return base.orderBy('createdAt', descending: true);
  }

  // ---------- helpers ----------
  DateTime _readDate(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) {
      final parsed = DateTime.tryParse(v);
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  double _totalUSDFromDoc(Map<String, dynamic> data) {
    final cents = data['totalCents'];
    if (cents is int) return cents / 100.0;
    final totalUSD = data['totalUSD'];
    if (totalUSD is num) return totalUSD.toDouble();
    return 0.0;
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return Colors.grey;
      case 'in progress':
        return Colors.blue;
      case 'confirmed':
        return Colors.teal;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _statusChip(String status) {
    final c = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }

  Future<void> _cancelOrder(
    BuildContext context, {
    required String uid,
    required String orderDocId,
    required bool isReservation,
  }) async {
    final fs = FirebaseFirestore.instance;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isReservation ? 'Cancel Reservation' : 'Cancel Order'),
        content: Text(isReservation
            ? 'Do you want to cancel this reservation?'
            : 'Do you want to cancel this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );
    if (ok != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final batch = fs.batch();
      final userRef = fs.collection('users').doc(uid).collection('orders').doc(orderDocId);
      batch.update(userRef, {'status': 'cancelled', 'updatedAt': FieldValue.serverTimestamp()});

      if (isReservation) {
        batch.update(fs.collection('dieinOrders').doc(orderDocId),
            {'status': 'cancelled', 'updatedAt': FieldValue.serverTimestamp()});
      } else {
        batch.update(fs.collection('orders').doc(orderDocId),
            {'status': 'cancelled', 'updatedAt': FieldValue.serverTimestamp()});
      }

      await batch.commit();
      if (context.mounted) Navigator.of(context).pop(); // spinner
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isReservation ? 'Reservation cancelled.' : 'Order cancelled.')),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to cancel: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Orders'), backgroundColor: Colors.red),
        body: const Center(child: Text('Please log in to view your orders.')),
      );
    }

    final currencyFormat = NumberFormat.simpleCurrency(name: 'USD');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.red,
        actions: const [CartBadgeIcon()],
      ),
      body: Column(
        children: [
          // Filters row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('All')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'in progress', child: Text('In Progress')),
                      DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (v) => setState(() => _statusFilter = v!),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<String>(
                    value: _yearFilter,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: _yearOptions
                        .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                        .toList(),
                    onChanged: (v) => setState(() => _yearFilter = v!),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Stream + list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery(uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No orders found.'));
                }

                // Client-side filter by status to avoid composite indexes
                final filteredDocs = snapshot.data!.docs.where((d) {
                  if (_statusFilter == 'ALL') return true;
                  final s = ((d.data() as Map<String, dynamic>)['status'] ?? '').toString().toLowerCase();
                  return s == _statusFilter;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('No orders match your filters.'));
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final docId = doc.id;
                    final displayId = (data['orderId'] as String?) ?? docId;
                    final total = _totalUSDFromDoc(data);
                    final status = (data['status'] as String?) ?? 'pending';
                    final orderedOn = _readDate(data['createdAt']);
                    final orderedOnStr = DateFormat('MMM d, yyyy - h:mm a').format(orderedOn);
                    final items = (data['items'] as List?) ?? const [];

                    final bool isReservation =
                        (data['type'] == 'reservation') || data.containsKey('reservationTimestamp');
                    final int persons = (data['numberOfPersons'] as int?) ?? 0;
                    final DateTime resTime = _readDate(data['reservationTimestamp']);
                    final String resTimeStr = DateFormat('MMM d, yyyy - h:mm a').format(resTime);

                    String paymentMethod = 'N/A';
                    if (!isReservation) {
                      final payment = data['payment'];
                      if (payment is Map && payment['method'] is String) {
                        paymentMethod = (payment['method'] as String);
                      } else if (data['paymentMethod'] is String) {
                        paymentMethod = data['paymentMethod'];
                      }
                    }
                    final methodUp = paymentMethod.toUpperCase();
                    final methodColor = methodUp == 'COD' ? Colors.green : Colors.blue;

                    final canCancel = status != 'completed' && status != 'cancelled';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Order ID: $displayId',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            _statusChip(status),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total: ${currencyFormat.format(total)}'),
                            if (!isReservation)
                              Text('Payment Method: $methodUp',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, color: methodColor)),
                            if (isReservation)
                              Text('Reservation: $resTimeStr • $persons person(s)',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('Ordered On: $orderedOnStr',
                                style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                        children: [
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Order Items:',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                if (items.isEmpty && isReservation)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8.0, left: 8.0),
                                    child: Text('Dine-in reservation (no items)'),
                                  )
                                else
                                  ...items.map((it) {
                                    final m = (it as Map?) ?? {};
                                    final title = m['title'] ?? '';
                                    final qty = m['quantity'] ?? 1;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                                      child: Text('$title x $qty',
                                          style: const TextStyle(fontSize: 16)),
                                    );
                                  }).toList(),
                                if (canCancel)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      icon: const Icon(Icons.cancel),
                                      label: Text(isReservation
                                          ? 'Cancel Reservation'
                                          : 'Cancel Order'),
                                      onPressed: () => _cancelOrder(
                                        context,
                                        uid: uid,
                                        orderDocId: docId,
                                        isReservation: isReservation,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
