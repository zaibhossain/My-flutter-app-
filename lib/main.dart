import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Upload Gallery',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ImageUploadScreen(),
    );
  }
}

class ImageUploadScreen extends StatefulWidget {
  @override
  _ImageUploadScreenState createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  File? _image;
  final _picker = ImagePicker();
  List<String> _uploadedImages = [];
  List<Map<String, dynamic>> _analysisResults = [];

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:8000/upload/'),
    );
    request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await http.Response.fromStream(response);
      final data = jsonDecode(responseData.body);

      setState(() {
        _analysisResults = List<Map<String, dynamic>>.from(data['results']);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo uploaded and analyzed successfully!')),
      );
      _fetchImages();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed')));
    }
  }

  Future<void> _deleteImage(String filename) async {
    try {
      final filenameWithoutDir = filename.split('/').last;

      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8000/delete/$filenameWithoutDir'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image deleted successfully!')));
        _fetchImages();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete image')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting image: $e')));
    }
  }

  Future<void> _fetchImages() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/images/'));
    if (response.statusCode == 200) {
      final List<dynamic> images = jsonDecode(response.body)['images'];
      setState(() {
        _uploadedImages = List<String>.from(images);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload & View Images')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _image == null
                ? Text('No image selected.')
                : Image.file(_image!, height: 150),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Pick Image'),
                ),
                SizedBox(width: 10),
                ElevatedButton(onPressed: _uploadImage, child: Text('Upload')),
              ],
            ),
            Divider(),
            if (_analysisResults.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analysis Results:'),
                  ..._analysisResults.map((result) {
                    return Text(
                      '${result['label']} - Probability: ${(result['probability'] * 100).toStringAsFixed(2)}%',
                    );
                  }).toList(),
                ],
              ),
            Divider(),
            Expanded(
              child:
                  _uploadedImages.isEmpty
                      ? Text('No uploaded images.')
                      : ListView.builder(
                        itemCount: _uploadedImages.length,
                        itemBuilder: (context, index) {
                          final imageUrl =
                              'http://10.0.2.2:8000/${_uploadedImages[index]}';
                          return ExpansionTile(
                            title: Text(_uploadedImages[index]),
                            children: [
                              Image.network(imageUrl),
                              ElevatedButton(
                                onPressed:
                                    () => _deleteImage(_uploadedImages[index]),
                                child: Text('Delete'),
                              ),
                            ],
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
