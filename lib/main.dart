import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Login & Signup'),
            bottom: TabBar(
              tabs: [
                Tab(text: 'Login'),
                Tab(text: 'Signup'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              LoginCard(),
              SignupCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginCard extends StatelessWidget {
  final emailController = TextEditingController();
  final passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: EdgeInsets.all(20.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: passController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: emailController.text.trim(),
                      password: passController.text.trim(),
                );

                  final uid = userCredential.user!.uid;

                  final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get();

                  if (!userDoc.exists) {
                    print("User document not found in Firestore for UID: $uid");

                  ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User data not found. Please contact support.')),
                );
                return; // Exit early
}

    final role = userDoc['role'];
    print('Logged in as $role');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged in as $role')),
    );
    final name = userDoc['name'];
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HomePage(name: name)),
    );
  } catch (e) {
    print('Login error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login failed')),
    );
  }
                },
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignupCard extends StatelessWidget {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: EdgeInsets.all(20.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Full Name'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: passController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
  try {
    final userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passController.text.trim(),
    );

    final uid = userCredential.user!.uid;
    print('Created user with UID: $uid');

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': 'executive',
      });

      print('User document created for UID: $uid');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signed up as Executive')),
      );
    } catch (firestoreError) {
      print('Firestore write error: $firestoreError');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: could not save user data')),
      );
    }
  } catch (e) {
    print('Signup error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Signup failed: email may be in use')),
    );
  }
},
                child: Text('Signup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
