import 'package:cyclop/cyclop.dart';
import 'package:flutter/material.dart';

// const pickerWidth = 316.0;
//
// const pickerHeight = 520.0;
//
// const pickerSize = Size(pickerWidth, pickerHeight);

const defaultDivider = Divider(
  color: Color(0xff999999),
  indent: 8,
  height: 10,
  endIndent: 8,
);

/// ColorPicker Widget
/// 2 or 3 tabs :
/// - material swatches
/// - HSL and RGB sliders
/// - custom swatches
///
/// Customisable with a [ColorPickerConfig]
class AppColorPicker extends StatefulWidget {
  final Color selectedColor;

  /// custom swatches library
  final Set<Color> swatches;

  /// colorPicker configuration
  final ColorPickerConfig config;

  /// color selection callback
  final ValueChanged<Color> onColorSelected;

  /// open [EyeDrop] callback
  final VoidCallback? onEyeDropper;

  /// custom swatches update callabck
  final ValueChanged<Set<Color>>? onSwatchesUpdate;

  /// close colorPicker callback
  final VoidCallback onClose;

  final VoidCallback? onKeyboard;

  const AppColorPicker({
    required this.onColorSelected,
    required this.selectedColor,
    required this.config,
    required this.onClose,
    this.onEyeDropper,
    this.onKeyboard,
    this.onSwatchesUpdate,
    this.swatches = const {},
    Key? key,
  }) : super(key: key);

  @override
  _AppColorPickerState createState() => _AppColorPickerState();
}

class _AppColorPickerState extends State<AppColorPicker> {
  late FocusNode hexFieldFocus;

  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    hexFieldFocus = FocusNode();
    if (widget.onKeyboard != null) {
      hexFieldFocus.addListener(widget.onKeyboard!);
    }

    selectedColor = widget.selectedColor;
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.onKeyboard != null) {
      hexFieldFocus.removeListener(widget.onKeyboard!);
    }
    hexFieldFocus.dispose();
  }

  @override
  void didUpdateWidget(covariant AppColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedColor != widget.selectedColor) {
      selectedColor = widget.selectedColor;
    }
  }

  void onColorChanged(Color newColor) {
    widget.onColorSelected(newColor);
    setState(() => selectedColor = newColor);
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          constraints: BoxConstraints.loose(pickerSize),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            // boxShadow: largeDarkShadowBox,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                MainTitle(onClose: widget.onClose),
                Flexible(
                  fit: FlexFit.loose,
                  child: Tabs(
                    labels: [
                      'Material',
                      'Sliders',
                      if (widget.config.enableLibrary) 'Library'
                    ],
                    views: [
                      GridColorSelector(
                        selectedColor: selectedColor,
                        onColorSelected: onColorChanged,
                      ),
                      ChannelSliders(
                        selectedColor: selectedColor,
                        onChange: onColorChanged,
                      ),
                      if (widget.config.enableLibrary)
                        SwatchLibrary(
                          colors: widget.swatches,
                          currentColor: selectedColor,
                          onSwatchesUpdate: widget.onSwatchesUpdate,
                          onColorSelected: onColorChanged,
                        ),
                    ],
                  ),
                ),
                if (widget.config.enableOpacity)
                  RepaintBoundary(
                    child: OpacitySlider(
                      selectedColor: selectedColor,
                      opacity: selectedColor.opacity,
                      onChange: _onOpacityChange,
                    ),
                  ),
                defaultDivider,
                ColorSelector(
                  color: selectedColor,
                  withAlpha: widget.config.enableOpacity,
                  thumbWidth: 96,
                  onColorChanged: widget.onColorSelected,
                  onEyePick: widget.config.enableEyePicker
                      ? widget.onEyeDropper
                      : null,
                  focus: hexFieldFocus,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onOpacityChange(double value) =>
      widget.onColorSelected(widget.selectedColor.withOpacity(value));
}
