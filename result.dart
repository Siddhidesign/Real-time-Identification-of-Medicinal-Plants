import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ResultPage extends StatefulWidget {
  final List<dynamic>? identifiedPlantPredictions;

  ResultPage({required this.identifiedPlantPredictions});

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  TextEditingController _feedbackController = TextEditingController();
  XFile? _selectedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Identification Result'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Identified Plants:',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            SizedBox(height: 20),
            if (widget.identifiedPlantPredictions != null)
              ...widget.identifiedPlantPredictions!.map((prediction) {
                return _buildPlantCard(prediction);
              }).toList(),
            SizedBox(height: 20),
            Text(
              'Provide Feedback:',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _feedbackController,
              decoration: InputDecoration(
                hintText: 'Enter correct species name',
                labelText: 'Correct Species Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _selectImage(context);
              },
              child: Text('Select Image'),
            ),
            SizedBox(height: 10),
            if (_selectedImage != null)
              Image.file(
                File(_selectedImage!.path),
                height: 150,
              ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _submitFeedback(context);
              },
              child: Text('Submit Feedback'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantCard(Map<String, dynamic> prediction) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        title: Text(
          prediction['species_name'] ?? '',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w300),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (prediction['local_name'] != null) ...[
              Text(
                'Local Name:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Text(
                prediction['local_name'] ?? '',
                style: TextStyle(fontSize: 20),
              ),
            ],
            if (prediction['uses'] != null) ...[
              SizedBox(height: 10),
              Text(
                'Uses: ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Text(
                prediction['uses'] ?? '',
                style: TextStyle(fontSize: 15),
              ),
            ],
            SizedBox(height: 10),
            Divider(),
          ],
        ),
      ),
    );
  }

  void _selectImage(BuildContext context) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  void _submitFeedback(BuildContext context) async {
    String feedbackSpeciesName = _feedbackController.text.trim();

    if (feedbackSpeciesName.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Please enter a species name and select an image for feedback.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    var apiUrl = 'http://13.201.56.91:8000/feedback';

    try {
      // Read image file as bytes
      List<int> imageBytes = await File(_selectedImage!.path).readAsBytes();

      // Encode image bytes to base64
      String base64Image = base64Encode(imageBytes);

      // Prepare feedback data
      Map<String, dynamic> feedbackData = {
        'username': 'example_username', // Change this to actual username
        'feedback':
            'example_feedback_text', // Change this to actual feedback text
        'image_data': base64Image,
      };

      // Convert feedback data to JSON
      String feedbackJson = jsonEncode(feedbackData);

      // Make POST request to submit feedback
      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: feedbackJson,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Feedback submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _feedbackController.clear();
        setState(() {
          _selectedImage = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit feedback. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting feedback. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error submitting feedback: $e');
    }
  }
}
