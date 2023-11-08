import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

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
  final List<CameraDescription> cameras; // Available cameras

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