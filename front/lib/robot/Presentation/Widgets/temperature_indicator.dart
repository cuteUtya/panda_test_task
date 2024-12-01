import 'package:flutter/material.dart';

class TemperatureIndicator extends StatelessWidget {
  final double? temperature;

  const TemperatureIndicator({super.key, required this.temperature});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 30,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xff4AC9F5),
                const Color(0xffF6FCFE),
                const Color(0xffFCE276),
                const Color(0xffF9681C),
              ],
            ),
          ),
        ),
        if (temperature != null)
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 0,
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              thumbShape: SquareSliderThumbShape(),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(value: temperature! / 100, onChanged: (v) {}),
          ),
      ],
    );
  }
}

class SquareSliderThumbShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(4, 30);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final Paint paint = Paint()..color = Colors.black;

    canvas.drawRect(Rect.fromLTWH(center.dx, center.dy - 10, 4, 30), paint);
  }
}
