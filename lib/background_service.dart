import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(),
  );

  await service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  print('[BG SERVICE] Service started ✅');

  final prefs = await SharedPreferences.getInstance();

  String? currentTaskId = prefs.getString('taskId');
  double? finalLat = prefs.getDouble('finalLat');
  double? finalLon = prefs.getDouble('finalLon');

  Timer? locationTimer;

  void startLocationTimer() {
    locationTimer = Timer.periodic(Duration(minutes: 5), (timer) async {
      try {
        if (currentTaskId == null) {
          print('[BG SERVICE] No task running ❌');
          return;
        }

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          print('[BG SERVICE] No user ❌');
          return;
        }

        // 🔥 Check if task is completed
        final taskDoc = await FirebaseFirestore.instance
            .collection('leads')
            .doc(currentTaskId)
            .get();

        if (taskDoc.exists && taskDoc['status'] == 'completed') {
          print('[BG SERVICE] Task is completed. Stopping tracking ❌');
          locationTimer?.cancel();
          locationTimer = null;
          await prefs.remove('taskId');
          await prefs.remove('finalLat');
          await prefs.remove('finalLon');
          currentTaskId = null;
          return;
        }

        final pos = await Geolocator.getCurrentPosition();
        print('[BG SERVICE] Got location: ${pos.latitude}, ${pos.longitude}');

        await FirebaseFirestore.instance.collection('executive_locations').add({
          'uid': user.uid,
          'taskId': currentTaskId,
          'executive_latitude': pos.latitude,
          'executive_longitude': pos.longitude,
          'final_latitude': finalLat,
          'final_longitude': finalLon,
          'timestamp': DateTime.now().toIso8601String(),
        });

        print('[BG SERVICE] Location saved ✅');
      } catch (e) {
        print('[BG SERVICE] Error: $e');
      }
    });
  }

  if (currentTaskId != null) {
    startLocationTimer();
  }

  service.on('startTask').listen((event) async {
    print('[BG SERVICE] Received startTask: $event');
    currentTaskId = event!['taskId'];
    finalLat = event['finalLat'];
    finalLon = event['finalLon'];

    await prefs.setString('taskId', currentTaskId!);
    await prefs.setDouble('finalLat', finalLat!);
    await prefs.setDouble('finalLon', finalLon!);

    locationTimer?.cancel();
    startLocationTimer();
  });

  service.on('stopTask').listen((event) async {
    print('[BG SERVICE] Received stopTask');
    currentTaskId = null;
    finalLat = null;
    finalLon = null;
    await prefs.remove('taskId');
    await prefs.remove('finalLat');
    await prefs.remove('finalLon');

    locationTimer?.cancel();
    locationTimer = null;
  });
}