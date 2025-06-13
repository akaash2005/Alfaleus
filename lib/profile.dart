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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 16))),
          const SizedBox(width: 20),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
        ],
      ),
    );
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xF6F6F6),
            height: 1,
          ),
        ),
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

              return Column(
                children: [
                  const SizedBox(height: 24),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFFF2F2F2),
                    child: Text(
                      initials,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(name,
                      style:
                          const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 30),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _infoRow("Role", role),
                        _infoRow("Mail", email),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(child: _countCard('Pending', pending, 'Tasks')),
                        const SizedBox(width: 16),
                        Expanded(child: _countCard('Completed', completed, 'Done')),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () => _signOut(context),
                        child: const Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _countCard(String title, int count, String subtitle) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 8),
          Text('$count', style: const TextStyle(fontSize: 20)),
          Text(subtitle, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
