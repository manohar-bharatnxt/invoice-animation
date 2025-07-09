// main.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(MaterialApp(home: ParticleDemo(), debugShowCheckedModeBanner: false));
}

class ParticleDemo extends StatelessWidget {
  const ParticleDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.arrow_back_ios, color: Colors.black),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            StaticParticleCircle(
              size: 400,
              particleColor: Colors.black54,
              particleCount: 7000,
              ringThickness: 100,
            ),
            SizedBox(height: 60),
            Text(
              'Connecting securely to GST Portal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Fetching all invoices and suppliers details...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class StaticParticleCircle extends StatefulWidget {
  final double size;
  final Color particleColor;
  final int particleCount;
  final double ringThickness;

  const StaticParticleCircle({
    super.key,
    required this.size,
    required this.particleColor,
    required this.particleCount,
    required this.ringThickness,
  });

  @override
  State<StaticParticleCircle> createState() => _StaticParticleCircleState();
}

class _StaticParticleCircleState extends State<StaticParticleCircle>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _contractionController;
  late AnimationController _colorController;
  late AnimationController _explosionController;

  late Animation<double> _contractionAnimation;
  late Animation<double> _explosionAnimation;
  late Animation<Color?> _colorAnimation;

  bool _shouldContract = false;
  bool _hideCenterCard = false;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _contractionController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _colorController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _explosionController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _contractionAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _contractionController, curve: Curves.easeInOut),
    );

    _explosionAnimation = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(parent: _explosionController, curve: Curves.easeOut),
    );

    _colorAnimation =
        ColorTween(begin: Colors.black54, end: const Color(0xFF6B73FF)).animate(
          CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
        );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _hideCenterCard = true;
          _shouldContract = true;
        });
        _contractionController.forward();
        _colorController.forward();
      }
    });

    _contractionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _explosionController.forward();
      }
    });

    _explosionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _rotationController.stop();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _contractionController.dispose();
    _colorController.dispose();
    _explosionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _rotationController,
          _contractionController,
          _explosionController,
          _colorController,
        ]),
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationController.value * 2 * math.pi,
            child: CustomPaint(
              painter: ParticleRingPainter(
                particleColor: _colorAnimation.value ?? widget.particleColor,
                particleCount: widget.particleCount,
                ringThickness: widget.ringThickness,
                contractionFactor: _contractionAnimation.value,
                explosionFactor: _explosionAnimation.value,
                showCenter: !_hideCenterCard,
              ),
            ),
          );
        },
      ),
    );
  }
}

class ParticleRingPainter extends CustomPainter {
  final Color particleColor;
  final int particleCount;
  final double ringThickness;
  final double contractionFactor;
  final double explosionFactor;
  final bool showCenter;

  ParticleRingPainter({
    required this.particleColor,
    required this.particleCount,
    required this.ringThickness,
    required this.contractionFactor,
    required this.explosionFactor,
    required this.showCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (explosionFactor >= 1.5) return; // Skip painting if fully exploded

    final center = Offset(size.width / 2, size.height / 2);
    final baseOuterRadius = size.width * 0.4;
    final baseInnerRadius = baseOuterRadius - ringThickness;
    final effectiveFactor = contractionFactor + explosionFactor;

    final outerRadius = baseOuterRadius * effectiveFactor;
    final innerRadius = baseInnerRadius * contractionFactor;
    final currentRingThickness = ringThickness * contractionFactor;

    final random = math.Random(42);

    for (int i = 0; i < particleCount; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final normalizedRadius = _generateRadiusWithFalloff(random);
      final radius = innerRadius + (normalizedRadius * currentRingThickness);

      final explosionOffset = explosionFactor * size.width * 1.5;
      final x = center.dx + math.cos(angle) * (radius + explosionOffset);
      final y = center.dy + math.sin(angle) * (radius + explosionOffset);

      final particleSize =
          (0.2 + (random.nextDouble() * 0.8)) *
          (contractionFactor + explosionFactor * 0.5);

      final ringCenter = innerRadius + currentRingThickness / 2;
      final distanceFromRingCenter = (radius - ringCenter).abs();
      final normalizedDistance =
          distanceFromRingCenter / (currentRingThickness / 2);
      final opacity = 1.0 - (normalizedDistance * 0.7);
      final dynamicOpacity = (opacity * (1 - explosionFactor)).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = particleColor.withOpacity(dynamicOpacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }

    if (showCenter && contractionFactor == 1.0 && explosionFactor == 0.0) {
      _drawCenterSquare(canvas, center);
    }
  }

  double _generateRadiusWithFalloff(math.Random random) {
    return (random.nextDouble() + random.nextDouble() + random.nextDouble()) /
        3;
  }

  void _drawCenterSquare(Canvas canvas, Offset center) {
    final squarePaint = Paint()
      ..color = Colors.grey.shade300.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final squareSize = 60.0;
    final rect = Rect.fromCenter(
      center: center,
      width: squareSize,
      height: squareSize,
    );

    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rRect, squarePaint);
  }

  @override
  bool shouldRepaint(covariant ParticleRingPainter oldDelegate) {
    return oldDelegate.particleColor != particleColor ||
        oldDelegate.particleCount != particleCount ||
        oldDelegate.ringThickness != ringThickness ||
        oldDelegate.contractionFactor != contractionFactor ||
        oldDelegate.explosionFactor != explosionFactor ||
        oldDelegate.showCenter != showCenter;
  }
}
