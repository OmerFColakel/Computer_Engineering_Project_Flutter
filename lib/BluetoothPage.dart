import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  @override
  void initState() {
    super.initState();
    connectToDevice();
  }

  connectToDevice() async {
    print("connectToDevice is called");
    // check if bluetooth is supported by your hardware
// Note: The platform is initialized on the first call to any FlutterBluePlus method.
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      return;
    } else
      print("Bluetooth is supported by this device");

// handle bluetooth on & off
// note: for iOS the initial state is typically BluetoothAdapterState.unknown
// note: if you have permissions issues you will get stuck at BluetoothAdapterState.unauthorized
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      print(state);
      if (state == BluetoothAdapterState.on) {
        // usually start scanning, connecting, etc
      } else {
        // show an error to the user, etc
      }
    });

// turn on bluetooth ourself if we can
// for iOS, the user controls bluetooth enable/disable
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to A Glasses'),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          BTDevice(device_Name: '1'),
          BTDevice(device_Name: '2'),
          BTDevice(device_Name: '3'),
          BTDevice(device_Name: '4'),
          BTDevice(device_Name: '5'),
          BTDevice(device_Name: '6'),
          BTDevice(device_Name: '7'),
          BTDevice(device_Name: '8'),
          BTDevice(device_Name: '9'),
          BTDevice(device_Name: '10'),
        ],
      ),
      backgroundColor: Colors.grey[900],
    );
  }
}


class BTDevice extends StatefulWidget {
  const BTDevice({super.key, required this.device_Name});

  final String device_Name;

  @override
  State<BTDevice> createState() => _BTDeviceState();
}

class _BTDeviceState extends State<BTDevice> {
  bool isConnecting = false;
  bool isConnected = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Container(
        height: 100,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[700],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              isConnecting = !isConnecting;
            });
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    widget.device_Name,
                    style: const TextStyle(
                        color: Colors.white,
                        overflow: TextOverflow.ellipsis,
                        fontSize: 17),
                    maxLines: 1,
                  ),
                ),
              ),
              isConnecting
                  ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
                  : (isConnected
                  ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Icon(Icons.check),
              )
                  : const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: CircularProgressIndicator(
                  color: Colors.transparent,
                ),
              ))
            ],
          ),
        ),
      ),
    );
  }
}