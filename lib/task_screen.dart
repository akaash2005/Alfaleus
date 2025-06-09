import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'task_form_screen.dart';

class TaskScreen extends StatefulWidget {
  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  List<DocumentSnapshot> pendingTasks = [];
  List<DocumentSnapshot> completedTasks = [];
  Map<String, Map<String, String>> completedTaskForms = {};
  Map<String, bool> inProgress = {};
  Map<String, String> startLatLng = {};
  String view = 'pending';

  Map<String, Timer> taskTimers = {}; // One timer per task
  Map<String, double> finalLat = {};
  Map<String, double> finalLon = {};

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  @override
  void dispose() {
    for (var timer in taskTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  Future<void> fetchTasks() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('leads')
        .where('assignedTo', isEqualTo: uid)
        .get();

    final allTasks = snapshot.docs;
    setState(() {
      pendingTasks = allTasks.where((t) => t['status'] != 'completed').toList();
      completedTasks = allTasks.where((t) => t['status'] == 'completed').toList();
    });
  }

  Future<void> startTask(DocumentSnapshot task) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final taskId = task.id;
    if (inProgress[taskId] == true) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      final address = task['destinationAddress'];

      List<Location> locations = await locationFromAddress(address);
      finalLat[taskId] = locations.first.latitude;
      finalLon[taskId] = locations.first.longitude;

      await FirebaseFirestore.instance.collection('executive_locations').add({
        'uid': uid,
        'taskId': taskId,
        'isInitial': true,
        'start_latitude': position.latitude,
        'start_longitude': position.longitude,
        'executive_latitude': position.latitude,
        'executive_longitude': position.longitude,
        'final_latitude': finalLat[taskId],
        'final_longitude': finalLon[taskId],
        'timestamp': DateTime.now().toIso8601String(),
      });

      setState(() {
        inProgress[taskId] = true;
        startLatLng[taskId] = 'Lat: ${position.latitude}, Lon: ${position.longitude}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task started.')),
      );

      // Start interval updates (5 minutes)
      taskTimers[taskId] = Timer.periodic(Duration(minutes: 1), (_) async {
        final pos = await Geolocator.getCurrentPosition();
        await FirebaseFirestore.instance.collection('executive_locations').add({
          'uid': uid,
          'taskId': taskId,
          'executive_latitude': pos.latitude,
          'executive_longitude': pos.longitude,
          'final_latitude': finalLat[taskId],
          'final_longitude': finalLon[taskId],
          'timestamp': DateTime.now().toIso8601String(),  
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void navigateToFinishForm(DocumentSnapshot task) async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(taskId: task.id),
      ),
    );

    if (result != null) {
      await FirebaseFirestore.instance
          .collection('leads')
          .doc(task.id)
          .update({'status': 'completed'});

      // Cancel periodic update
      taskTimers[task.id]?.cancel();
      taskTimers.remove(task.id);

      setState(() {
        pendingTasks.removeWhere((t) => t.id == task.id);
        completedTasks.add(task);
        completedTaskForms[task.id] = result;
        inProgress.remove(task.id);
        startLatLng.remove(task.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTasks = view == 'pending' ? pendingTasks : completedTasks;

    return Scaffold(
      appBar: AppBar(title: Text('Tasks')),
      body: Column(
        children: [
          ToggleButtons(
            isSelected: [view == 'pending', view == 'completed'],
            onPressed: (index) {
              setState(() {
                view = index == 0 ? 'pending' : 'completed';
              });
            },
            children: [
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Pending')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Completed')),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: currentTasks.length,
              itemBuilder: (context, index) {
                final task = currentTasks[index];
                final taskId = task.id;

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ExpansionTile(
                    title: Text(task['title'] ?? 'No Title'),
                    subtitle: Text(task['description'] ?? ''),
                    children: [
                      Text("Priority: ${task['priority'] ?? 'N/A'}"),
                      Text("Due: ${task['dueDate'] ?? 'N/A'}"),
                      Text("Destination: ${task['destinationAddress'] ?? 'N/A'}"),
                      if (startLatLng.containsKey(taskId))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text("Start Location: ${startLatLng[taskId]}"),
                        ),
                      if (view == 'pending') ...[
                        ElevatedButton(
                          onPressed: inProgress[taskId] == true
                              ? null
                              : () => startTask(task),
                          child: Text(inProgress[taskId] == true ? 'In Progress' : 'Start Task'),
                        ),
                        if (inProgress[taskId] == true)
                          ElevatedButton(
                            onPressed: () => navigateToFinishForm(task),
                            child: Text('Finish Task'),
                          ),
                      ] else if (completedTaskForms.containsKey(taskId)) ...[
                        Divider(),
                        Text("Form Data:", style: TextStyle(fontWeight: FontWeight.bold)),
                        ...completedTaskForms[taskId]!.entries.map((entry) => Text('${entry.key}: ${entry.value}')),
                      ]
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
