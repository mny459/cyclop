import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class OpacitySliderTrack extends SliderTrackShape with BaseSliderTrackShape {
  final Color selectedColor;

  final Paint gridPaint;

  OpacitySliderTrack(this.selectedColor, {required ui.Image gridImage})
      : gridPaint = Paint()
          ..shader = ImageShader(
            gridImage,
            TileMode.repeated,
            TileMode.repeated,
            Matrix4.identity().storage,
          );

  @override
  void paint(PaintingContext context, ui.Offset offset,
      {required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required Animation<double> enableAnimation,
      required ui.Offset thumbCenter,
      ui.Offset? secondaryOffset,
      bool isEnabled = false,
      bool isDiscrete = false,
      required ui.TextDirection textDirection}) {
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final trackRadius = Radius.circular(trackRect.height / 2);
    final activeTrackRadius = Radius.circular(trackRect.height / 2 + 1);

    final activePaint = Paint()..color = Colors.transparent;

    final inactivePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(trackRect.width, 0),
        [selectedColor.withOpacity(0), selectedColor.withOpacity(1)],
        [0.05, 0.95],
      );

    Paint leftTrackPaint;
    Paint rightTrackPaint;
    switch (textDirection) {
      case TextDirection.ltr:
        leftTrackPaint = activePaint;
        rightTrackPaint = inactivePaint;
        break;
      case TextDirection.rtl:
        leftTrackPaint = inactivePaint;
        rightTrackPaint = activePaint;
        break;
    }

    const thumbRadius = 14;

    final shapeRect = RRect.fromLTRBAndCorners(
      trackRect.left - thumbRadius,
      (textDirection == TextDirection.ltr) ? trackRect.top : trackRect.top,
      trackRect.right + thumbRadius,
      (textDirection == TextDirection.ltr)
          ? trackRect.bottom
          : trackRect.bottom,
      topLeft: (textDirection == TextDirection.ltr)
          ? activeTrackRadius
          : trackRadius,
      bottomLeft: (textDirection == TextDirection.ltr)
          ? activeTrackRadius
          : trackRadius,
      topRight: (textDirection == TextDirection.ltr)
          ? activeTrackRadius
          : trackRadius,
      bottomRight: (textDirection == TextDirection.ltr)
          ? activeTrackRadius
          : trackRadius,
    );

    context.canvas.drawRRect(shapeRect, leftTrackPaint);
    context.canvas.drawRRect(shapeRect, gridPaint);

    context.canvas.drawRRect(shapeRect, rightTrackPaint);
  }
}
