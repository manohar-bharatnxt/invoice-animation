import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() => runApp(
  MaterialApp(
    home: DisintegratingImage(
      size: 150,
      assetPath: 'assets/images/icon_blue.png',
      onDisintegrationComplete: () {
        // Optional callback when disintegration ends
      },
    ),
  ),
);

class DisintegratingImage extends StatefulWidget {
  final double size;
  final String assetPath;
  final VoidCallback? onDisintegrationComplete;

  const DisintegratingImage({
    super.key,
    required this.size,
    required this.assetPath,
    this.onDisintegrationComplete,
  });

  @override
  State<DisintegratingImage> createState() => _DisintegratingImageState();
}

class _DisintegratingImageState extends State<DisintegratingImage>
    with SingleTickerProviderStateMixin {
  final GlobalKey _key = GlobalKey();
  ui.Image? _image;
  late AnimationController _controller;
  List<Particle>? _particles;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: Duration(seconds: 2), vsync: this)
          ..addListener(() => setState(() {}))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              widget.onDisintegrationComplete?.call();
            }
          });

    Future.delayed(Duration(milliseconds: 800), () {
      _captureAndGenerateParticles();
    });
  }

  Future<void> _captureAndGenerateParticles() async {
    RenderRepaintBoundary boundary =
        _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    _image = await boundary.toImage(pixelRatio: 1);
    final byteData = await _image!.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    final width = _image!.width;
    final height = _image!.height;

    final pixels = byteData!.buffer.asUint8List();
    final random = math.Random();
    final tempParticles = <Particle>[];

    for (int y = 0; y < height; y += 2) {
      for (int x = 0; x < width; x += 2) {
        final index = (y * width + x) * 4;
        if (index + 3 >= pixels.length) continue;
        final r = pixels[index];
        final g = pixels[index + 1];
        final b = pixels[index + 2];
        final a = pixels[index + 3];

        if (a > 0) {
          final color = Color.fromARGB(a, r, g, b);
          tempParticles.add(
            Particle(
              position: Offset(x.toDouble(), y.toDouble()),
              color: color,
              direction: Offset(
                random.nextDouble() * 2 - 1,
                random.nextDouble() * 2 - 1,
              ),
              speed: random.nextDouble() * 2 + 1,
            ),
          );
        }
      }
    }

    setState(() {
      _particles = tempParticles;
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (_particles != null) {
      return CustomPaint(
        size: Size(widget.size, widget.size),
        painter: ParticlePainter(
          particles: _particles!,
          progress: _controller.value,
        ),
      );
    }

    return RepaintBoundary(
      key: _key,
      child: Image.asset(
        widget.assetPath,
        width: widget.size,
        height: widget.size,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class Particle {
  Offset position;
  final Offset direction;
  final double speed;
  final Color color;

  Particle({
    required this.position,
    required this.direction,
    required this.speed,
    required this.color,
  });

  Offset getAnimatedPosition(double progress) {
    return position + direction * speed * progress * 60;
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final pos = p.getAnimatedPosition(progress);
      final paint = Paint()..color = p.color;
      canvas.drawCircle(pos, 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
