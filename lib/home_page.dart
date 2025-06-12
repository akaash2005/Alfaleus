import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'task_screen.dart';
import 'checklist_screen.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final String name;
  const HomePage({Key? key, required this.name}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pendingCount = 0;
  int completedCount = 0;
  List<Map<String, dynamic>> topTasks = [];
  String locationStatus = "OFF";
  String currentLocation = "Unknown";
  String userName = "Executive";
  String lastSync = "--:--";

  @override
  void initState() {
    super.initState();
    loadUserName();
    loadTaskCounts();
    loadTopTasks();
    checkLocation();
  }

  Future<void> loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId != null) {
        final userSnap = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        final data = userSnap.data();
        if (data != null && data['name'] != null) {
          setState(() {
            userName = data['name'];
          });
        }
      }
    } catch (_) {}
  }

  Future<void> loadTaskCounts() async {
    int pending = 0;
    int completed = 0;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

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

    setState(() {
      pendingCount = pending;
      completedCount = completed;
    });
  }

  Future<void> loadTopTasks() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final leadsSnap = await FirebaseFirestore.instance
        .collection('leads')
        .where('assignedTo', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('dueDate')
        .limit(2)
        .get();

    setState(() {
      topTasks = leadsSnap.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> checkLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final place = placemarks.first;
      setState(() {
        locationStatus = "ON";
        currentLocation = "${place.name}, ${place.locality}";
        final now = DateTime.now();
        lastSync = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      });
    } catch (_) {
      setState(() {
        locationStatus = "OFF";
        currentLocation = "Unknown";
      });
    }
  }

  String _timeLeft(Timestamp dueDate) {
    final now = DateTime.now();
    final due = dueDate.toDate();
    final diff = due.difference(now);
    if (diff.isNegative) return "Overdue";
    return "${diff.inHours}h ${diff.inMinutes % 60}m left";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome ! ${widget.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 45),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _countCard('Pending', pendingCount, 'Task for Today'),
                  _countCard('Completed', completedCount, 'Keep Going!'),
                ],
              ),
              const SizedBox(height: 35),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TaskScreen()));
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: const Color(0xFF2F80ED),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Complete Now", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Today's Tasks", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    for (var task in topTasks)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(task['title'] ?? 'New Task', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(task['description'] ?? 'No description', style: const TextStyle(color: Colors.black54)),
                                  const SizedBox(height: 4),
                                  Text(_timeLeft(task['dueDate']), style: const TextStyle(fontSize: 12, color: Colors.red)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEAF1FB),
                                foregroundColor: const Color(0xFF2F80ED),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('START'),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChecklistScreen()));
                      },
                      child: const Center(
                        child: Text("See All", style: TextStyle(color: Colors.blue)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Location Status'),
                        Text(locationStatus, style: TextStyle(color: locationStatus == 'ON' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                        Text('Last Sync: $lastSync', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current Location'),
                        Text(currentLocation, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
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
