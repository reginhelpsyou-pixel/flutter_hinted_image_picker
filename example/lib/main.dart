import 'package:flutter/material.dart';
import 'package:hinted_image_picker/hinted_image_picker.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  String _log = 'No action yet.';

  void _appendLog(String message) {
    setState(() => _log = message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hinted Image Picker Demo')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'Single image',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              HintedImagePicker(
                hintAssetPath: 'assets/hint.png',
                size: 120,
                shape: PickerShape.circle,
                onImagePicked: (file) => _appendLog('Picked: ${file.name}'),
                onImageRemoved: () => _appendLog('Single picker cleared'),
                onError: (e) => _appendLog('Error: $e'),
              ),

              const SizedBox(height: 40),

              const Text(
                'Multi image',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Shows first image + "+N" badge for the rest',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              HintedMultiImagePicker(
                hintAssetPath: 'assets/hint.png',
                size: 120,
                shape: PickerShape.rounded,
                maxImages: 10,
                onImagesPicked: (files) =>
                    _appendLog('Picked ${files.length} image(s)'),
                onImagesCleared: () => _appendLog('Multi picker cleared'),
                onError: (e) => _appendLog('Error: $e'),
              ),

              const SizedBox(height: 40),

              const Text(
                'Square shape, no lighten, custom icon',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              HintedImagePicker(
                hintAssetPath: 'assets/hint.png',
                size: 120,
                shape: PickerShape.square,
                hintLightenAmount: 0,
                overlayIcon: Icons.camera_alt_outlined,
                overlayIconColor: Colors.deepOrange,
                onImagePicked: (file) => _appendLog('Picked: ${file.name}'),
                onError: (e) => _appendLog('Error: $e'),
              ),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 12),
              Text(_log, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}