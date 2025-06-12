import 'package:flutter/material.dart';
import 'package:phone_state/phone_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({Key? key}) : super(key: key);

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

        if (event.number != null && event.number!.isNotEmpty && event.number != "Unknown") {
          number = event.number!;
        }
      });

      print("Status: $status, Number: $number");

      if (status == PhoneStateStatus.CALL_STARTED && !isInCall) {
        isInCall = true;
        callStart = DateTime.now();
      }

      if (status == PhoneStateStatus.CALL_ENDED && isInCall) {
        isInCall = false;
        final callEnd = DateTime.now();
        final duration = callEnd.difference(callStart ?? callEnd).inSeconds;

        if (number != "Unknown") {
          FirebaseFirestore.instance.collection('call_logs').add({
            'number': number,
            'start_time': callStart?.toIso8601String(),
            'end_time': callEnd.toIso8601String(),
            'duration_seconds': duration,
          });
          print("✅ Call logged to Firebase.");
        } else {
          print("❌ Number unknown, not logging to Firebase.");
        }

        callStart = null;
        number = "Unknown"; // reset after logging
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Phone State"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Status: $status"),
            const SizedBox(height: 20),
            Text("Number: $number"),
          ],
        ),
      ),
    );
  }
}
