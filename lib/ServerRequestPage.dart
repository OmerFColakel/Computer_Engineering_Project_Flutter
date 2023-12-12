import 'dart:io';

import 'package:camera/camera.dart';
import 'package:ceng2/CameraScreen.dart';
import 'package:flutter/material.dart';

class ServerRequestPage extends StatefulWidget {
  const ServerRequestPage({super.key});

  @override
  State<ServerRequestPage> createState() => _ServerRequestPageState();
}

class _ServerRequestPageState extends State<ServerRequestPage> {
  late TextEditingController _controller;
  List<CameraDescription> cameras = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    getCamera().then((value) => {cameras = value});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to A Raspberry Pi'),
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: Colors.grey[900],
        padding: const EdgeInsets.only(left: 32, right: 32),
        child: Column(
          children: [
            ImageIcon(
              AssetImage("assets/main_logo.png"),
              size: 300,
              color: Colors.white,
            ),
            TextField(
              keyboardType: TextInputType.number,
              controller: _controller,
              cursorColor: Colors.white,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter an IP Address',
                labelStyle: TextStyle(color: Colors.white),
                focusColor: Colors.white,
                hoverColor: Colors.white,
                fillColor: Colors.grey[700],
                filled: true,
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              style:  TextStyle(color: Colors.grey[900]),
              onSubmitted: (value) async {
                Future<String> returnedValue = tryConnection(value);
                String result = await returnedValue;
                if (result != "Error") {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return TakePictureScreen(
                            cameras: cameras,
                            portNumberForWifi: 8080,
                            ipAddressForWifi: result);
                      },
                    ),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Error'),
                        content: Text('Could not connect to $value'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<String> tryConnection(String ipAddress) async {
  try {
    Socket socket = await Socket.connect(ipAddress, 8080);
    print('Connected to: '
        '${socket.remoteAddress.address}:${socket.remotePort}');
    socket.destroy();
    return ipAddress;
  } catch (e) {
    print(e);
  }
  return "Error";
}

Future<List<CameraDescription>> getCamera() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  return cameras;
}
