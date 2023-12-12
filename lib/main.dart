import 'dart:async';
import 'package:ceng2/ServerRequestPage.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'CameraScreen.dart';

void main() {
  runApp(MyApp());
}

// Gets the list of available cameras.

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  final int portNUmberForWifi = 8080;
  final String ipAddressForWifi = '10.1.240.225';

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primarySwatch: Colors.blue, backgroundColor: Colors.grey[900]),
      home: ServerRequestPage(),
    );
  }
}
