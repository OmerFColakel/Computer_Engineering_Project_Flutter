import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  List<CameraDescription> cameras = [];

  getCamera()
      .then((value) => {cameras = value, runApp(MyApp(cameras: cameras))});
  // runApp(MyApp(cameras: cameras));
}

Future<List<CameraDescription>> getCamera() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  return cameras;
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key, required this.cameras}) : super(key: key);
  final List<CameraDescription> cameras;

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

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.cameras,
  });

  final List<CameraDescription> cameras;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen>
    with WidgetsBindingObserver {
  AppLifecycleState? _notification;
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  var isVideoOn = false;

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
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.cameras[0],
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
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
              backgroundColor: Colors.grey[900],
              body: Center(
                child: CameraPreview(_controller),
              ),
              bottomNavigationBar: BottomAppBar(
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () async {
                        if (isVideoOn) {
                          final video = await _controller.stopVideoRecording();
                          isVideoOn = false;
                          GallerySaver.saveVideo(video.path);
                        }
                        var flag = true;
                        if (_controller.description.lensDirection ==
                            CameraLensDirection.front) {
                          flag = false;
                        }
                        if (flag) {
                          _controller = CameraController(
                            // Get a specific camera from the list of available cameras.
                            widget.cameras[1],
                            // Define the resolution to use.
                            ResolutionPreset.medium,
                          );
                        } else {
                          _controller = CameraController(
                            // Get a specific camera from the list of available cameras.
                            widget.cameras[0],
                            // Define the resolution to use.
                            ResolutionPreset.medium,
                          );
                        }
                        setState(() {
                          _initializeControllerFuture =
                              _controller.initialize();
                        });
                      },
                      icon: const Icon(Icons.cameraswitch_outlined),
                      color: Colors.white,
                    ),
                    IconButton(
                      onPressed: () async {
                        // Take the Picture in a try / catch block. If anything goes wrong,
                        // catch the error.
                        try {
                          if (isVideoOn) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                snackBar("Please stop video recording first"));
                          } else {
                            await _initializeControllerFuture;

                            final image = await _controller.takePicture();

                            GallerySaver.saveImage(image.path);
                            ScaffoldMessenger.of(context).showSnackBar(
                                snackBar("Image saved to gallery"));
                            if (!mounted) return;
                          }
                        } catch (e) {
                          // If an error occurs, log the error to the console.
                          print("An error occurred $e");
                        }
                      },
                      icon: const Icon(Icons.camera_alt_outlined),
                      color: Colors.white,
                    ),
                    IconButton(
                      onPressed: () async {
                        try {
                          await _initializeControllerFuture;
                          if (isVideoOn) {
                            final video =
                                await _controller.stopVideoRecording();
                            setState(() {
                              isVideoOn = false;
                            });
                            GallerySaver.saveVideo(video.path);
                            ScaffoldMessenger.of(context).showSnackBar(
                                snackBar("Video saved to gallery"));
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
                      },
                      icon: (isVideoOn
                          ? const Icon(Icons.videocam_outlined)
                          : const Icon(Icons.videocam_off_outlined)),
                      color: Colors.white,
                    ),
                    IconButton(
                        onPressed: () {
                          _controller.pausePreview();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BluetoothPage(),
                              )).then((value) => _controller.resumePreview());
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

SnackBar snackBar(String message) {
  return SnackBar(
    content: Text(message),
  );
}

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
    }else
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
