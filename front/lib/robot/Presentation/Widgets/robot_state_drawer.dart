import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:panda_test_task/robot/Data/Model/robot_state.dart';

class RobotStateDrawer extends CustomPainter {
  final RobotState? robotState;
  final ui.Image? tankImage;
  final Offset? oldPosition;

  RobotStateDrawer({
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

    //left borders
    canvas.drawLine(Offset(0, 0), Offset(0, cellSize * rows), gridPaint);
    //draw horizontal lines
    for (int j = 1; j <= columns; j++) {
      double x = j * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, cellSize * rows), gridPaint);
    }

    //draw vertical lines
    if (robotState != null) {
      var robotSize = Offset(50, 50);
      var robotLocation = Offset(
        robotState!.position.dx / 100 * size.height,
        size.height - robotState!.position.dy / 100 * size.height,
      );

      canvas.save();

      //we can draw robot if we know his vector
      if (oldPosition != null) {
        var dx = robotState!.position.dx - oldPosition!.dx;
        var dy = robotState!.position.dy - oldPosition!.dy;

        //calculating angle beetwen previous and current position
        //and adjusting it for current model
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

      //draw battery indicator
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

  //function to rotate image from center
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
