// home_page.dart
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final String name;

  const HomePage({Key? key, required this.name}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome')),
      body: Center(
        child: Text(
          'Hello, $name!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
