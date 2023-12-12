import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

import 'SelectBondedDevicePage.dart';

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.cameras,
    required this.portNumberForWifi,
    required this.ipAddressForWifi,
  });

  final List<CameraDescription> cameras;
  final int portNumberForWifi;
  final String ipAddressForWifi;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen>
    with WidgetsBindingObserver {
  AppLifecycleState? _notification;
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late BluetoothDevice server;
  var isVideoOn = false;
  bool isFlashOn = false;
  bool isDisconnecting = false;
  bool isConnecting = true;
  BluetoothConnection? connection;

  bool get isConnected => (connection?.isConnected ?? false);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _notification = state;
    });

    switch (_notification) {
      case AppLifecycleState.resumed:
        _controller.resumePreview();
        break;
      case AppLifecycleState.inactive:
        _controller.pausePreview();
        break;
      case AppLifecycleState.paused:
        _controller.pausePreview();
        break;
      case AppLifecycleState.detached:
        _controller.pausePreview();
        break;

      case null:
        break;
    }
  }

  @override
  void initState() {
    print("got ipaddress: " + widget.ipAddressForWifi);
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.cameras[0],
      // Define the resolution to use.
      ResolutionPreset.ultraHigh,
    );
    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  Future<void> _initializeBluetooth() async {
    try {
      connection = await BluetoothConnection.toAddress(server.address);
      print('Connected to the device');

      connection!.input!.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
      });
    } catch (error) {
      print('Cannot connect, exception occurred');
      print(error);
    }
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fill this out in the next steps.
    return FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return Scaffold(
              appBar: AppBar(
                title: const Text('VisionVortex'),
                actions: [
                  IconButton(
                      icon: Icon((isFlashOn
                          ? Icons.flash_on_outlined
                          : Icons.flash_off_outlined)),
                      onPressed: () {
                        setState(() {
                          isFlashOn = !isFlashOn;
                          _controller.setFlashMode(
                              isFlashOn ? FlashMode.torch : FlashMode.off);
                        });
                      }),
                ],
                backgroundColor: Colors.grey[900],
              ),
              backgroundColor: Colors.grey[900],
              body: Center(
                child: CameraPreview(_controller),
              ),
              bottomNavigationBar: BottomAppBar(
                color: Colors.grey[900],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        changeCamera();
                      },
                      icon: const Icon(Icons.cameraswitch_outlined),
                      color: Colors.white,
                    ),
                    IconButton(
                      onPressed: () {
                        takeImage();
                      },
                      icon: const Icon(Icons.camera_alt_outlined),
                      color: Colors.white,
                    ),
                    IconButton(
                      onPressed: () {
                        takeVideo();
                      },
                      icon: (isVideoOn
                          ? const Icon(Icons.videocam_outlined)
                          : const Icon(Icons.videocam_off_outlined)),
                      color: Colors.white,
                    ),
                    IconButton(
                        onPressed: () async {
                          var btScanStatus =
                              await Permission.bluetoothScan.status;
                          var btConnectStatus =
                              await Permission.bluetoothConnect.status;
                          print("btScanStatus: " + btScanStatus.toString());
                          print("btConnectStatus: " + btConnectStatus.toString());
                          if (btScanStatus.isDenied ||
                              btScanStatus.isPermanentlyDenied ||
                              btConnectStatus.isDenied ||
                              btConnectStatus.isPermanentlyDenied) {
                            await Permission.bluetoothScan.request();
                            await Permission.bluetoothConnect.request();
                          }

                          if ((btScanStatus.isGranted ||
                                  btScanStatus.isLimited ||
                                  btScanStatus.isRestricted) &&
                              (btConnectStatus.isGranted ||
                                  btConnectStatus.isLimited ||
                                  btConnectStatus.isRestricted)) {
                            final BluetoothDevice? selectedDevice =
                                await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) {
                                  return SelectBondedDevicePage(
                                      checkAvailability: false);
                                },
                              ),
                            );

                            if (selectedDevice != null) {
                              print('Connect -> selected ' +
                                  selectedDevice.address);
                              server = selectedDevice;
                              _initializeBluetooth();
                            } else {
                              print('Connect -> no device selected');
                            }
                          }
                        },
                        icon: const Icon(
                          Icons.bluetooth,
                          color: Colors.white,
                        ))
                  ],
                ),
              ),
            );
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

// Send video to server
  Future<String> sendVideo(String path, String ip_address, int port) async {
    try {
      final socket = await Socket.connect(ip_address, port);
      print('Connected to:' +
          socket.remoteAddress.address +
          ':' +
          socket.remotePort.toString());
      File file = File(path);
      int fileSize = file.lengthSync();
      final String out = fileSize.toString() + "-Video";
      socket.write(out);

      RandomAccessFile raf = file.openSync(mode: FileMode.read);
      int bufferSize = 1024;
      List<int> buffer = List.filled(bufferSize, 0);
      while (true) {
        int readBytes = raf.readIntoSync(buffer, 0, bufferSize);
        if (readBytes == 0) {
          break;
        }
        socket.add(Uint8List.fromList(buffer.sublist(0, readBytes)));
      }
      raf.closeSync();
      await socket.flush();
      await socket.close();
      print('Video sent');
    } catch (e) {
      print(e);
      return e.toString();
    }
    return "Video sent";
  }

  Future<String> sendImage(String path, String ip_address, int port) async {
    try {
      final socket = await Socket.connect(ip_address, port);
      print('Connected to:' +
          socket.remoteAddress.address +
          ':' +
          socket.remotePort.toString());
      File file = File(path);
      //{ "fileType" : "Image", "fileExtension": "jpg", "totalSize": "123456", "expectedChecksum": "123456}"
      /*print("File extension: " + file.path.split(".").last);
      print("File size: " + file.lengthSync().toString());
      print("File calculated sum:" + crc32(file.readAsBytesSync()).toString());
      int fileSize = file.lengthSync();*/
      final String out = "{fileType:\"image\",fileExtension:\"" +
          file.path.split(".").last +
          "\",totalSize:" +
          file.lengthSync().toString() +
          ",expectedChecksum:" +
          crc32(file.readAsBytesSync()).toString() +
          "}";
      // convert out.legth to uint32 and write to socket

      socket.write(out.length);
      socket.write(out.toString());

      print('out: ' + out);

      RandomAccessFile raf = file.openSync(mode: FileMode.read);
      int bufferSize = 1024;
      List<int> buffer = List.filled(bufferSize, 0);
      while (true) {
        int readBytes = raf.readIntoSync(buffer, 0, bufferSize);
        if (readBytes == 0) {
          break;
        }
        socket.add(Uint8List.fromList(buffer.sublist(0, readBytes)));
      }
      raf.closeSync();
      await socket.flush();
      await socket.close();
      print('Image sent');
    } catch (e) {
      print(e);
      return e.toString();
    }
    return "Image sent";
  }

  void takeImage() async {
    try {
      if (isVideoOn) {
        ScaffoldMessenger.of(context)
            .showSnackBar(snackBar("Please stop video recording first"));
      } else {
        await _initializeControllerFuture;

        final image = await _controller.takePicture();
        GallerySaver.saveImage(image.path);

        ScaffoldMessenger.of(context).showSnackBar(snackBar(await sendImage(
            image.path, widget.ipAddressForWifi, widget.portNumberForWifi)));
        ScaffoldMessenger.of(context)
            .showSnackBar(snackBar("Image saved to gallery"));
        if (!mounted) return;
      }
    } catch (e) {
      // If an error occurs, log the error to the console.
      print("An error occurred $e");
    }
  }

  void takeVideo() async {
    String ipAddress = widget.ipAddressForWifi;
    int port = widget.portNumberForWifi;
    try {
      await _initializeControllerFuture;
      if (isVideoOn) {
        final video = await _controller.stopVideoRecording();
        setState(() {
          isVideoOn = false;
        });
        GallerySaver.saveVideo(video.path);
        ScaffoldMessenger.of(context).showSnackBar(
            snackBar(await sendVideo(video.path, ipAddress, port)));
        ScaffoldMessenger.of(context)
            .showSnackBar(snackBar("Video saved to gallery"));
      } else {
        await _controller.startVideoRecording();
        setState(() {
          isVideoOn = true;
        });
      }
      if (!mounted) return;
    } catch (e) {
      print(e.toString());
    }
  }

  void changeCamera() async {
    if (isVideoOn) {
      final video = await _controller.stopVideoRecording();
      isVideoOn = false;
      GallerySaver.saveVideo(video.path);
    }
    var flag = true;
    if (_controller.description.lensDirection == CameraLensDirection.front) {
      flag = false;
    }
    if (flag) {
      _controller = CameraController(
          // Get a specific camera from the list of available cameras.
          widget.cameras[1],
          // Define the resolution to use.
          _controller.resolutionPreset);
    } else {
      _controller = CameraController(
          // Get a specific camera from the list of available cameras.
          widget.cameras[0],
          // Define the resolution to use.
          _controller.resolutionPreset);
    }
    setState(() {
      _initializeControllerFuture = _controller.initialize();
    });
  }

  void _onDataReceived(Uint8List data) async {
    // Process the received data here
    String dataString = String.fromCharCodes(data);
    String signal = dataString.trim();
    if (signal == "1") {
      print("Signal 1 received");
      signal = "1";
      // Trigger camera functionality
      takeImage();
    } else if (signal == "2") {
      print("Signal 2 received");
      signal = "2";
      // Trigger camera functionality
      changeCamera();
    } else if (signal == "3") {
      print("Signal 3 received");
      signal = "3";
      // Trigger camera functionality
      takeVideo();
    }
  }

  int crc32(List<int> data) {
    int crc = 0xFFFFFFFF;
    for (int byte in data) {
      crc ^= byte;
      for (int k = 0; k < 8; k++) {
        crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
      }
    }
    return crc ^ 0xFFFFFFFF;
  }
}

SnackBar snackBar(String message) {
  return SnackBar(
    content: Text(message),
  );
}
