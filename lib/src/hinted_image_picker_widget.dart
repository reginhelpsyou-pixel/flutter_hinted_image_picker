import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'picker_shape.dart';

/// A tappable widget that shows [hintWidget] or [hintAssetPath] (lightened,
/// with a centered [overlayIcon]) before an image is picked, and a thumbnail
/// of the picked image afterward.
///
/// Wraps [ImagePicker] from the `image_picker` package. Rendering uses
/// [Image.memory] rather than [Image.file], so it works on web without any
/// `dart:io` dependency.
///
/// ```dart
/// HintedImagePicker(
///   hintAssetPath: 'assets/hint.png',
///   size: 120,
///   shape: PickerShape.circle,
///   onImagePicked: (file) => print(file.path),
/// )
/// ```
///
/// See the package README for required platform permission setup (iOS
/// `Info.plist`, Android `minSdkVersion`, macOS entitlements).
///
/// For multi-image selection, see [HintedMultiImagePicker].
class HintedImagePicker extends StatefulWidget {
  /// Creates a [HintedImagePicker].
  ///
  /// Either [hintWidget] or [hintAssetPath] must be provided.
  const HintedImagePicker({
    super.key,
    this.hintWidget,
    this.hintAssetPath,
    this.size = 100,
    this.shape = PickerShape.circle,
    this.borderRadius,
    this.border,
    this.source,
    this.showSourceSelector = true,
    this.allowRemove = true,
    this.enabled = true,
    this.imageQuality = 85,
    this.maxWidth,
    this.maxHeight,
    this.elevation = 1,
    this.hoverElevation = 4,
    this.splashColor,
    this.hoverColor,
    this.overlayIcon = Icons.image_outlined,
    this.overlayIconColor,
    this.overlayIconSize,
    this.hintLightenAmount = 0.4,
    this.onImagePicked,
    this.onImageRemoved,
    this.onError,
  })  : assert(
          hintWidget != null || hintAssetPath != null,
          'Provide either hintWidget or hintAssetPath',
        ),
        assert(
          hintLightenAmount >= 0 && hintLightenAmount <= 1,
          'hintLightenAmount must be between 0 and 1',
        );

  /// Custom widget shown before an image is picked. Takes priority over [hintAssetPath].
  final Widget? hintWidget;

  /// Asset path used as hint if [hintWidget] is not provided.
  final String? hintAssetPath;

  /// Width and height of the picker (square bounding box).
  final double size;

  /// Visual shape of the picker: circle, rounded, or square.
  final PickerShape shape; 

  /// Only used when [shape] is [PickerShape.rounded]. Defaults to a 12px radius.
  final BorderRadius? borderRadius;

  /// Optional border drawn around the picker.
  final BoxBorder? border;

  /// If null and [showSourceSelector] is true, the user picks a source via a
  /// bottom sheet. If null and [showSourceSelector] is false, defaults to
  /// [ImageSource.gallery].
  final ImageSource? source;

  /// Whether tapping opens a camera/gallery selector sheet when [source] is null.
  final bool showSourceSelector;

  /// Whether a remove ("×") button is shown once an image is picked.
  final bool allowRemove;

  /// Disables tap interaction (and dims nothing automatically — style via
  /// [hintWidget]/theme if you want a visual disabled state) when false.
  final bool enabled;

  /// Compression quality (0–100) passed through to `image_picker`.
  final int? imageQuality;

  /// Max width passed through to `image_picker`. Image is scaled down to fit,
  /// aspect ratio preserved.
  final double? maxWidth;

  /// Max height passed through to `image_picker`. Image is scaled down to fit,
  /// aspect ratio preserved.
  final double? maxHeight;

  /// Base shadow elevation at rest.
  final double elevation;

  /// Shadow elevation on hover (desktop/web pointer devices only — touch
  /// devices never trigger hover).
  final double hoverElevation;

  /// Color of the ink splash on tap. Defaults to the theme's splash color.
  final Color? splashColor;

  /// Color of the hover highlight. Defaults to `Colors.black` at 4% opacity.
  final Color? hoverColor;

  /// Icon shown centered over the hint image. Only shown in the "no image
  /// picked" state — hidden once a thumbnail is showing.
  final IconData overlayIcon;

  /// Color of [overlayIcon]. Defaults to `Theme.of(context).colorScheme.primary`.
  final Color? overlayIconColor;

  /// Size of [overlayIcon]. Defaults to roughly a third of [size].
  final double? overlayIconSize;

  /// How much the hint (only the hint, not the thumbnail) is lightened, via a
  /// white overlay at this opacity. Range `0.0`–`1.0`.
  final double hintLightenAmount;

  /// Called with the picked file once selection succeeds.
  final ValueChanged<XFile>? onImagePicked;

  /// Called when the remove ("×") button is tapped, clearing the current selection.
  final VoidCallback? onImageRemoved;

  /// Called if `image_picker` throws (e.g. permission denied).
  final ValueChanged<Object>? onError;

  @override
  State<HintedImagePicker> createState() => _HintedImagePickerState();
}

class _HintedImagePickerState extends State<HintedImagePicker> {
  final ImagePicker _picker = ImagePicker();

  XFile? _pickedFile;
  Uint8List? _pickedBytes;
  bool _isLoading = false;
  bool _isHovering = false;

  Future<void> _handleTap() async {
    if (!widget.enabled || _isLoading) return;

    final source = widget.source ??
        (widget.showSourceSelector ? await _showSourceSheet() : ImageSource.gallery);

    if (source == null) return; // user dismissed the sheet

    await _pickImage(source);
  }

  Future<ImageSource?> _showSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoading = true);
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: widget.imageQuality,
        maxWidth: widget.maxWidth,
        maxHeight: widget.maxHeight,
      );

      if (file == null) {
        setState(() => _isLoading = false);
        return;
      }

      final bytes = await file.readAsBytes();

      if (!mounted) return;
      setState(() {
        _pickedFile = file;
        _pickedBytes = bytes;
        _isLoading = false;
      });

      widget.onImagePicked?.call(file);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      widget.onError?.call(e);
    }
  }

  void _removeImage() {
    setState(() {
      _pickedFile = null;
      _pickedBytes = null;
    });
    widget.onImageRemoved?.call();
  }

  // BorderRadius _resolveBorderRadius() {
  //   switch (widget.shape) {
  //     case PickerShape.circle:
  //       return BorderRadius.circular(widget.size);
  //     case PickerShape.square:
  //       return BorderRadius.zero;
  //     case PickerShape.rounded:
  //       return widget.borderRadius ?? BorderRadius.circular(12);
  //   }
  // }

  ShapeBorder _resolveMaterialShape() {
    switch (widget.shape) {
      case PickerShape.circle:
        return const CircleBorder();
      case PickerShape.square:
        return const RoundedRectangleBorder();
      case PickerShape.rounded:
        return RoundedRectangleBorder(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        );
    }
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pickedBytes != null) {
      return Image.memory(
        _pickedBytes!,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
      );
    }

    final baseHint = widget.hintWidget ??
        Image.asset(
          widget.hintAssetPath!,
          fit: BoxFit.cover,
          width: widget.size,
          height: widget.size,
        );

    return Stack(
      fit: StackFit.expand,
      children: [
        baseHint,
        if (widget.hintLightenAmount > 0)
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(widget.hintLightenAmount)),
          ),
        Center(
          child: Icon(
            widget.overlayIcon,
            size: widget.overlayIconSize ?? widget.size / 3,
            color: widget.overlayIconColor ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // final radius = _resolveBorderRadius();
    final materialShape = _resolveMaterialShape();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(border: widget.border),
          child: Material(
            elevation: _isHovering ? widget.hoverElevation : widget.elevation,
            shape: materialShape,
            clipBehavior: Clip.antiAlias,
            color: Theme.of(context).colorScheme.surface,
            child: InkWell(
              onTap: widget.enabled ? _handleTap : null,
              onHover: widget.enabled
                  ? (hovering) => setState(() => _isHovering = hovering)
                  : null,
              customBorder: materialShape,
              splashColor: widget.splashColor,
              hoverColor: widget.hoverColor ?? Colors.black.withOpacity(0.04),
              child: _buildContent(context),
            ),
          ),
        ),
        if (_pickedFile != null && widget.allowRemove && !_isLoading)
          Positioned(
            top: -4,
            right: -4,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _removeImage,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Like [HintedImagePicker] but for multi-image selection via
/// [ImagePicker.pickMultiImage].
///
/// Shows the first picked image as the thumbnail, with a `+N` badge in the
/// bottom-right corner indicating how many additional images were selected
/// (`N` = total count minus one, not the raw total).
///
/// Tapping the widget again **replaces** the entire selection rather than
/// appending to it — this mirrors `pickMultiImage`'s underlying platform
/// behavior, which always returns a fresh full selection. If you need
/// per-image review or removal, use [onImagesPicked]'s `List<XFile>` to
/// drive a separate full-screen gallery UI; this widget is a compact
/// preview, not a selection manager.
///
/// ```dart
/// HintedMultiImagePicker(
///   hintAssetPath: 'assets/hint.png',
///   size: 120,
///   shape: PickerShape.rounded,
///   maxImages: 10,
///   onImagesPicked: (files) => print('${files.length} images picked'),
/// )
/// ```
class HintedMultiImagePicker extends StatefulWidget {
  /// Creates a [HintedMultiImagePicker].
  ///
  /// Either [hintWidget] or [hintAssetPath] must be provided.
  const HintedMultiImagePicker({
    super.key,
    this.hintWidget,
    this.hintAssetPath,
    this.size = 100,
    this.shape = PickerShape.circle,
    this.borderRadius,
    this.border,
    this.allowRemove = true,
    this.enabled = true,
    this.imageQuality = 85,
    this.maxWidth,
    this.maxHeight,
    this.maxImages,
    this.elevation = 1,
    this.hoverElevation = 4,
    this.splashColor,
    this.hoverColor,
    this.overlayIcon = Icons.image_outlined,
    this.overlayIconColor,
    this.overlayIconSize,
    this.hintLightenAmount = 0.4,
    this.badgeColor,
    this.badgeTextStyle,
    this.onImagesPicked,
    this.onImagesCleared,
    this.onError,
  })  : assert(
          hintWidget != null || hintAssetPath != null,
          'Provide either hintWidget or hintAssetPath',
        ),
        assert(
          hintLightenAmount >= 0 && hintLightenAmount <= 1,
          'hintLightenAmount must be between 0 and 1',
        );

  /// Custom widget shown before any images are picked. Takes priority over [hintAssetPath].
  final Widget? hintWidget;

  /// Asset path used as hint if [hintWidget] is not provided.
  final String? hintAssetPath;

  /// Width and height of the picker (square bounding box).
  final double size;

  /// Visual shape of the picker: circle, rounded, or square.
  final PickerShape shape;

  /// Only used when [shape] is [PickerShape.rounded]. Defaults to a 12px radius.
  final BorderRadius? borderRadius;

  /// Optional border drawn around the picker.
  final BoxBorder? border;

  /// Whether a clear-all ("×") button is shown once images are picked.
  final bool allowRemove;

  /// Disables tap interaction when false.
  final bool enabled;

  /// Compression quality (0–100) passed through to `image_picker`.
  final int? imageQuality;

  /// Max width passed through to `image_picker` for every picked image.
  final double? maxWidth;

  /// Max height passed through to `image_picker` for every picked image.
  final double? maxHeight;

  /// Caps how many images `pickMultiImage` returns/keeps. Null = no cap.
  final int? maxImages;

  /// Base shadow elevation at rest.
  final double elevation;

  /// Shadow elevation on hover (desktop/web pointer devices only).
  final double hoverElevation;

  /// Color of the ink splash on tap. Defaults to the theme's splash color.
  final Color? splashColor;

  /// Color of the hover highlight. Defaults to `Colors.black` at 4% opacity.
  final Color? hoverColor;

  /// Icon shown centered over the hint image. Only shown before any images are picked.
  final IconData overlayIcon;

  /// Color of [overlayIcon]. Defaults to `Theme.of(context).colorScheme.primary`.
  final Color? overlayIconColor;

  /// Size of [overlayIcon]. Defaults to roughly a third of [size].
  final double? overlayIconSize;

  /// How much the hint is lightened via a white overlay at this opacity. Range `0.0`–`1.0`.
  final double hintLightenAmount;

  /// Background color of the "+N" count badge. Defaults to `Colors.black54`.
  final Color? badgeColor;

  /// Text style of the "+N" badge label. Defaults to white, 11px, semi-bold.
  final TextStyle? badgeTextStyle;

  /// Fires with the full current selection every time it changes — i.e. after
  /// every successful pick, not incrementally. See class docs: a new pick
  /// replaces rather than appends to the previous selection.
  final ValueChanged<List<XFile>>? onImagesPicked;

  /// Called when the clear-all ("×") button is tapped.
  final VoidCallback? onImagesCleared;

  /// Called if `image_picker` throws (e.g. permission denied).
  final ValueChanged<Object>? onError;

  @override
  State<HintedMultiImagePicker> createState() => _HintedMultiImagePickerState();
}

class _HintedMultiImagePickerState extends State<HintedMultiImagePicker> {
  final ImagePicker _picker = ImagePicker();

  final List<XFile> _pickedFiles = [];
  Uint8List? _firstImageBytes;
  bool _isLoading = false;
  bool _isHovering = false;

  Future<void> _handleTap() async {
    if (!widget.enabled || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      final files = await _picker.pickMultiImage(
        imageQuality: widget.imageQuality,
        maxWidth: widget.maxWidth,
        maxHeight: widget.maxHeight,
        limit: widget.maxImages,
      );

      if (files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final bytes = await files.first.readAsBytes();

      if (!mounted) return;
      setState(() {
        _pickedFiles
          ..clear()
          ..addAll(files);
        _firstImageBytes = bytes;
        _isLoading = false;
      });

      widget.onImagesPicked?.call(List.unmodifiable(_pickedFiles));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      widget.onError?.call(e);
    }
  }

  void _clearAll() {
    setState(() {
      _pickedFiles.clear();
      _firstImageBytes = null;
    });
    widget.onImagesCleared?.call();
  }

  // BorderRadius _resolveBorderRadius() {
  //   switch (widget.shape) {
  //     case PickerShape.circle:
  //       return BorderRadius.circular(widget.size);
  //     case PickerShape.square:
  //       return BorderRadius.zero;
  //     case PickerShape.rounded:
  //       return widget.borderRadius ?? BorderRadius.circular(12);
  //   }
  // }

  ShapeBorder _resolveMaterialShape() {
    switch (widget.shape) {
      case PickerShape.circle:
        return const CircleBorder();
      case PickerShape.square:
        return const RoundedRectangleBorder();
      case PickerShape.rounded:
        return RoundedRectangleBorder(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        );
    }
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_firstImageBytes != null) {
      final extraCount = _pickedFiles.length - 1;
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            _firstImageBytes!,
            fit: BoxFit.cover,
            width: widget.size,
            height: widget.size,
          ),
          if (extraCount > 0)
            Positioned(
              bottom: 4,
              right: 4,
              child: _CountBadge(
                count: extraCount,
                color: widget.badgeColor,
                textStyle: widget.badgeTextStyle,
              ),
            ),
        ],
      );
    }

    final baseHint = widget.hintWidget ??
        Image.asset(
          widget.hintAssetPath!,
          fit: BoxFit.cover,
          width: widget.size,
          height: widget.size,
        );

    return Stack(
      fit: StackFit.expand,
      children: [
        baseHint,
        if (widget.hintLightenAmount > 0)
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(widget.hintLightenAmount)),
          ),
        Center(
          child: Icon(
            widget.overlayIcon,
            size: widget.overlayIconSize ?? widget.size / 3,
            color: widget.overlayIconColor ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final materialShape = _resolveMaterialShape();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(border: widget.border),
          child: Material(
            elevation: _isHovering ? widget.hoverElevation : widget.elevation,
            shape: materialShape,
            clipBehavior: Clip.antiAlias,
            color: Theme.of(context).colorScheme.surface,
            child: InkWell(
              onTap: widget.enabled ? _handleTap : null,
              onHover: widget.enabled
                  ? (hovering) => setState(() => _isHovering = hovering)
                  : null,
              customBorder: materialShape,
              splashColor: widget.splashColor,
              hoverColor: widget.hoverColor ?? Colors.black.withOpacity(0.04),
              child: _buildContent(context),
            ),
          ),
        ),
        if (_pickedFiles.isNotEmpty && widget.allowRemove && !_isLoading)
          Positioned(
            top: -4,
            right: -4,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _clearAll,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Small pill showing "+N" (or "99+" past 99), used by [HintedMultiImagePicker]
/// to indicate how many images beyond the visible thumbnail were selected.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, this.color, this.textStyle});

  final int count;
  final Color? color;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '+$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? Colors.black54,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: textStyle ??
            const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}