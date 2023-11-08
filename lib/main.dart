import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'CameraScreen.dart';

void main() {
  List<CameraDescription> cameras = [];

  getCamera()
      .then((value) => {cameras = value, runApp(MyApp(cameras: cameras))});
  // runApp(MyApp(cameras: cameras));
}

// Gets the list of available cameras.
Future<List<CameraDescription>> getCamera() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  return cameras;
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key, required this.cameras}) : super(key: key);
  final List<CameraDescription> cameras;  // Available cameras

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primarySwatch: Colors.blue, backgroundColor: Colors.grey[900]),
      home: TakePictureScreen(cameras: cameras),
    );
  }
}


class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(File(imagePath)),
    );
  }
}





