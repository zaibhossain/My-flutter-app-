import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final _nameController = TextEditingController();
  final _interestsController = TextEditingController();
  final _giftPreferencesController = TextEditingController();
  List<dynamic> _users = []; // List to store user profiles
  int? _selectedUserId; // To track which user is selected for editing

  // POST request to create a new user
  void _submitForm() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/user/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': _nameController.text,
        'interests': _interestsController.text,
        'gift_preferences': _giftPreferencesController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User profile created successfully!')),
      );

      // Clear the input fields after successful submission
      _nameController.clear();
      _interestsController.clear();
      _giftPreferencesController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create profile: ${response.body}')),
      );
    }
  }

  // PUT request to update an existing user
  void _updateUser(int userId) async {
    final response = await http.put(
      Uri.parse('http://10.0.2.2:8000/user/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': _nameController.text,
        'interests': _interestsController.text,
        'gift_preferences': _giftPreferencesController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User profile updated successfully!')),
      );
      setState(() {
        _users.firstWhere((user) => user['user_id'] == userId)['name'] =
            _nameController.text;
        _users.firstWhere((user) => user['user_id'] == userId)['interests'] =
            _interestsController.text;
        _users.firstWhere(
              (user) => user['user_id'] == userId,
            )['gift_preferences'] =
            _giftPreferencesController.text;

        // Reset selected user ID to allow creating new users
        _selectedUserId = null;
      });

      // Clear the input fields after successful update
      _nameController.clear();
      _interestsController.clear();
      _giftPreferencesController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: ${response.body}')),
      );
    }
  }

  // DELETE request to remove a user
  void _deleteUser(int userId) async {
    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8000/user/$userId'),
    );

    if (response.statusCode == 200) {
      setState(() {
        _users.removeWhere((user) => user['user_id'] == userId);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('User deleted successfully!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: ${response.body}')),
      );
    }
  }

  // GET request to fetch all users
  void _fetchUsers() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/users/'));

    if (response.statusCode == 200) {
      List<dynamic> users = jsonDecode(response.body)['users'];
      setState(() {
        _users = users; // Update the user list
      });

      // Show fetched profiles in a scrollable dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('User Profiles'),
            content: SingleChildScrollView(
              child: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      _users.map((user) {
                        return ListTile(
                          title: Text(user['name']),
                          subtitle: Text(
                            'Interests: ${user['interests']}\nGift Preferences: ${user['gift_preferences']}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  // Set the selected user ID and populate fields for editing
                                  setState(() {
                                    _selectedUserId = user['user_id'];
                                    _nameController.text = user['name'];
                                    _interestsController.text =
                                        user['interests'];
                                    _giftPreferencesController.text =
                                        user['gift_preferences'];
                                  });
                                  Navigator.pop(context); // Close dialog
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _deleteUser(user['user_id']); // Delete user
                                  Navigator.pop(context); // Close dialog
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profiles')));
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
            // User profile form fields
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
            ElevatedButton(
              onPressed:
                  _selectedUserId == null
                      ? _submitForm
                      : () {
                        _updateUser(
                          _selectedUserId!,
                        ); // Update existing profile
                      },
              child: Text(_selectedUserId == null ? 'Submit' : 'Update'),
            ),
            SizedBox(height: 10),
            ElevatedButton(onPressed: _fetchUsers, child: Text('Fetch Users')),
          ],
        ),
      ),
    );
  }
}
