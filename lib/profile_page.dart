import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  final String userEmail;

  const ProfilePage({Key? key, required this.userEmail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Colors.red,
        actions: user != null
            ? [
                IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => LoginPage()),
                    );
                  },
                )
              ]
            : [],
      ),
      body: user == null
          ? Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                  );
                },
                child: Text("Login / Sign Up"),
              ),
            )
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.email)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final userData =
                    snapshot.data!.data() as Map<String, dynamic>?;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Name: ${userData?['name'] ?? 'Not set'}",
                          style: TextStyle(fontSize: 18)),
                      SizedBox(height: 10),
                      Text("Email: ${user.email}",
                          style: TextStyle(fontSize: 18)),
                      SizedBox(height: 10),
                      Text("Phone: ${userData?['phone'] ?? 'Not set'}",
                          style: TextStyle(fontSize: 18)),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Optional: Implement editing user details
                        },
                        child: Text("Edit Profile"),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
