import 'dart:async';

import 'package:camera/camera.dart';
import 'package:ceng2/SelectBondedDevice.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';

import 'BluetoothPage.dart';

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
                                builder: (context) => const SelectBondedDevicePage(),
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

SnackBar snackBar(String message) {
  return SnackBar(
    content: Text(message),
  );
}
