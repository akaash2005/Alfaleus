import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskFormScreen extends StatefulWidget {
  final String taskId;

  const TaskFormScreen({Key? key, required this.taskId}) : super(key: key);

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _field1 = TextEditingController();
  final _field2 = TextEditingController();
  final _field3 = TextEditingController();
  final _field4 = TextEditingController();

  @override
  void dispose() {
    _field1.dispose();
    _field2.dispose();
    _field3.dispose();
    _field4.dispose();
    super.dispose();
  }

  void _submitForm() async {
  if (_formKey.currentState!.validate()) {
    final formData = {
      'Field 1': _field1.text,
      'Field 2': _field2.text,
      'Field 3': _field3.text,
      'Field 4': _field4.text,
    };

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    // Upload to Firestore under 'quotations'
    await FirebaseFirestore.instance.collection('quotations').add({
      'uid': uid,
      'taskId': widget.taskId,
      'timestamp': DateTime.now(),
      ...formData,
    });

    Navigator.pop(context, formData); // Optionally pass back formData
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Finish Task Form')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _field1,
                decoration: InputDecoration(labelText: 'Doctor,Hospital Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _field2,
                decoration: InputDecoration(labelText: 'Product Ordered'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _field3,
                decoration: InputDecoration(labelText: 'Deal Value'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _field4,
                decoration: InputDecoration(labelText: 'Quantity'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _submitForm, child: Text('Submit')),
            ],
          ),
        ),
      ),
    );
  }
}
