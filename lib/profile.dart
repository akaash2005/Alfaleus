import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart'; 
import 'package:flutter/cupertino.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _signOut(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginSignupScreen()),
    );
  }

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!snapshot.exists) return null;

    return snapshot.data();
  }

  Future<Map<String, int>> _fetchTaskCounts(String userId) async {
    int pending = 0;
    int completed = 0;

    final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return {'pending': 0, 'completed': 0};

      final querySnapshot = await FirebaseFirestore.instance
    .collection('leads')
    .where('assignedTo', isEqualTo: uid)
    .get();

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      if (data['status'] == 'pending') {
        pending++;
      } else if (data['status'] == 'completed') {
        completed++;
      }
    }

    return {'pending': pending, 'completed': completed};
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final words = name.trim().split(RegExp(r'\s+'));
    return words.map((w) => w[0].toUpperCase()).take(2).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('User data not found.'));
          }

          final userData = snapshot.data!;
          final uid = FirebaseAuth.instance.currentUser?.uid;
          final name = userData['name'] ?? 'N/A';
          final email = userData['email'] ?? 'N/A';
          final role = userData['role'] ?? 'N/A';
          final initials = _getInitials(name);

          return FutureBuilder<Map<String, int>>(
            future: _fetchTaskCounts(uid!),
            builder: (context, taskSnap) {
              final pending = taskSnap.data?['pending'] ?? 0;
              final completed = taskSnap.data?['completed'] ?? 0;

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xF7F7F7F7),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Role: $role',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _countCard('Pending', pending, 'Tasks'),
                          _countCard('Completed', completed, 'Done'),
                        ],
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          color: const Color(0xF7F7F7F7),
                          borderRadius: BorderRadius.circular(12),
                          onPressed: () => _signOut(context),
                          child: const Text(
                            'Sign Out',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _countCard(String title, int count, String subtitle) {
    return Container(
      width: 150,
      height: 125,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFE0E0E0), width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('$count', style: const TextStyle(fontSize: 20)),
          Text(subtitle, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
