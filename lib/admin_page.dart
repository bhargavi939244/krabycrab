import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  // ---- Menu form ----
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();

  // ---- Offers form ----
  final _offerFormKey = GlobalKey<FormState>();
  final TextEditingController _offerTitleCtrl = TextEditingController();
  final TextEditingController _offerDescCtrl = TextEditingController();
  final TextEditingController _offerPriceCtrl = TextEditingController();
  final TextEditingController _offerImageCtrl = TextEditingController();
  bool _offerActive = true;

  final List<String> _categories = [
    'Grab n Go Combos',
    'Snow Crab Deals',
    'Kraby sandwiches',
    'Add on Tiny Krabies',
    'Fried combos',
    'SOUP',
    'wings',
    'Blue Crab Meals',
  ];
  String? _selectedCategory;

  // ---- Orders filters ----
  String _statusFilter = 'ALL'; // ALL | pending | in progress | confirmed | completed | cancelled
  String _yearFilter = 'ALL';   // ALL | YYYY

  List<String> get _yearOptions {
    final nowY = DateTime.now().year;
    final years = <String>['ALL'];
    for (int y = 0; y < 6; y++) {
      years.add((nowY - y).toString());
    }
    return years;
  }

  Query _ordersQuery() {
    Query q = FirebaseFirestore.instance.collection('orders');

    if (_yearFilter != 'ALL') {
      final y = int.parse(_yearFilter);
      final start = DateTime(y, 1, 1);
      final end = DateTime(y + 1, 1, 1);
      q = q
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end));
    }

    if (_statusFilter != 'ALL') {
      q = q.where('status', isEqualTo: _statusFilter);
    }

    q = q.orderBy('createdAt', descending: true);
    return q;
  }

  // ---- Helpers ----
  Future<void> _sendOrderConfirmationEmail(String userEmail) async {
    debugPrint('Simulating email to $userEmail');
    debugPrint('Email: Your order has been confirmed and is on its way!');
  }

  Future<void> _updateOrderStatus(String orderDocId, String newStatus, String userEmail) async {
    final fs = FirebaseFirestore.instance;
    try {
      final snap = await fs.collection('orders').doc(orderDocId).get();
      final data = snap.data();
      final String? uid = data?['userId'] as String?;

      final batch = fs.batch();
      batch.update(fs.collection('orders').doc(orderDocId), {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (uid != null && uid.isNotEmpty) {
        batch.update(
          fs.collection('users').doc(uid).collection('orders').doc(orderDocId),
          {'status': newStatus, 'updatedAt': FieldValue.serverTimestamp()},
        );
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Order $orderDocId → $newStatus")),
        );
      }
      if (newStatus == 'In Progress') {
        final email = (data?['customer'] as Map?)?['email'] as String? ?? '';
        _sendOrderConfirmationEmail(email);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update order: $e")),
        );
      }
    }
  }

  // ---- MENU: add/delete ----
  Future<void> _addMenuItem() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance.collection('menuItems').add({
        'category': _selectedCategory,
        'title': _titleController.text.trim(),
        'desc': _descController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0, // USD
        'image': _imageController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      _descController.clear();
      _priceController.clear();
      _imageController.clear();
      setState(() => _selectedCategory = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu item added!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add item: $e')),
        );
      }
    }
  }

  Future<void> _deleteMenuItem(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('menuItems').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu item deleted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete item: $e')),
        );
      }
    }
  }

  // ---- OFFERS: add / toggle / delete ----
  Future<void> _addOffer() async {
    if (!_offerFormKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance.collection('offers').add({
        'title': _offerTitleCtrl.text.trim(),
        'desc': _offerDescCtrl.text.trim(),
        'price': double.tryParse(_offerPriceCtrl.text) ?? 0.0, // USD
        'image': _offerImageCtrl.text.trim(),
        'active': _offerActive,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _offerTitleCtrl.clear();
      _offerDescCtrl.clear();
      _offerPriceCtrl.clear();
      _offerImageCtrl.clear();
      setState(() => _offerActive = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer added!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add offer: $e')),
        );
      }
    }
  }

  Future<void> _toggleOfferActive(String id, bool newValue) async {
    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(id)
          .update({'active': newValue});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Offer ${newValue ? 'activated' : 'deactivated'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update offer: $e')),
        );
      }
    }
  }

  Future<void> _deleteOffer(String id) async {
    try {
      await FirebaseFirestore.instance.collection('offers').doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer deleted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete offer: $e')),
        );
      }
    }
  }

  // ---- misc helpers ----
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

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _imageController.dispose();

    _offerTitleCtrl.dispose();
    _offerDescCtrl.dispose();
    _offerPriceCtrl.dispose();
    _offerImageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // <-- increased (Orders, Menu, Dine-In, Offers)
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Dashboard"),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async => FirebaseAuth.instance.signOut(),
              tooltip: 'Logout',
            ),
          ],
          backgroundColor: Colors.red,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Orders"),
              Tab(text: "Menu"),
              Tab(text: "Dine-In"),
              Tab(text: "Offers"), // <-- new
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ================== ORDERS TAB ==================
            _OrdersTab(
              yearOptions: _yearOptions,
              yearFilter: _yearFilter,
              statusFilter: _statusFilter,
              onYearChanged: (v) => setState(() => _yearFilter = v),
              onStatusChanged: (v) => setState(() => _statusFilter = v),
              buildQuery: _ordersQuery,
              statusChip: _statusChip,
              totalUSDFromDoc: _totalUSDFromDoc,
              readDate: _readDate,
              onUpdateStatus: _updateOrderStatus,
            ),

            // ================== MENU TAB ==================
            _MenuTab(
              formKey: _formKey,
              categories: _categories,
              selectedCategory: _selectedCategory,
              onCategoryChanged: (v) => setState(() => _selectedCategory = v),
              titleController: _titleController,
              descController: _descController,
              priceController: _priceController,
              imageController: _imageController,
              onAddItem: _addMenuItem,
              onDeleteItem: _deleteMenuItem,
            ),

            // ================== DINE-IN TAB ==================
            const DineInReservationsTab(),

            // ================== OFFERS TAB (NEW) ==================
            _OffersTab(
              formKey: _offerFormKey,
              titleCtrl: _offerTitleCtrl,
              descCtrl: _offerDescCtrl,
              priceCtrl: _offerPriceCtrl,
              imageCtrl: _offerImageCtrl,
              active: _offerActive,
              onActiveChanged: (v) => setState(() => _offerActive = v),
              onAddOffer: _addOffer,
              onToggleActive: _toggleOfferActive,
              onDeleteOffer: _deleteOffer,
            ),
          ],
        ),
      ),
    );
  }
}

// ======= ORDERS TAB (same features you had: filters + badges) =======
class _OrdersTab extends StatelessWidget {
  final List<String> yearOptions;
  final String yearFilter;
  final String statusFilter;
  final ValueChanged<String> onYearChanged;
  final ValueChanged<String> onStatusChanged;
  final Query Function() buildQuery;
  final Widget Function(String status) statusChip;
  final double Function(Map<String, dynamic> data) totalUSDFromDoc;
  final DateTime Function(dynamic v) readDate;
  final Future<void> Function(String orderDocId, String newStatus, String userEmail)
      onUpdateStatus;

  const _OrdersTab({
    Key? key,
    required this.yearOptions,
    required this.yearFilter,
    required this.statusFilter,
    required this.onYearChanged,
    required this.onStatusChanged,
    required this.buildQuery,
    required this.statusChip,
    required this.totalUSDFromDoc,
    required this.readDate,
    required this.onUpdateStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(name: 'USD');

    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: statusFilter,
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
                  onChanged: (v) => onStatusChanged(v!),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<String>(
                  value: yearFilter,
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items:
                      yearOptions.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                  onChanged: (v) => onYearChanged(v!),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: buildQuery().snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No orders found."));
              }

              return ListView(
                children: snapshot.data!.docs.map((DocumentSnapshot doc) {
                  final data = doc.data()! as Map<String, dynamic>;

                  final displayId = (data['orderId'] as String?) ?? doc.id;
                  final total = totalUSDFromDoc(data);
                  final status = (data['status'] as String?) ?? 'pending';
                  final items = (data['items'] as List?) ?? const [];

                  final customer = (data['customer'] as Map?) ?? {};
                  final userName = (customer['name'] as String?) ?? 'N/A';
                  final userEmail = (customer['email'] as String?) ?? 'N/A';
                  final userPhone = (customer['phone'] as String?) ?? 'N/A';
                  final userAddress = (customer['address'] as String?) ?? 'N/A';

                  String paymentMethod = 'N/A';
                  final payment = data['payment'];
                  if (payment is Map) {
                    final m = payment['method'];
                    if (m is String) paymentMethod = m;
                  } else {
                    final m = data['paymentMethod'];
                    if (m is String) paymentMethod = m;
                  }

                  final orderedOn = readDate(data['createdAt']);
                  final orderedOnStr = DateFormat('MMM d, yyyy - h:mm a').format(orderedOn);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order ID: $displayId',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          statusChip(status),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Customer: $userName'),
                          Text('Total: ${currency.format(total)} (${items.length} items)'),
                          Text('Payment Method: ${paymentMethod.toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Ordered On: $orderedOnStr',
                              style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                      children: <Widget>[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Delivery Details',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Name: $userName'),
                              Text('Phone Number: $userPhone'),
                              Text('Email: $userEmail'),
                              Text('Address: $userAddress'),
                              const SizedBox(height: 16),
                              const Text('Order Items',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              ...items.map((it) {
                                final m = (it as Map?) ?? {};
                                final t = m['title'] ?? '';
                                final q = m['quantity'] ?? 1;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                                  child: Text('$t x $q',
                                      style: const TextStyle(fontSize: 16)),
                                );
                              }).toList(),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => onUpdateStatus(doc.id, 'In Progress', userEmail),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('In Progress'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => onUpdateStatus(doc.id, 'Completed', userEmail),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Completed'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ======= MENU TAB WIDGET =======
class _MenuTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final TextEditingController titleController;
  final TextEditingController descController;
  final TextEditingController priceController;
  final TextEditingController imageController;
  final VoidCallback onAddItem;
  final Function(String) onDeleteItem;

  const _MenuTab({
    Key? key,
    required this.formKey,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.titleController,
    required this.descController,
    required this.priceController,
    required this.imageController,
    required this.onAddItem,
    required this.onDeleteItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text('Add New Menu Item',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Form(
            key: formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories
                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: onCategoryChanged,
                  validator: (value) => value == null ? 'Please select a category' : null,
                ),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
                ),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (v) => v!.isEmpty ? 'Please enter a description' : null,
                ),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price (USD)'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v!.isEmpty || double.tryParse(v) == null ? 'Enter a valid price' : null,
                ),
                TextFormField(
                  controller: imageController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                  validator: (v) => v!.isEmpty ? 'Please enter an image URL' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onAddItem,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: const Text('Add Item'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text('Existing Menu Items',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('menuItems').orderBy('title').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) return Text('Error: ${snapshot.error}');
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('No menu items found.');
              }

              return ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Image.network(
                        data['image'] ?? 'https://via.placeholder.com/50',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                      ),
                      title: Text(data['title'] ?? 'No Title'),
                      subtitle: Text('Category: ${data['category']}\nPrice: \$${data['price']}'),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => onDeleteItem(doc.id),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ======= OFFERS TAB WIDGET (NEW) =======
class _OffersTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController imageCtrl;
  final bool active;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onAddOffer;
  final Future<void> Function(String id, bool newValue) onToggleActive;
  final Future<void> Function(String id) onDeleteOffer;

  const _OffersTab({
    Key? key,
    required this.formKey,
    required this.titleCtrl,
    required this.descCtrl,
    required this.priceCtrl,
    required this.imageCtrl,
    required this.active,
    required this.onActiveChanged,
    required this.onAddOffer,
    required this.onToggleActive,
    required this.onDeleteOffer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text('Add New Offer',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
                ),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (v) => v!.isEmpty ? 'Please enter a description' : null,
                ),
                TextFormField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Price (USD)'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v!.isEmpty || double.tryParse(v) == null ? 'Enter a valid price' : null,
                ),
                TextFormField(
                  controller: imageCtrl,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                  validator: (v) => v!.isEmpty ? 'Please enter an image URL' : null,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Active'),
                  value: active,
                  onChanged: onActiveChanged,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onAddOffer,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: const Text('Add Offer'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text('Existing Offers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('offers')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) return Text('Error: ${snapshot.error}');
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('No offers found.');
              }

              return ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final active = (data['active'] as bool?) ?? true;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Image.network(
                        data['image'] ?? 'https://via.placeholder.com/50',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                      ),
                      title: Text(data['title'] ?? 'No Title'),
                      subtitle: Text('Price: \$${(data['price'] ?? 0).toString()}'
                          '\nActive: ${active ? 'Yes' : 'No'}'),
                      isThreeLine: true,
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          Switch(
                            value: active,
                            onChanged: (v) => onToggleActive(doc.id, v),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => onDeleteOffer(doc.id),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ======= DINE-IN TAB (unchanged from your latest) =======
class DineInReservationsTab extends StatelessWidget {
  const DineInReservationsTab({super.key});

  Future<void> _updateReservationStatus(
      BuildContext context, String resId, String status) async {
    final fs = FirebaseFirestore.instance;

    try {
      final snap = await fs.collection('dieinOrders').doc(resId).get();
      final data = snap.data();
      final String? uid = data?['userId'] as String?;

      final batch = fs.batch();
      batch.update(fs.collection('dieinOrders').doc(resId), {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (uid != null && uid.isNotEmpty) {
        batch.update(
          fs.collection('users').doc(uid).collection('orders').doc(resId),
          {'status': status, 'updatedAt': FieldValue.serverTimestamp()},
        );
      }
      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reservation $resId → $status')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  Color _chipColor(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    const collectionPath = 'dieinOrders';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collectionPath)
          .orderBy('reservationTimestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No reservations submitted yet.'));
        }

        final reservations = snapshot.data!.docs;

        return ListView.builder(
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            final id = reservations[index].id;
            final r = reservations[index].data() as Map<String, dynamic>;
            final ts = r['reservationTimestamp'] as Timestamp?;
            final submittedTime =
                ts != null ? DateFormat('MMM d, yyyy - h:mm a').format(ts.toDate()) : 'N/A';
            final status = (r['status'] as String?) ?? 'pending';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${r['fullName']} - ${r['numberOfPersons']} Guests',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _chipColor(status).withOpacity(.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _chipColor(status).withOpacity(.4)),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _chipColor(status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Reservation Time: $submittedTime'),
                    Text('Phone: ${r['phoneNumber']}'),
                    Text('Email: ${r['emailAddress']}'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () =>
                              _updateReservationStatus(context, id, 'confirmed'),
                          child: const Text('Confirm'),
                        ),
                        TextButton(
                          onPressed: () =>
                              _updateReservationStatus(context, id, 'cancelled'),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
