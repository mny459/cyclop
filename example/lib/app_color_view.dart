import 'dart:math';
import 'dart:ui';

import 'package:cyclop/cyclop.dart';
import 'package:example/app_color_picker.dart';
import 'package:flutter/material.dart';

const _buttonSize = 48.0;
const defaultRadius = 8.0;

const defaultBorderRadius = BorderRadius.all(Radius.circular(defaultRadius));

class AppColorView extends StatefulWidget {
  final Widget child;
  final Color color;
  final ColorPickerConfig config;
  final Set<Color> swatches;

  final ValueChanged<Color> onColorChanged;

  final ValueChanged<Set<Color>>? onSwatchesChanged;

  const AppColorView({
    required this.child,
    required this.color,
    required this.onColorChanged,
    this.onSwatchesChanged,
    this.config = const ColorPickerConfig(),
    this.swatches = const {},
    Key? key,
  }) : super(key: key);

  @override
  _AppColorViewState createState() => _AppColorViewState();
}

class _AppColorViewState extends State<AppColorView>
    with WidgetsBindingObserver {
  OverlayEntry? pickerOverlay;

  late Color color;

  // hide the palette during eyedropping
  bool hidden = false;

  bool keyboardOn = false;

  double bottom = 30;

  @override
  void initState() {
    super.initState();
    color = widget.color;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(AppColorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) color = widget.color;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (details) => _colorPick(context, details),
        child: widget.child,
      );

  void _colorPick(BuildContext context, TapDownDetails details) async {
    final selectedColor =
        await showColorPicker(context, details.globalPosition);
    widget.onColorChanged(selectedColor);
  }

  Future<Color> showColorPicker(BuildContext rootContext, Offset offset) async {
    if (pickerOverlay != null) return Future.value(widget.color);

    pickerOverlay = _buildPickerOverlay(offset, rootContext);

    Overlay.of(rootContext)?.insert(pickerOverlay!);

    return Future.value(widget.color);
  }

  OverlayEntry _buildPickerOverlay(Offset offset, BuildContext context) {
    final mq = MediaQuery.of(context);
    final onLandscape =
        mq.size.shortestSide < 600 && mq.orientation == Orientation.landscape;
    final pickerPosition =
        onLandscape ? offset : calculatePickerPosition(offset, mq.size);

    return OverlayEntry(
      maintainState: true,
      builder: (c) {
        return _DraggablePicker(
          initialOffset: pickerPosition,
          bottom: bottom,
          keyboardOn: keyboardOn,
          child: IgnorePointer(
            ignoring: hidden,
            child: Opacity(
              opacity: hidden ? 0 : 1,
              child: Material(
                borderRadius: defaultBorderRadius,
                child: AppColorPicker(
                  config: widget.config,
                  selectedColor: color,
                  swatches: widget.swatches,
                  onClose: () {
                    pickerOverlay?.remove();
                    pickerOverlay = null;
                  },
                  onColorSelected: (c) {
                    color = c;
                    pickerOverlay?.markNeedsBuild();
                    widget.onColorChanged(c);
                  },
                  onSwatchesUpdate: widget.onSwatchesChanged,
                  onEyeDropper: () => _showEyeDropperOverlay(context),
                  onKeyboard: _onKeyboardOn,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Offset calculatePickerPosition(Offset offset, Size size) =>
      offset +
      Offset(
        _buttonSize,
        min(-pickerHeight / 2, size.height - pickerHeight - 50),
      );

  void _showEyeDropperOverlay(BuildContext context) {
    hidden = true;
    try {
      EyeDrop.of(context).capture(context, (value) {
        hidden = false;
        _onEyePick(value);
      }, null);
    } catch (err) {
      debugPrint('ERROR !!! _buildPickerOverlay $err');
    }
  }

  void _onEyePick(Color value) {
    color = value;
    widget.onColorChanged(value);
    pickerOverlay?.markNeedsBuild();
  }

  void _onKeyboardOn() {
    keyboardOn = true;
    pickerOverlay?.markNeedsBuild();
    setState(() {});
  }

  @override
  void didChangeMetrics() {
    final keyboardTopPixels =
        window.physicalSize.height - window.viewInsets.bottom;

    final newBottom = (window.physicalSize.height - keyboardTopPixels) /
        window.devicePixelRatio;

    setState(() => bottom = newBottom);
    pickerOverlay?.markNeedsBuild();
  }
}

class _DraggablePicker extends StatefulWidget {
  final Offset initialOffset;

  final Widget child;

  final double bottom;

  final bool keyboardOn;

  const _DraggablePicker({
    Key? key,
    required this.child,
    required this.initialOffset,
    required this.bottom,
    required this.keyboardOn,
  }) : super(key: key);

  @override
  State<_DraggablePicker> createState() => _DraggablePickerState();
}

class _DraggablePickerState extends State<_DraggablePicker> {
  late Offset offset;

  @override
  void initState() {
    super.initState();
    offset = widget.initialOffset;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;

    final onLandscape =
        mq.size.shortestSide < 600 && mq.orientation == Orientation.landscape;

    return Positioned(
      left: mq.isPhone
          ? (size.width - pickerWidth) / 2
          : offset.dx.clamp(0.0, size.width - pickerWidth),
      top: mq.isPhone
          ? onLandscape
              ? 0
              : (widget.keyboardOn ? 20 : (size.height - pickerHeight) / 2)
          : offset.dy.clamp(0.0, size.height - pickerHeight),
      bottom: mq.isPhone ? 20 + widget.bottom : null,
      child: GestureDetector(onPanUpdate: _onDrag, child: widget.child),
    );
  }

  void _onDrag(DragUpdateDetails details) =>
      setState(() => offset = offset + details.delta);
}
