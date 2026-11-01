import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/app/branding/brand_geometry.g.dart';
import 'package:muenee/app/theme/app_theme.dart';
import 'package:muenee/app/widgets/brand_mark.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SVG, Flutter and both Android vectors share identical paths', () {
    final svg = File('assets/brand/muenee_launcher.svg').readAsStringSync();
    for (final relative in [
      'android/app/src/main/res/drawable/muenee_launcher_foreground.xml',
      'android/app/src/main/res/drawable/muenee_mark.xml',
    ]) {
      final native = File(relative).readAsStringSync();
      for (final data in BrandGeometry.sourcePathData) {
        expect(svg, contains('d="$data"'));
        expect(native, contains('android:pathData="$data"'));
      }
      expect(native, contains('android:strokeWidth="6"'));
      expect(native, contains('android:strokeLineCap="round"'));
    }
    final adaptive = File(
      'android/app/src/main/res/drawable/muenee_launcher_foreground.xml',
    ).readAsStringSync();
    expect(adaptive, contains('android:pivotX="54" android:pivotY="54"'));
    expect(
      adaptive,
      contains('android:scaleX="${BrandGeometry.adaptiveScale}"'),
    );
    expect(
      adaptive,
      contains('android:scaleY="${BrandGeometry.adaptiveScale}"'),
    );
  });

  test(
    'raster has four equal, separated tines and a centered ink box',
    () async {
      const scale = 10;
      const edge = 108 * scale;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(scale.toDouble());
      BrandGeometry.paint(canvas, Colors.white);
      final picture = recorder.endRecording();
      final image = await picture.toImage(edge, edge);
      final rgba = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      int alpha(int x, int y) => rgba.getUint8((y * edge + x) * 4 + 3);
      var minX = edge;
      var minY = edge;
      var maxX = -1;
      var maxY = -1;
      var radius = 0.0;
      for (var y = 0; y < edge; y++) {
        for (var x = 0; x < edge; x++) {
          if (alpha(x, y) < 128) continue;
          minX = math.min(minX, x);
          maxX = math.max(maxX, x);
          minY = math.min(minY, y);
          maxY = math.max(maxY, y);
          final dx = (x + .5) / scale - 54;
          final dy = (y + .5) / scale - 54;
          radius = math.max(radius, math.sqrt(dx * dx + dy * dy));
        }
      }
      expect((minX + maxX + 1) / (2 * scale), closeTo(54, .15));
      expect((minY + maxY + 1) / (2 * scale), closeTo(54, .15));
      expect((maxX - minX + 1) / scale, closeTo(64, .2));
      expect((maxY - minY + 1) / scale, closeTo(68, .2));
      // Conservative circular safe zone, stricter than a square bounding check.
      expect(radius * BrandGeometry.adaptiveScale, lessThanOrEqualTo(33));
      expect(64 * BrandGeometry.adaptiveScale, greaterThanOrEqualTo(48));
      expect(68 * BrandGeometry.adaptiveScale, greaterThanOrEqualTo(48));

      final tines = <(int, int)>[];
      int? start;
      for (var x = 16 * scale; x <= 58 * scale; x++) {
        final ink = alpha(x, 33 * scale) >= 128;
        if (ink && start == null) start = x;
        if (!ink && start != null) {
          tines.add((start, x - 1));
          start = null;
        }
      }
      expect(tines, hasLength(4));
      final centers = tines
          .map((run) => (run.$1 + run.$2 + 1) / (2 * scale))
          .toList();
      for (var i = 0; i < 4; i++) {
        expect(centers[i], closeTo(25 + 9.0 * i, .1));
        expect((tines[i].$2 - tines[i].$1 + 1) / scale, closeTo(6, .1));
      }
      image.dispose();
      picture.dispose();
    },
  );

  testWidgets('brand mark and wordmark work at small and large sizes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Column(
            children: [
              BrandWordmark(),
              BrandMark(size: 24, onCoral: true),
              BrandMark(size: 32),
              BrandMark(size: 48, onCoral: true),
              BrandMark(size: 96),
            ],
          ),
        ),
      ),
    );
    expect(find.text('MueNee'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.byType(BrandMark), findsNWidgets(5));
  });

  test('export before/after preview only when explicitly requested', () async {
    if (!const bool.fromEnvironment('GENERATE_BRAND_PREVIEW')) return;
    final fonts = FontLoader('Prompt')
      ..addFont(rootBundle.load('assets/fonts/prompt/Prompt-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/prompt/Prompt-Bold.ttf'));
    await fonts.load();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(const Color(0xFFFFF8E7), BlendMode.src);
    void text(
      String copy,
      double x,
      double y,
      double size, {
      bool bold = false,
    }) {
      final builder =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(
                fontFamily: 'Prompt',
                fontSize: size,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            )
            ..pushStyle(ui.TextStyle(color: AppTheme.ink))
            ..addText(copy);
      final paragraph = builder.build()
        ..layout(const ui.ParagraphConstraints(width: 1250));
      canvas.drawParagraph(paragraph, Offset(x, y));
      paragraph.dispose();
    }

    void mark(double x, double y, double size) {
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(size / 108);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 108, 108),
          const Radius.circular(27),
        ),
        Paint()..color = AppTheme.coral,
      );
      BrandGeometry.paint(canvas, Colors.white);
      canvas.restore();
    }

    text('MueNee / Campus Pop', 64, 36, 40, bold: true);
    text('Logo refinement — precise vector geometry', 64, 101, 22);
    final panel = Paint()..color = Colors.white;
    for (final x in [64.0, 736.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 158, 600, 558),
          const Radius.circular(28),
        ),
        panel,
      );
    }
    text('BEFORE', 104, 182, 19, bold: true);
    text('REFINED', 776, 182, 19, bold: true);
    final oldBytes = await File(
      'artifacts/brand-refinement/2026-10-03/before/assets/brand/muenee_launcher_512.png',
    ).readAsBytes();
    final codec = await ui.instantiateImageCodec(oldBytes);
    final old = (await codec.getNextFrame()).image;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(184, 228, 360, 360),
        const Radius.circular(90),
      ),
    );
    canvas.drawImageRect(
      old,
      Rect.fromLTWH(0, 0, old.width.toDouble(), old.height.toDouble()),
      const Rect.fromLTWH(184, 228, 360, 360),
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();
    mark(856, 228, 360);
    text('5 tines / uneven spacing / offset', 118, 627, 22);
    text('4 equal tines / centered / uniform stroke', 772, 627, 22);
    text('Small-size check', 64, 752, 21, bold: true);
    var x = 300.0;
    for (final size in [24.0, 32.0, 48.0, 64.0]) {
      mark(x, 752, size);
      text('${size.toInt()} px', x, 830, 15);
      x += 140;
    }
    text('Master: SVG · No generated-image geometry', 64, 879, 16);
    final picture = recorder.endRecording();
    final image = await picture.toImage(1400, 944);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    final target = File(
      'artifacts/brand-refinement/2026-10-03/logo-before-after.png',
    );
    await target.parent.create(recursive: true);
    await target.writeAsBytes(
      png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
    );
    old.dispose();
    codec.dispose();
    image.dispose();
    picture.dispose();
  });
}
