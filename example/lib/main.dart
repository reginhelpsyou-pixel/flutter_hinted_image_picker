import 'package:flutter/material.dart';
import 'package:hinted_image_picker/hinted_image_picker.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hinted Image Picker',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
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
  // Live-tunable settings, shared by the "Playground" section.
  PickerShape _shape = PickerShape.circle;
  double _size = 120;
  double _hintLighten = 0.4;
  IconData _overlayIcon = Icons.image_outlined;
  Color _overlayColor = Colors.deepPurple;
  bool _allowRemove = true;

  final List<String> _log = [];

  void _pushLog(String message) {
    setState(() {
      _log.insert(0, message);
      if (_log.length > 6) _log.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('hinted_image_picker'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionHeader(
              title: 'Playground',
              subtitle: 'Tweak the controls below, tap the picker to test',
            ),
            const SizedBox(height: 16),
            Center(
              child: HintedImagePicker(
                key: ValueKey('$_shape-$_size-$_hintLighten-$_overlayIcon-$_overlayColor-$_allowRemove'),
                hintAssetPath: 'assets/hint.png',
                size: _size,
                shape: _shape,
                hintLightenAmount: _hintLighten,
                overlayIcon: _overlayIcon,
                overlayIconColor: _overlayColor,
                allowRemove: _allowRemove,
                onImagePicked: (file) => _pushLog('Playground: picked ${file.name}'),
                onImageRemoved: () => _pushLog('Playground: cleared'),
                onError: (e) => _pushLog('Playground: error $e'),
              ),
            ),
            const SizedBox(height: 24),
            _PlaygroundControls(
              shape: _shape,
              onShapeChanged: (v) => setState(() => _shape = v),
              size: _size,
              onSizeChanged: (v) => setState(() => _size = v),
              hintLighten: _hintLighten,
              onHintLightenChanged: (v) => setState(() => _hintLighten = v),
              overlayIcon: _overlayIcon,
              onOverlayIconChanged: (v) => setState(() => _overlayIcon = v),
              overlayColor: _overlayColor,
              onOverlayColorChanged: (v) => setState(() => _overlayColor = v),
              allowRemove: _allowRemove,
              onAllowRemoveChanged: (v) => setState(() => _allowRemove = v),
            ),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),

            _SectionHeader(
              title: 'Multi-image picker',
              subtitle: 'First image shown as thumbnail, "+N" badge for the rest',
            ),
            const SizedBox(height: 16),
            Center(
              child: HintedMultiImagePicker(
                hintAssetPath: 'assets/hint.png',
                size: 120,
                shape: PickerShape.rounded,
                maxImages: 10,
                onImagesPicked: (files) =>
                    _pushLog('Multi: picked ${files.length} image(s)'),
                onImagesCleared: () => _pushLog('Multi: cleared'),
                onError: (e) => _pushLog('Multi: error $e'),
              ),
            ),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),

            _SectionHeader(
              title: 'Shape variants',
              subtitle: 'Same picker, three shapes, side by side',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _LabeledPicker(
                  label: 'circle',
                  child: HintedImagePicker(
                    hintAssetPath: 'assets/hint.png',
                    size: 90,
                    shape: PickerShape.circle,
                    onImagePicked: (f) => _pushLog('Circle: picked ${f.name}'),
                  ),
                ),
                _LabeledPicker(
                  label: 'rounded',
                  child: HintedImagePicker(
                    hintAssetPath: 'assets/hint.png',
                    size: 90,
                    shape: PickerShape.rounded,
                    onImagePicked: (f) => _pushLog('Rounded: picked ${f.name}'),
                  ),
                ),
                _LabeledPicker(
                  label: 'square',
                  child: HintedImagePicker(
                    hintAssetPath: 'assets/hint.png',
                    size: 90,
                    shape: PickerShape.square,
                    onImagePicked: (f) => _pushLog('Square: picked ${f.name}'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),

            _SectionHeader(
              title: 'Forced source, no lighten',
              subtitle: 'Camera-only, sharp hint, custom overlay',
            ),
            const SizedBox(height: 16),
            Center(
              child: HintedImagePicker(
                hintAssetPath: 'assets/hint.png',
                size: 120,
                shape: PickerShape.square,
                source: ImageSource.camera,
                showSourceSelector: false,
                hintLightenAmount: 0,
                overlayIcon: Icons.camera_alt_outlined,
                overlayIconColor: Colors.deepOrange,
                onImagePicked: (f) => _pushLog('Camera-only: picked ${f.name}'),
                onError: (e) => _pushLog('Camera-only: error $e'),
              ),
            ),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),

            _SectionHeader(title: 'Activity log', subtitle: 'Last 6 events'),
            const SizedBox(height: 12),
            _ActivityLog(entries: _log),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _LabeledPicker extends StatelessWidget {
  const _LabeledPicker({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        child,
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _ActivityLog extends StatelessWidget {
  const _ActivityLog({required this.entries});

  final List<String> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Nothing yet — try picking an image above.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(entry, style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

class _PlaygroundControls extends StatelessWidget {
  const _PlaygroundControls({
    required this.shape,
    required this.onShapeChanged,
    required this.size,
    required this.onSizeChanged,
    required this.hintLighten,
    required this.onHintLightenChanged,
    required this.overlayIcon,
    required this.onOverlayIconChanged,
    required this.overlayColor,
    required this.onOverlayColorChanged,
    required this.allowRemove,
    required this.onAllowRemoveChanged,
  });

  final PickerShape shape;
  final ValueChanged<PickerShape> onShapeChanged;
  final double size;
  final ValueChanged<double> onSizeChanged;
  final double hintLighten;
  final ValueChanged<double> onHintLightenChanged;
  final IconData overlayIcon;
  final ValueChanged<IconData> onOverlayIconChanged;
  final Color overlayColor;
  final ValueChanged<Color> onOverlayColorChanged;
  final bool allowRemove;
  final ValueChanged<bool> onAllowRemoveChanged;

  static const _icons = [
    Icons.image_outlined,
    Icons.camera_alt_outlined,
    Icons.person_outline,
    Icons.add_a_photo_outlined,
  ];

  static const _colors = [
    Colors.deepPurple,
    Colors.teal,
    Colors.deepOrange,
    Colors.blue,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shape', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<PickerShape>(
            segments: const [
              ButtonSegment(value: PickerShape.circle, label: Text('Circle')),
              ButtonSegment(value: PickerShape.rounded, label: Text('Rounded')),
              ButtonSegment(value: PickerShape.square, label: Text('Square')),
            ],
            selected: {shape},
            onSelectionChanged: (s) => onShapeChanged(s.first),
          ),

          const SizedBox(height: 20),
          Text('Size: ${size.round()}px', style: Theme.of(context).textTheme.labelLarge),
          Slider(
            value: size,
            min: 60,
            max: 200,
            onChanged: onSizeChanged,
          ),

          const SizedBox(height: 12),
          Text(
            'Hint lighten: ${(hintLighten * 100).round()}%',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Slider(
            value: hintLighten,
            onChanged: onHintLightenChanged,
          ),

          const SizedBox(height: 12),
          Text('Overlay icon', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final icon in _icons)
                ChoiceChip(
                  label: Icon(icon, size: 18),
                  selected: overlayIcon == icon,
                  onSelected: (_) => onOverlayIconChanged(icon),
                ),
            ],
          ),

          const SizedBox(height: 12),
          Text('Overlay color', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final color in _colors)
                GestureDetector(
                  onTap: () => onOverlayColorChanged(color),
                  child: CircleAvatar(
                    backgroundColor: color,
                    radius: 14,
                    child: overlayColor == color
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Allow remove'),
            value: allowRemove,
            onChanged: onAllowRemoveChanged,
          ),
        ],
      ),
    );
  }
}