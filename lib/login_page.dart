import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage  extends StatefulWidget {
  const LoginPage ({Key? key}) : super(key: key);

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<LoginPage > {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLogin = true; // toggle between login & signup
  bool loading = false;

  String email = '';
  String password = '';
  String name = '';
  String phone = '';

  void _toggleMode() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => loading = true);

    try {
      if (isLogin) {
        // LOGIN
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      } else {
        // SIGNUP
        UserCredential userCred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Store extra info in Firestore
        await _firestore.collection('users').doc(userCred.user!.uid).set({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password, // ❗ storing plain passwords is not secure
        });
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Authentication failed')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Signup'),
      backgroundColor: Colors.red),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (!isLogin)
                      TextFormField(
                        key: const ValueKey('name'),
                        decoration: const InputDecoration(labelText: 'Name'),
                        onSaved: (val) => name = val!.trim(),
                        validator: (val) =>
                            val!.isEmpty ? 'Enter your name' : null,
                      ),
                    if (!isLogin)
                      TextFormField(
                        key: const ValueKey('phone'),
                        decoration: const InputDecoration(labelText: 'Phone'),
                        onSaved: (val) => phone = val!.trim(),
                        validator: (val) =>
                            val!.isEmpty ? 'Enter your phone number' : null,
                      ),
                    TextFormField(
                      key: const ValueKey('email'),
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      onSaved: (val) => email = val!.trim(),
                      validator: (val) =>
                          val!.contains('@') ? null : 'Enter valid email',
                    ),
                    TextFormField(
                      key: const ValueKey('password'),
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      onSaved: (val) => password = val!.trim(),
                      validator: (val) =>
                          val!.length < 6 ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 20),
                    if (loading) const CircularProgressIndicator(),
                    if (!loading)
                      ElevatedButton(
                        onPressed: _submit,
                        child: Text(isLogin ? 'Login' : 'Signup'),
                      ),
                    TextButton(
                      onPressed: _toggleMode,
                      child: Text(isLogin
                          ? 'Create new account'
                          : 'Already have an account? Login'),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
