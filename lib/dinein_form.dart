import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

final Uuid uuid = Uuid();

class DineInForm extends StatefulWidget {
  const DineInForm({Key? key}) : super(key: key);

  @override
  _DineInFormState createState() => _DineInFormState();
}

class _DineInFormState extends State<DineInForm> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _phone = '';
  String _email = '';
  int _numberOfPersons = 1;
  DateTime _reservationDay = DateTime.now();
  TimeOfDay _reservationTime = const TimeOfDay(hour: 12, minute: 0);

  // ---- Firestore writes (Admin + My Orders) ----
  Future<void> _sendDataToAdminAndUser(Map<String, dynamic> dineInDetails) async {
    final fs = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    // Use same id for both places so they correlate
    final String resId = uuid.v4();

    final adminRef = fs.collection('dieinOrders').doc(resId);
    final FieldValue nowServer = FieldValue.serverTimestamp();

    // Doc for Admin → Dine-In tab (matches your Admin reader)
    final adminData = {
      ...dineInDetails,                          // fullName, phoneNumber, emailAddress, numberOfPersons, reservationTimestamp
      'reservationId': resId,
      'status': 'pending',
      'userId': user?.uid,
      'submittedAt': nowServer,
    };

    final batch = fs.batch();
    batch.set(adminRef, adminData);

    // Also add a copy to user's My Orders if signed in
    if (user != null) {
      final userOrderRef = fs
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .doc(resId);

      final userOrderData = {
        'orderId': resId.substring(0, 8),        // short display id
        'orderDocId': resId,
        'userId': user.uid,
        'customer': {
          'name': _name,
          'phone': _phone,
          'email': _email,
          'address': 'Dine-in at restaurant',
        },
        // Reservation-specific fields so My Orders can show details
        'type': 'reservation',
        'reservationTimestamp': dineInDetails['reservationTimestamp'],
        'numberOfPersons': _numberOfPersons,

        // Keep schema compatible with orders list
        'items': const <Map<String, dynamic>>[],
        'totalUSD': 0.0,
        'totalCents': 0,
        'currency': 'USD',
        'payment': {'method': 'RESERVATION', 'status': 'n/a'},
        'status': 'pending',
        'createdAt': nowServer,
      };

      batch.set(userOrderRef, userOrderData);
    }

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user == null
                ? 'Reservation submitted! (Sign in to see it in My Orders)'
                : 'Reservation submitted!',
          ),
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _reservationDay,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _reservationDay) {
      setState(() => _reservationDay = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reservationTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (picked.hour >= 10 && picked.hour <= 23) {
        setState(() => _reservationTime = picked);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a time between 10:00 AM and 11:00 PM.')),
        );
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Combine day + time
      final DateTime reservationDateTime = DateTime(
        _reservationDay.year,
        _reservationDay.month,
        _reservationDay.day,
        _reservationTime.hour,
        _reservationTime.minute,
      );

      final Map<String, dynamic> dineInDetails = {
        'fullName': _name,
        'phoneNumber': _phone,
        'emailAddress': _email,
        'numberOfPersons': _numberOfPersons,
        'reservationTimestamp': Timestamp.fromDate(reservationDateTime),
      };

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Reservation Confirmed'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Name: ${dineInDetails['fullName']}'),
                  Text('Phone: ${dineInDetails['phoneNumber']}'),
                  Text('Email: ${dineInDetails['emailAddress']}'),
                  Text('Persons: ${dineInDetails['numberOfPersons']}'),
                  Text('Date: ${DateFormat('yyyy-MM-dd').format(reservationDateTime)}'),
                  Text('Time: ${DateFormat('h:mm a').format(reservationDateTime)}'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () async {
                  Navigator.of(context).pop(); // close dialog

                  // Write to Admin + My Orders
                  await _sendDataToAdminAndUser(dineInDetails);

                  if (mounted) Navigator.of(context).pop(); // back to previous page
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dine-in Reservation'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter your name' : null,
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter your phone number' : null,
                onSaved: (value) => _phone = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your email';
                  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
                  return ok ? null : 'Please enter a valid email';
                },
                onSaved: (value) => _email = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Number of Persons',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                keyboardType: TextInputType.number,
                initialValue: '1',
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter number of persons';
                  final n = int.tryParse(value);
                  if (n == null || n <= 0) return 'Please enter a valid number';
                  return null;
                },
                onSaved: (value) => _numberOfPersons = int.parse(value!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Reservation Day: ${DateFormat('yyyy-MM-dd').format(_reservationDay)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  ElevatedButton(onPressed: () => _selectDate(context), child: const Text('Select Date')),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Reservation Time: ${_reservationTime.format(context)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  ElevatedButton(onPressed: () => _selectTime(context), child: const Text('Select Time')),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Book Now', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
