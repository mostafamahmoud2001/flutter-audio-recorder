import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    initRecorder();
    requestPermission();
    super.initState();


  }
  void requestPermission() async {
    final PermissionStatus permissionStatus = await Permission.manageExternalStorage.request();
    if (permissionStatus != PermissionStatus.granted) {
      throw Exception('Permission denied for storage');
    }
  }
  @override
  void dispose() {
    recorder.closeRecorder();
    super.dispose();
  }

  final recorder = FlutterSoundRecorder();

  Future initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw 'Permission not granted';
    }
    await recorder.openRecorder();
    recorder.setSubscriptionDuration(const Duration(milliseconds: 500));
  }
  Future<String?> getExternalStoragePath() async {
    Directory? directory;
    try {
      directory = await getExternalStorageDirectory();
    } catch (e) {
      print('Failed to get external storage directory: $e');
    }
    String? path = directory?.path;
    return path;
  }

  Future startRecord() async {
    String? externalStoragePath = await getExternalStoragePath();
    if (externalStoragePath == null) {
      throw Exception('External storage path not found');
    }
    String path = '$externalStoragePath/audio.wav';
    await recorder.startRecorder(toFile: path);
  }

  Future stopRecorder() async {
    final filePath = await recorder.stopRecorder();
    final file = File(filePath!);
    print('Recorded file path: $filePath');

    String? externalStoragePath = await getExternalStoragePath();
    if (externalStoragePath == null) {
      throw Exception('External storage path not found');
    }
    String destinationPath = '$externalStoragePath/audio.wav';
    await file.copy(destinationPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.teal.shade700,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StreamBuilder<RecordingDisposition>(
                builder: (context, snapshot) {
                  final duration = snapshot.hasData
                      ? snapshot.data!.duration
                      : Duration.zero;

                  String twoDigits(int n) => n.toString().padLeft(2, '0');

                  final twoDigitMinutes =
                      twoDigits(duration.inMinutes.remainder(60));
                  final twoDigitSeconds =
                      twoDigits(duration.inSeconds.remainder(60));

                  return Text(
                    '$twoDigitMinutes:$twoDigitSeconds',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
                stream: recorder.onProgress,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (recorder.isRecording) {
                    await stopRecorder();
                    setState(() {});
                  } else {
                    await startRecord();
                    setState(() {});
                  }
                },
                child: Icon(
                  recorder.isRecording ? Icons.stop : Icons.mic,
                  size: 100,
                ),
              ),
            ],
          ),
        ));
  }
}
