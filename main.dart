import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

List<CameraDescription>? cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emotion Detection App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CameraApp(),
    );
  }
}

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  late CameraController controller;
  late Future<void> cameraInitialize;

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras![1], ResolutionPreset.medium);
    cameraInitialize = controller.initialize();
  }

  Future<void> _onCameraButtonPressed() async {
    if (!controller.value.isInitialized) {
      return;
    }

    try {
      await cameraInitialize;

      XFile image = await controller.takePicture();
      Uint8List bytes = await image.readAsBytes();

      String emotion = await requestEmotionDetection(bytes);
      // Handle emotion
      print('Detected Emotion: $emotion');

      // Open the web browser to play music 
      openWebBrowser(emotion);
    } catch (e) {
      print('Error capturing image: $e');
    }
  }

  Future<String> requestEmotionDetection(Uint8List imageBytes) async {
    try {
      String apiUrl = 'http://192.168.218.96:5000/detect_emotion';
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'image': base64Encode(imageBytes)},
      );

      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['emotion'];
      } else {
        throw Exception('Failed to detect emotion. Server returned ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  void openWebBrowser(String emotion) {
    try {
      
      String musicUrl = getMusicUrl(emotion);

      // Open the web browser to play the music
      launch(musicUrl);
    } catch (e) {
      print('Error opening web browser: $e');
    }
  }

  String getMusicUrl(String emotion) {
//music logic
    Map<String, String> musicMapping = {
      'Angry': 'https://www.youtube.com/watch?v=YKLX3QbKBg0',
      'Disgust': 'https://www.youtube.com/watch?v=I-QfPUz1es8',
      'Fear': 'https://www.youtube.com/watch?v=GVUqZC7lNiw',
      'Happy': 'https://www.youtube.com/watch?v=dhYOPzcsbGM',
      'Sad': 'https://www.youtube.com/watch?v=50VNCymT-Cs',
      'Surprise': 'https://www.youtube.com/watch?v=7ufkMTshjz8',
      'Neutral': 'https://www.youtube.com/watch?v=TBsKCT4rsPw'
    };
    return musicMapping[emotion] ?? 'https://mahindamahaththaya/mp3/maharajano';
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emotion Detection App'),
      ),
      body: FutureBuilder<void>(
        future: cameraInitialize,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(controller);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCameraButtonPressed,
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}
