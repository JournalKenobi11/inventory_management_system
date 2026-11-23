import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RepaintBoundary captures full widget height to PNG', (tester) async {
    final GlobalKey boundaryKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RepaintBoundary(
              key: boundaryKey,
              child: Container(
                color: Colors.white,
                height: 1200,
                width: 400,
                child: const Column(
                  children: [
                    Text('Top text'),
                    Spacer(),
                    Text('Bottom text'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.runAsync(() async {
      final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      expect(image.width, 400);
      expect(image.height, 1200);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(byteData, isNotNull);
      expect(byteData!.lengthInBytes, greaterThan(0));
    });
  });
}
