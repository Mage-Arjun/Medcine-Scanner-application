import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medcam_app/app.dart';
import 'package:medcam_app/providers/shared_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(
    ProviderScope(
      overrides: [
        camerasProvider.overrideWithValue(cameras),
      ],
      child: const MedCamApp(),
    ),
  );
}
