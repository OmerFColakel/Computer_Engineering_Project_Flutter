import 'dart:io';

import 'package:camera/camera.dart';
import 'package:ceng2/CameraScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ServerRequestPage extends StatefulWidget {
  const ServerRequestPage({super.key});

  @override
  State<ServerRequestPage> createState() => _ServerRequestPageState();
}

class _ServerRequestPageState extends State<ServerRequestPage> {
  late TextEditingController _ipController;
  late TextEditingController _usernameController;
  late TextEditingController _eventNameController;
  String _myIPAddress = "";

  List<CameraDescription> cameras = [];

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController();
    _usernameController = TextEditingController();
    _eventNameController = TextEditingController();
    printIps();
    getCamera().then((value) => {cameras = value});
  }

  Future printIps() async {
    for (var interface in await NetworkInterface.list()) {
      print('== Interface: ${interface.name} ==');
      for (var addr in interface.addresses) {
        print(
            '${addr.address} ${addr.host} ${addr.isLoopback} ${addr.rawAddress} ${addr.type.name}');
      }
      if (interface.name == "wlan0") {
        _myIPAddress = interface.addresses.first.address;
      }
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _usernameController.dispose();
    _eventNameController.dispose();
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
        child: ListView(
          children: [
            const ImageIcon(
              AssetImage("assets/main_logo.png"),
              size: 300,
              color: Colors.white,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
                keyboardType: TextInputType.number,
                controller: _ipController,
                cursorColor: Colors.white,
                decoration: buildInputDecoration("Enter an IP Address"),
                style: TextStyle(color: Colors.grey[300]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.deny(",")
                ],
                controller: _usernameController,
                cursorColor: Colors.white,
                decoration: buildInputDecoration("Enter a Username"),
                style: TextStyle(color: Colors.grey[300]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.deny(",")
                ],
                controller: _eventNameController,
                cursorColor: Colors.white,
                decoration: buildInputDecoration("Enter an Event Name"),
                style: TextStyle(color: Colors.grey[300]),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 100,
                height: 50,
                child: TextButton(
                  onPressed: textButtonPressed,
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.grey[700]),
                  ),
                  child: const Text(
                    "Connect",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration buildInputDecoration(String labelText) {
    return InputDecoration(
      border: const OutlineInputBorder(),
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.white),
      focusColor: Colors.white,
      hoverColor: Colors.white,
      fillColor: Colors.grey[700],
      filled: true,
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
    );
  }

  Future<int> enterToApp(String ipAddress, String eventname) async {
    print("Trying to connect to $ipAddress");
    print("Eventname: $eventname");
    print("My IP Address: $_myIPAddress");

    Future<String> returnedValue =
        tryConnection(ipAddress, eventname, _myIPAddress);
    String result = await returnedValue;
    if (result != "Error") {
      return 1;
    }
    return -1;
  }

  void textButtonPressed() async {
    if (_ipController.text.isEmpty ||
        _eventNameController.text.isEmpty ||
        _usernameController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Please fill all the fields'),
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
      return;
    }
    int value = await enterToApp(_ipController.text, _eventNameController.text);
    if (value == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return TakePictureScreen(
              cameras: cameras,
              portNumberForWifi: 8080,
              ipAddressForWifi: _ipController.text,
              username: _usernameController.text,
              myIPAddress: _myIPAddress,
              eventName: _eventNameController.text,
            );
          },
        ),
      );
    } else if (value == -1) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Could not connect to ${_ipController.text}'),
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
  }
}

Future<String> tryConnection(
    String ipAddress, String eventname, String _myIPAdress) async {
  try {
    Socket socket = await Socket.connect(ipAddress, 8080);
    socket.destroy();
    return "";
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
