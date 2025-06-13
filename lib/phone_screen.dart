import 'package:flutter/material.dart';
import 'package:phone_state/phone_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneScreen extends StatefulWidget {
  final String name;
  const PhoneScreen({Key? key, required this.name}) : super(key: key);

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  PhoneStateStatus status = PhoneStateStatus.NOTHING;
  String number = "Unknown";
  bool isInCall = false;
  DateTime? callStart;

  @override
  void initState() {
    super.initState();
    listenToCall();
    
  }

  void listenToCall() {
    PhoneState.stream.listen((event) {
      setState(() {
        status = event.status;
        if (event.number != null &&
            event.number!.isNotEmpty &&
            event.number != "Unknown") {
          number = event.number!;
        }
      });
    
      if (status == PhoneStateStatus.CALL_STARTED && !isInCall) {
        isInCall = true;
        callStart = DateTime.now();
      }

      if (status == PhoneStateStatus.CALL_ENDED && isInCall) {
        isInCall = false;
        final callEnd = DateTime.now();
        final duration = callEnd.difference(callStart ?? callEnd).inSeconds;

        String callType = duration == 0 ? 'missed' : 'outgoing';

        
      
        if (number != "Unknown") {
          FirebaseFirestore.instance.collection('call_logs').add({
            'number': number,
            'start_time': callStart?.toIso8601String(),
            'end_time': callEnd.toIso8601String(),
            'duration_seconds': duration,
            'type': callType,
            'name': widget.name,
          });
        }

        callStart = null;
        number = "Unknown";
      }
    });
  }

  String formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "00:$minutes:$secs";
  }

  void showCallDetails(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (_) {
        final date = DateFormat('MMM d, yyyy – hh:mm a')
            .format(DateTime.parse(log['start_time']));
        final duration = formatDuration(log['duration_seconds'] ?? 0);
        return AlertDialog(
          title: const Text('Call Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Number: ${log['number']}"),
              Text("Type: ${log['type']}"),
              Text("Start: $date"),
              Text("Duration: $duration"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Call history")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('call_logs')
            .orderBy('start_time', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final log = docs[index].data() as Map<String, dynamic>;

              final name = log['number'];
              final type = log['type'] ?? 'outgoing';
              final duration = formatDuration(log['duration_seconds'] ?? 0);
              final date = DateFormat('MM/dd/yy')
                  .format(DateTime.parse(log['start_time']));

              Color textColor;
              if (type == 'missed') {
                textColor = Colors.red;
              } else if (type == 'incoming') {
                textColor = Colors.green;
              } else {
                textColor = Colors.black;
              }

              return ListTile(
                onTap: () => showCallDetails(log),
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(name, style: TextStyle(color: textColor)),
                subtitle: Row(
                  children: [
                    Icon(
                      type == 'incoming'
                          ? Icons.call_received
                          : type == 'missed'
                              ? Icons.call_missed
                              : Icons.call_made,
                      size: 16,
                      color: textColor,
                    ),
                    const SizedBox(width: 4),
                    Text(type),
                    const SizedBox(width: 10),
                    Text(duration),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(date),
                    const SizedBox(height: 4),
                    const Icon(Icons.info_outline,
                        size: 18, color: Colors.blue),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
