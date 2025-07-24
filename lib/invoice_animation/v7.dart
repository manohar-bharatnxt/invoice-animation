import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;

void main() {
  runApp(MaterialApp(home: ParticleDemo(), debugShowCheckedModeBanner: false));
}

class ParticleDemo extends StatefulWidget {
  const ParticleDemo({super.key});

  @override
  State<ParticleDemo> createState() => _ParticleDemoState();
}

class _ParticleDemoState extends State<ParticleDemo> {
  bool _showSuccess = false;
  bool _showLoadingText = true;

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
          children: [
            StaticParticleCircle(
              size: 400,
              particleColor: Colors.black54,
              particleCount: 8000,
              ringThickness: 100,
              onAnimationComplete: () {
                setState(() {
                  _showSuccess = true;
                  _showLoadingText = false;
                });
              },
            ),
            const SizedBox(height: 60),
            if (_showLoadingText) ...[
              const Text(
                'Connecting securely to GST Portal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fetching all invoices and suppliers details...',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
            if (_showSuccess) ...[
              const Text(
                'Congratulations!!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Successfully Fetched GST Invoices.',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
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
  final VoidCallback? onAnimationComplete;

  const StaticParticleCircle({
    super.key,
    required this.size,
    required this.particleColor,
    required this.particleCount,
    required this.ringThickness,
    this.onAnimationComplete,
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

  bool _showAssetImage = true;
  bool _showImageParticles = false;
  bool _showTick = false;
  List<ImageParticle> _imageParticles = [];

  @override
  void initState() {
    super.initState();

    // Slower rotation - 8 seconds per rotation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // 4 seconds for contraction during rotation
    _contractionController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _colorController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // 2 seconds for explosion
    _explosionController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    ;

    // Slight contraction - only 10%
    _contractionAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _contractionController, curve: Curves.easeInOut),
    );

    _explosionAnimation = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(parent: _explosionController, curve: Curves.easeOut),
    );

    _colorAnimation =
        ColorTween(begin: Colors.black54, end: const Color(0xFF6B73FF)).animate(
          CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
        );

    // Start everything after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        // Generate particles and immediately switch to particles
        _generateImageParticles().then((_) {
          setState(() {
            _showAssetImage = false;
            _showImageParticles = true;
          });
          _contractionController.forward();
          _colorController.forward();
        });
      }
    });

    _contractionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Stop rotation and start explosion
        _rotationController.stop();
        _explosionController.forward();
      }
    });

    _explosionController.addStatusListener((status) {
      setState(() {
        _showTick = true;
      });
      if (widget.onAnimationComplete != null) {
        widget.onAnimationComplete!();
      }
    });
  }

  Future<void> _generateImageParticles() async {
    // Use the disintegration approach from your provided code
    try {
      final ByteData data = await DefaultAssetBundle.of(
        context,
      ).load('assets/images/icon_blue.png');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Image image = await decodeImageFromList(bytes);

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      final width = image.width;
      final height = image.height;
      final pixels = byteData!.buffer.asUint8List();

      final random = math.Random();
      final tempParticles = <ImageParticle>[];
      final center = Offset(widget.size / 2, widget.size / 2);
      final circleRadius = widget.size * 0.4; // Match the circle boundary

      // Scale factor to fit image in center
      final imageScale = 120.0 / math.max(width, height);

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

            // Calculate initial position (scaled and centered)
            final initialX = ((x - width / 2) * imageScale) + center.dx;
            final initialY = ((y - height / 2) * imageScale) + center.dy;
            final initialPos = Offset(initialX, initialY);

            // Random direction but constrained within circle
            final direction = Offset(
              random.nextDouble() * 2 - 1,
              random.nextDouble() * 2 - 1,
            );

            tempParticles.add(
              ImageParticle(
                position: initialPos,
                color: color,
                center: center,
                direction: direction,
                speed: random.nextDouble() * 2 + 1,
                circleRadius: circleRadius,
              ),
            );
          }
        }
      }

      setState(() {
        _imageParticles = tempParticles;
      });
    } catch (e) {
      print('Error loading image: $e');
    }
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Combined particle system
          AnimatedBuilder(
            animation: Listenable.merge([
              _rotationController,
              _contractionController,
              _explosionController,
              _colorController,
            ]),
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * -math.pi,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: UnifiedParticlePainter(
                    particleColor:
                        _colorAnimation.value ?? widget.particleColor,
                    particleCount: widget.particleCount,
                    ringThickness: widget.ringThickness,
                    contractionFactor: _contractionAnimation.value,
                    explosionFactor: _explosionAnimation.value,
                    imageParticles: _imageParticles,
                    showImageParticles: _showImageParticles,
                    imageParticleColor:
                        _colorAnimation.value ?? widget.particleColor,
                  ),
                ),
              );
            },
          ),

          // Static asset image (NO fade transition)
          if (_showAssetImage)
            Image.asset(
              'assets/images/icon_blue.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),

          if (_showTick)
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
        ],
      ),
    );
  }
}

class ImageParticle {
  Offset position;
  final Color color;
  final Offset center;
  final Offset direction;
  final double speed;
  final double circleRadius;

  ImageParticle({
    required this.position,
    required this.color,
    required this.center,
    required this.direction,
    required this.speed,
    required this.circleRadius,
  });

  Offset getAnimatedPosition(double progress, double explosionFactor) {
    if (explosionFactor > 0) {
      // During explosion, constrain particles within circle
      final animatedPos = position + direction * speed * explosionFactor * 60;
      final distanceFromCenter = (animatedPos - center).distance;

      if (distanceFromCenter > circleRadius) {
        // Keep particle within circle boundary
        final directionFromCenter = (animatedPos - center) / distanceFromCenter;
        return center + directionFromCenter * circleRadius;
      }
      return animatedPos;
    } else {
      // During contraction, spread within center area
      final spreadDistance = progress * circleRadius * 0.3;
      return position + direction * spreadDistance;
    }
  }
}

class UnifiedParticlePainter extends CustomPainter {
  final Color particleColor;
  final int particleCount;
  final double ringThickness;
  final double contractionFactor;
  final double explosionFactor;
  final List<ImageParticle> imageParticles;
  final bool showImageParticles;
  final Color imageParticleColor;

  UnifiedParticlePainter({
    required this.particleColor,
    required this.particleCount,
    required this.ringThickness,
    required this.contractionFactor,
    required this.explosionFactor,
    required this.imageParticles,
    required this.showImageParticles,
    required this.imageParticleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseOuterRadius = size.width * 0.4;
    final baseInnerRadius = baseOuterRadius - ringThickness * 0.8;

    // Current radii with contraction
    final outerRadius = baseOuterRadius * contractionFactor;
    final innerRadius = baseInnerRadius * contractionFactor;

    final random = math.Random(42);

    // Draw image particles (fill center during contraction)
    if (showImageParticles) {
      for (final particle in imageParticles) {
        // Use the animated position with boundary constraints
        final animatedPos = particle.getAnimatedPosition(
          contractionFactor,
          explosionFactor,
        );

        final opacity = (1.0 - explosionFactor).clamp(0.0, 1.0);

        final paint = Paint()
          ..color = imageParticleColor.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(animatedPos, 0.8, paint);
      }
    }

    // Don't draw ring if explosion is complete
    if (explosionFactor >= 1.5) return;

    // Draw ring particles with center filling
    final currentRingThickness = ringThickness * contractionFactor;

    // Fill center progressively during contraction
    final centerFillProgress =
        (1.0 - contractionFactor) * 5; // More aggressive filling
    final minRadius = math.max(
      0,
      innerRadius - (innerRadius * centerFillProgress),
    );

    for (int i = 0; i < particleCount; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final normalizedRadius = _generateRadiusWithFalloff(random);

      // Distribute from center to outer edge
      final radius = minRadius + (normalizedRadius * (outerRadius - minRadius));

      final explosionOffset = explosionFactor * size.width * 1.5;
      final x = center.dx + math.cos(angle) * (radius + explosionOffset);
      final y = center.dy + math.sin(angle) * (radius + explosionOffset);

      final particleSize =
          (0.2 + (random.nextDouble() * 0.8)) * contractionFactor;

      // Opacity based on position
      double opacity = 1.0;
      if (radius < innerRadius) {
        // Center-filling particles
        opacity = (1.0 - contractionFactor) * 3; // Fade in during contraction
      }

      final dynamicOpacity = (opacity * (1 - explosionFactor)).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = particleColor.withValues(alpha: dynamicOpacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  double _generateRadiusWithFalloff(math.Random random) {
    return (random.nextDouble() + random.nextDouble() + random.nextDouble()) /
        3;
  }

  @override
  bool shouldRepaint(covariant UnifiedParticlePainter oldDelegate) {
    return oldDelegate.contractionFactor != contractionFactor ||
        oldDelegate.explosionFactor != explosionFactor ||
        oldDelegate.particleColor != particleColor ||
        oldDelegate.showImageParticles != showImageParticles ||
        oldDelegate.imageParticleColor != imageParticleColor;
  }
}
