# hinted_image_picker

A Flutter widget that wraps [`image_picker`](https://pub.dev/packages/image_picker) to show a customizable hint image before selection and a thumbnail after — with `InkWell` ripple, hover elevation, and a lightened hint overlay with a pickable icon. Includes a multi-image variant with a `+N` count badge.

|                | Single | Multi |
|----------------|--------|-------|
| Hint state     | ✅     | ✅    |
| Thumbnail      | ✅     | ✅ (first image) |
| `+N` badge     | —      | ✅    |
| Ripple / hover / elevation | ✅ | ✅ |

## Features

- Lightened hint image with a centered, customizable overlay icon
- Thumbnail preview after picking (`Image.memory`, web-safe — no `dart:io`)
- `InkWell` ripple + hover elevation on desktop/web pointer devices
- Circle, rounded, or square shape
- Source selector (camera/gallery) bottom sheet, or force a single source
- Multi-image picker with a `+N` badge showing how many additional images were selected
- Remove/clear button

## Installation

```yaml
dependencies:
  hinted_image_picker: ^0.1.0
```

```bash
flutter pub get
```

## Platform setup

This package uses `image_picker` under the hood, which requires platform-specific permission declarations in the **app that consumes this package** — not in the package itself.

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to let you pick an image.</string>
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to let you take a photo.</string>
```

### Android

`image_picker` handles runtime permissions automatically on modern Android. Confirm `minSdkVersion` is 21+ in `android/app/build.gradle`.

### macOS

Add to both `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`:

```xml
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
```

### Web

No extra setup — picking works via the browser's file input. Camera capture support depends on the browser.

## Usage

### Single image picker

```dart
import 'package:hinted_image_picker/hinted_image_picker.dart';

HintedImagePicker(
  hintAssetPath: 'assets/hint.png',
  size: 120,
  shape: PickerShape.circle,
  overlayIcon: Icons.camera_alt_outlined, // default: Icons.image_outlined
  overlayIconColor: Colors.blue,          // default: Theme primary color
  hintLightenAmount: 0.4,                 // 0.0–1.0
  onImagePicked: (file) => print(file.path),
  onImageRemoved: () => print('cleared'),
  onError: (e) => print('error: $e'),
)
```

### Multi image picker

```dart
HintedMultiImagePicker(
  hintAssetPath: 'assets/hint.png',
  size: 120,
  shape: PickerShape.rounded,
  maxImages: 10,
  onImagesPicked: (files) => print('${files.length} images picked'),
  onImagesCleared: () => print('cleared'),
  onError: (e) => print('error: $e'),
)
```

The multi picker shows the **first** selected image as the thumbnail with a `+N` badge in the bottom-right corner, where `N` is the number of *additional* images (total minus one), not the raw total.

Tapping the widget again **replaces** the entire selection — it does not append to the existing one. This mirrors the underlying `pickMultiImage` platform behavior, which always returns a fresh full selection rather than an incremental one. If you need per-image review or removal, use `onImagesPicked`'s `List<XFile>` to drive a separate full-screen gallery UI; this widget is a compact preview, not a selection manager.

### Custom hint widget instead of an asset

```dart
HintedImagePicker(
  hintWidget: Icon(Icons.person, size: 48),
  // ...
)
```

Either `hintAssetPath` or `hintWidget` is required — an assertion fires at construction if neither is provided. The lighten overlay and overlay icon are applied on top of whichever hint you pass, including custom widgets.

## API reference

Both widgets share the same visual/interaction configuration.

| Property | Type | Default | Description |
|---|---|---|---|
| `hintWidget` / `hintAssetPath` | `Widget?` / `String?` | — | One is required. Shown before an image is picked. |
| `size` | `double` | `100` | Width/height of the picker (square bounding box). |
| `shape` | `PickerShape` | `circle` | `circle`, `rounded`, or `square`. |
| `borderRadius` | `BorderRadius?` | `12` (rounded only) | Only used when `shape` is `rounded`. |
| `border` | `BoxBorder?` | `null` | Optional border decoration. |
| `allowRemove` | `bool` | `true` | Shows an "×" button to clear the selection. |
| `enabled` | `bool` | `true` | Disables tap interaction when `false`. |
| `imageQuality` | `int?` | `85` | Passed through to `image_picker`. |
| `maxWidth` / `maxHeight` | `double?` | `null` | Passed through to `image_picker`. |
| `elevation` / `hoverElevation` | `double` | `1` / `4` | Shadow depth at rest / on hover (desktop, web). |
| `splashColor` / `hoverColor` | `Color?` | theme default / `black 4%` | `InkWell` interaction colors. |
| `overlayIcon` | `IconData` | `Icons.image_outlined` | Icon centered over the hint. |
| `overlayIconColor` | `Color?` | `Theme.of(context).colorScheme.primary` | Overlay icon color. |
| `overlayIconSize` | `double?` | `size / 3` | Overlay icon size. |
| `hintLightenAmount` | `double` | `0.4` | White overlay opacity on the hint, `0.0`–`1.0`. |
| `onError` | `ValueChanged<Object>?` | `null` | Called if `image_picker` throws. |

### `HintedImagePicker`-only

| Property | Type | Default | Description |
|---|---|---|---|
| `source` | `ImageSource?` | `null` | Forces a single source; skips the selector sheet. |
| `showSourceSelector` | `bool` | `true` | Show camera/gallery bottom sheet when `source` is `null`. |
| `onImagePicked` | `ValueChanged<XFile>?` | `null` | Called with the picked file. |
| `onImageRemoved` | `VoidCallback?` | `null` | Called when the "×" button is tapped. |

### `HintedMultiImagePicker`-only

| Property | Type | Default | Description |
|---|---|---|---|
| `maxImages` | `int?` | `null` | Caps how many images can be returned. `null` = no cap. |
| `badgeColor` | `Color?` | `black54` | Background color of the `+N` badge. |
| `badgeTextStyle` | `TextStyle?` | white, 11px, w600 | Text style of the badge label. |
| `onImagesPicked` | `ValueChanged<List<XFile>>?` | `null` | Called with the **full current selection** on every pick. |
| `onImagesCleared` | `VoidCallback?` | `null` | Called when the "×" button is tapped. |

## Testing

The widget tests in this repo mock `image_picker`'s platform interface (`ImagePickerPlatform.instance`) rather than the `ImagePicker` class directly, since that's the layer `image_picker` itself is built to be swapped at. See `test/hinted_image_picker_test.dart` for a working example using `image_picker_platform_interface` and `plugin_platform_interface`.

Run:

```bash
flutter test
```

## Example app

The `example/` app demonstrates both widgets side by side, including a square-shape/no-lighten/custom-icon variant. Run it with:

```bash
cd example
flutter run
```

## License

See [LICENSE](LICENSE).