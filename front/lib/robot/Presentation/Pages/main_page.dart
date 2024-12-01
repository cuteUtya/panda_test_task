import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panda_test_task/robot/Data/Model/robot_command.dart';
import 'package:panda_test_task/robot/Data/Model/robot_state.dart';
import 'package:panda_test_task/robot/Presentation/Providers/robot_provider.dart';

import 'dart:ui' as ui;

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState {
  Offset? mousePosition;
  Offset? robotPinPosition;

  Offset? oldPosition;

  var r = robotProvider();
  RobotState? robotState;

  @override
  void initState() {
    ref.read(r.notifier).sendCommand(RobotCommandStart());
    ref.read(r.notifier).sendCommand(RobotCommandChangeSpeed(value: 10));
    super.initState();
  }

  Future<ui.Image> _load(String path) async {
    final ByteData assetImageByteData = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      assetImageByteData.buffer.asUint8List(),
      targetHeight: 50,
      targetWidth: 50,
    );
    return (await codec.getNextFrame()).image;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(r, (oldState, newState) {
      oldPosition = oldState?.position;
      setState(() => robotState = newState);
    });

    var screenH = MediaQuery.of(context).size.height;
    var workingArea = screenH;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Robot speed: ${robotState?.speed.toStringAsFixed(2)}'),
                Slider(
                  padding: EdgeInsets.zero,
                  value: (robotState?.speed ?? 0) / 200,
                  onChanged: (v) {
                    ref
                        .read(r.notifier)
                        .sendCommand(RobotCommandChangeSpeed(value: v * 200));
                  },
                ),
                const SizedBox(height: 32),

                //TODO: move to separate widget
                Text('Robot temperature: ${robotState?.temperature}°'),
                Stack(
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
                    if (robotState != null)
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 0,
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                          thumbShape: SquareSliderThumbShape(),
                          overlayShape: SliderComponentShape.noOverlay,
                        ),
                        child: Slider(
                          value: robotState!.temperature / 100,
                          onChanged: (v) {},
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                RichText(
                  text: TextSpan(
                    text: 'Robot status: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text:
                            (robotState?.isActive ?? false)
                                ? 'Working'
                                : 'Inactive',
                        style: TextStyle(
                          color:
                              robotState != null
                                  ? (robotState!.isActive
                                      ? Colors.green
                                      : Colors.red)
                                  : null,
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed:
                          () => ref
                              .read(r.notifier)
                              .sendCommand(RobotCommandStop()),
                      child: Text('Stop'),
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed:
                          () => ref
                              .read(r.notifier)
                              .sendCommand(RobotCommandStart()),
                      child: Text('Start'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() => robotPinPosition = mousePosition);
          },
          child: Stack(
            children: [
              FutureBuilder(
                future: _load('images/tank_green.png'),
                builder:
                    (_, data) =>
                        !data.hasData
                            ? SizedBox()
                            : SizedBox(
                              width: screenH,
                              height: screenH,
                              child: CustomPaint(
                                size: Size(screenH, screenH),
                                painter: GridPainter(
                                  robotState: robotState,
                                  tankImage: data.data,
                                  oldPosition: oldPosition,
                                ),
                              ),
                            ),
              ),
              if (mousePosition != null)
                Positioned(
                  bottom: mousePosition!.dy,
                  left: mousePosition!.dx,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'x: ${(mousePosition!.dx / workingArea * 100).toStringAsFixed(2)}\ny: ${(mousePosition!.dy / workingArea * 100).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              if (robotPinPosition != null)
                Positioned(
                  bottom: robotPinPosition!.dy,
                  left: robotPinPosition!.dx,
                  child: Container(
                    height: 16,
                    width: 16,
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      border: Border.all(color: Colors.black),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red),
                  ),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.precise,
                    onExit: (e) => setState(() => mousePosition = null),
                    onHover: (hover) {
                      setState(
                        () =>
                            mousePosition = Offset(
                              hover.localPosition.dx,
                              screenH - hover.localPosition.dy,
                            ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: Column()),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  final RobotState? robotState;
  final ui.Image? tankImage;
  final Offset? oldPosition;

  GridPainter({
    required this.robotState,
    required this.tankImage,
    required this.oldPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const int rows = 10;
    const int columns = 10;
    final double cellSize = (size.width / columns).clamp(
      0.0,
      size.height / rows,
    );

    final Paint gridPaint =
        Paint()
          ..color = Colors.grey
          ..strokeWidth = 1.0;

    for (int i = 1; i <= rows; i++) {
      double y = i * cellSize;
      canvas.drawLine(Offset(0, y), Offset(cellSize * columns, y), gridPaint);
    }

    for (int j = 1; j <= columns; j++) {
      double x = j * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, cellSize * rows), gridPaint);
    }

    if (robotState != null) {
      var robotSize = Offset(50, 50);
      var robotLocation = Offset(
        robotState!.position.dx / 100 * size.height,
        size.height - robotState!.position.dy / 100 * size.height,
      );

      canvas.save();

      if (oldPosition != null) {
        var dx = robotState!.position.dx - oldPosition!.dx;
        var dy = robotState!.position.dy - oldPosition!.dy;

        var angle = 3.141 - atan2(dy, dx) + 1.5708;

        canvas.drawImage(
          rotatedImage(image: tankImage!, angle: angle),
          Offset(
            robotLocation.dx - robotSize.dx / 2,
            robotLocation.dy - robotSize.dy / 2,
          ),
          Paint()..color = Colors.black,
        );
      }

      canvas.translate(-size.width / 2, -size.height / 2);

      canvas.restore();

      canvas.drawRect(
        Rect.fromCenter(
          center: robotLocation - Offset(0, 35),
          width: robotState!.battery * 0.6,
          height: 10,
        ),
        Paint()
          ..color =
              Color.lerp(Colors.red, Colors.green, robotState!.battery / 100)!,
      );
    }
  }

  ui.Image rotatedImage({required ui.Image image, required double angle}) {
    var pictureRecorder = ui.PictureRecorder();
    Canvas canvas = Canvas(pictureRecorder);

    final double r =
        sqrt(image.width * image.width + image.height * image.height) / 2;
    final alpha = atan(image.height / image.width);
    final gama = alpha + angle;
    final shiftY = r * sin(gama);
    final shiftX = r * cos(gama);
    final translateX = image.width / 2 - shiftX;
    final translateY = image.height / 2 - shiftY;
    canvas.translate(translateX, translateY);
    canvas.rotate(angle);
    canvas.drawImage(image, Offset.zero, Paint());

    return pictureRecorder.endRecording().toImageSync(
      image.width + 30,
      image.height + 30,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

enum MainPageStateMachine { waitingForUserOptions, ready }

class SquareSliderThumbShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(20, 20); // Size of the square thumb
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
    final Paint paint = Paint()..color = Colors.black; // Thumb color

    // Draw square thumb
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - 10, 4, 30), // Position and size
      paint,
    );
  }
}
