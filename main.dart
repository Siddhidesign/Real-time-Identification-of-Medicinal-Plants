import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:leaflens/login.dart';
import 'package:leaflens/result.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Identification',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
      home: LoginPage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  List<Map<String, dynamic>> _userHistory = []; // List to store user history
  Map<String, dynamic>? _identifiedPlantData;
  bool _isIdentifying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Identification'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildImageSection(),
            const SizedBox(height: 20),
            _buildIdentifyButton(),
            const SizedBox(height: 20),
            _buildIdentifiedPlantSection(),
            const SizedBox(height: 20),
            _buildUserHistorySection(), // Add user history section
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24),
      child: GestureDetector(
        onTap: _image == null ? _showImageOptionsBottomSheet : null,
        child: Container(
          height: 224,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey[200],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_image != null)
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  child: Image.file(
                    File(_image!.path),
                    height: 224,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              _image == null
                  ? const Icon(Icons.photo_camera, size: 48, color: Colors.grey)
                  : Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _image = null;
                            _identifiedPlantData = null;
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.grey.withOpacity(0.5),
                          radius: 16,
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentifyButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: _image != null && !_isIdentifying ? _identifyPlant : null,
        child: _isIdentifying
            ? const CircularProgressIndicator()
            : const Text('Identify Plant'),
      ),
    );
  }

  Widget _buildIdentifiedPlantSection() {
    if (_identifiedPlantData == null) {
      return Container();
    } else {
      List<dynamic> predictions = _identifiedPlantData!['predictions'];
      Map<String, dynamic> firstPrediction =
          predictions.isNotEmpty ? predictions[0] : {};
      List<Map<String, dynamic>> restPredictions = predictions.length > 1
          ? List<Map<String, dynamic>>.from(predictions.sublist(1))
          : [];

      return Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Identified Plant:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.grass),
                  const SizedBox(width: 10),
                  Text(
                    firstPrediction['species_name'] ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              if (firstPrediction['local_name'] != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.language),
                    const SizedBox(width: 10),
                    const Text(
                      'Local Name: ',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      firstPrediction['local_name'] ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
              if (firstPrediction['uses'] != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.lightbulb),
                    const SizedBox(width: 10),
                    const Text(
                      'Uses: ',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Flexible(
                      child: Text(
                        firstPrediction['uses'] ?? '',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1, // Adjust as needed
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 20),
              if (restPredictions.isNotEmpty) ...[
                ExpansionTile(
                  title: Text('View More'),
                  children: restPredictions.map((prediction) {
                    return ListTile(
                      title: Text(prediction['species_name'] ?? ''),
                      subtitle: Text(prediction['local_name'] ?? ''),
                      onTap: () {
                        // Handle tile tap if needed
                      },
                    );
                  }).toList(),
                ),
              ],
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResultPage(
                        identifiedPlantPredictions: _identifiedPlantData != null
                            ? _identifiedPlantData!['predictions']
                            : null,
                      ),
                    ),
                  );
                },
                child: Text('View Result'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildUserHistorySection() {
    if (_userHistory.isEmpty) {
      return Container();
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'User Search History:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: _userHistory.map((historyItem) {
              return ListTile(
                title: Text(historyItem['species_name'] ?? ''),
                subtitle: Text(historyItem['local_name'] ?? ''),
                leading: historyItem['imagePath'] != null
                    ? Image.file(File(historyItem['imagePath']))
                    : null,
                onTap: () {
                  // Handle tap on user history item if needed
                },
              );
            }).toList(),
          ),
        ],
      );
    }
  }

  void _showImageOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Upload Image'),
                onTap: () {
                  Navigator.pop(context);
                  getImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Capture Image'),
                onTap: () {
                  Navigator.pop(context);
                  getImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future getImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = image;
      _identifiedPlantData = null; // Reset identified plant data
    });
  }

  Future getImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    setState(() {
      _image = image;
      _identifiedPlantData = null; // Reset identified plant data
    });
  }

  void _identifyPlant() async {
    setState(() {
      _isIdentifying = true;
    });

    try {
      // Read the image file as bytes
      List<int> imageBytes = await File(_image!.path).readAsBytes();

      // Prepare the request body
      Map<String, dynamic> requestBody = {
        'username': 'arnav', // Replace with the actual username
        'image_data': base64Encode(imageBytes),
      };

      // Make the POST request to the predict_species endpoint
      final http.Response response = await http.post(
        Uri.parse('http://13.201.56.91:8000/predict_species'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );

      // Check the response status
      if (response.statusCode == 200) {
        // Decode the response JSON
        List<dynamic> responseData = jsonDecode(response.body);
        print(responseData);

        // Handle the response data
        if (responseData.isNotEmpty) {
          setState(() {
            _identifiedPlantData = {
              'predictions': responseData,
            };
            _isIdentifying = false;
            // Add identified plant data to user history
            _userHistory.insert(0, {
              'species_name': _identifiedPlantData!['predictions'][0]
                  ['species_name'],
              'local_name': _identifiedPlantData!['predictions'][0]
                  ['local_name'],
              'imagePath': _image!.path,
            });
          });
        } else {
          throw Exception('No predictions found');
        }
      } else {
        throw Exception(
            'Failed to load response. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error identifying plant: $e');
      setState(() {
        _isIdentifying = false;
        _identifiedPlantData = null;
      });
      // Show error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error identifying plant. Please try again.'),
        ),
      );
    }
  }
}
