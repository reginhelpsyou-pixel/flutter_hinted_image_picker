import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hinted_image_picker/hinted_image_picker.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockImagePickerPlatform extends ImagePickerPlatform
    with MockPlatformInterfaceMixin {
  XFile? fileToReturn;
  Object? errorToThrow;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return fileToReturn;
  }
}

void main() {
  late MockImagePickerPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockImagePickerPlatform();
    ImagePickerPlatform.instance = mockPlatform;
  });

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows hint widget and default overlay icon when no image picked',
      (tester) async {
    await tester.pumpWidget(wrap(
      const HintedImagePicker(
        hintWidget: ColoredBox(color: Colors.grey),
        showSourceSelector: false,
        source: ImageSource.gallery,
      ),
    ));

    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows thumbnail after picking an image', (tester) async {
    mockPlatform.fileToReturn = XFile.fromData(
      Uint8List.fromList([0, 1, 2, 3]),
      name: 'test.png',
      mimeType: 'image/png',
    );

    XFile? pickedResult;

    await tester.pumpWidget(wrap(
      HintedImagePicker(
        hintWidget: const ColoredBox(color: Colors.grey),
        showSourceSelector: false,
        source: ImageSource.gallery,
        onImagePicked: (file) => pickedResult = file,
      ),
    ));

    await tester.tap(find.byType(HintedImagePicker));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.image_outlined), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(pickedResult, isNotNull);
    expect(pickedResult!.name, 'test.png');
  });

  testWidgets('calls onError when picker throws', (tester) async {
    mockPlatform.errorToThrow = Exception('permission denied');
    Object? capturedError;

    await tester.pumpWidget(wrap(
      HintedImagePicker(
        hintWidget: const ColoredBox(color: Colors.grey),
        showSourceSelector: false,
        source: ImageSource.gallery,
        onError: (e) => capturedError = e,
      ),
    ));

    await tester.tap(find.byType(HintedImagePicker));
    await tester.pumpAndSettle();

    expect(capturedError, isNotNull);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });

  testWidgets('remove button clears picked image', (tester) async {
    mockPlatform.fileToReturn = XFile.fromData(
      Uint8List.fromList([0, 1, 2, 3]),
      name: 'test.png',
      mimeType: 'image/png',
    );

    bool removed = false;

    await tester.pumpWidget(wrap(
      HintedImagePicker(
        hintWidget: const ColoredBox(color: Colors.grey),
        showSourceSelector: false,
        source: ImageSource.gallery,
        allowRemove: true,
        onImageRemoved: () => removed = true,
      ),
    ));

    await tester.tap(find.byType(HintedImagePicker));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(removed, isTrue);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });

  testWidgets('tap does nothing when disabled', (tester) async {
    await tester.pumpWidget(wrap(
      const HintedImagePicker(
        hintWidget: ColoredBox(color: Colors.grey),
        enabled: false,
        showSourceSelector: false,
        source: ImageSource.gallery,
      ),
    ));

    await tester.tap(find.byType(HintedImagePicker));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('custom overlay icon and color are applied', (tester) async {
    await tester.pumpWidget(wrap(
      const HintedImagePicker(
        hintWidget: ColoredBox(color: Colors.grey),
        showSourceSelector: false,
        source: ImageSource.gallery,
        overlayIcon: Icons.person,
        overlayIconColor: Colors.red,
      ),
    ));

    final iconFinder = find.byIcon(Icons.person);
    expect(iconFinder, findsOneWidget);
    final iconWidget = tester.widget<Icon>(iconFinder);
    expect(iconWidget.color, Colors.red);
  });
}