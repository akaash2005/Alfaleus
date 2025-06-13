import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'task_screen.dart';

class HomePage extends StatefulWidget {
  final String name;
  const HomePage({Key? key, required this.name}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pendingCount = 0;
  int completedCount = 0;
  List<Map<String, dynamic>> userTasks = [];
  String locationStatus = "OFF";
  String currentLocation = "Unknown";
  String lastSync = "--:--";

  @override
  void initState() {
    super.initState();
    loadTaskCounts();
    loadUserTasks();
    checkLocation();
  }

  Future<void> loadTaskCounts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('leads')
        .where('assignedTo', isEqualTo: uid)
        .get();

    int pend = 0, comp = 0;
    for (var doc in snap.docs) {
      final status = (doc['status'] ?? '').toString().toLowerCase();
      if (status == 'pending') pend++;
      if (status == 'completed') comp++;
    }

    setState(() {
      pendingCount = pend;
      completedCount = comp;
    });
  }

  Future<void> loadUserTasks() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('leads')
        .where('assignedTo', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('dueDate')
        .get();

    setState(() {
      userTasks = snap.docs.map((d) => d.data()).toList().cast<Map<String, dynamic>>();
    });
  }

  Future<void> checkLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      final place = (await placemarkFromCoordinates(pos.latitude, pos.longitude)).first;
      final now = DateTime.now();
      setState(() {
        locationStatus = "ON";
        currentLocation = "${place.name}, ${place.locality}";
        lastSync = DateFormat.Hm().format(now);
      });
    } catch (_) {
      setState(() {
        locationStatus = "OFF";
        currentLocation = "Unknown";
      });
    }
  }

  String _timeLeft(Timestamp dueDate) {
    final diff = dueDate.toDate().difference(DateTime.now());
    if (diff.isNegative) return "Overdue";
    return "${diff.inHours}h ${diff.inMinutes % 60}m left";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await loadTaskCounts();
            await loadUserTasks();
            await checkLocation();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, ${widget.name}!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 35),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _countCard('Pending', pendingCount, 'Tasks waiting'),
                    _countCard('Completed', completedCount, 'Keep it up!'),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskScreen())),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: const Color(0xFF2F80ED),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Complete Now", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 24),
                if (userTasks.isNotEmpty)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Your Tasks", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        for (var task in userTasks)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(task['title'] ?? 'No title', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(task['description'] ?? '', style: const TextStyle(color: Colors.black54)),
                                      const SizedBox(height: 4),
                                      if (task['dueDate'] != null)
                                        Text(_timeLeft(task['dueDate']), style: const TextStyle(fontSize: 12, color: Colors.red)),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => TaskScreen()));
                                  },
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
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => TaskScreen()));
                            },
                            child: const Text("See All", style: TextStyle(color: Colors.blue)),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
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
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('$count', style: const TextStyle(fontSize: 20)),
        Text(subtitle, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }
}
