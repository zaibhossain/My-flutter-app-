import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter User Profile',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: UserProfileForm(),
    );
  }
}

class UserProfileForm extends StatefulWidget {
  @override
  _UserProfileFormState createState() => _UserProfileFormState();
}

class _UserProfileFormState extends State<UserProfileForm> {
  int newUserId = Random().nextInt(10000);
  final _nameController = TextEditingController();
  final _interestsController = TextEditingController();
  final _giftPreferencesController = TextEditingController();

  // POST request to FastAPI
  void _submitForm() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/user/'),
      headers: {
        'Content-Type': 'application/json',
      }, // Add this line to set headers to JSON
      body: jsonEncode({
        'user_id': newUserId.toString(),
        'name': _nameController.text,
        'interests': _interestsController.text,
        'gift_preferences': _giftPreferencesController.text,
      }),
    );

    if (response.statusCode == 200) {
      print('User profile created');
    } else {
      print('Failed to create profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _interestsController,
              decoration: InputDecoration(
                labelText: 'Interests (comma separated)',
              ),
            ),
            TextField(
              controller: _giftPreferencesController,
              decoration: InputDecoration(
                labelText: 'Gift Preferences (comma separated)',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _submitForm, child: Text('Submit')),
          ],
        ),
      ),
    );
  }
}
