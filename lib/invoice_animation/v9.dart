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
  late AnimationController _disintegrationController;
  late AnimationController _fillingController;
  late AnimationController _contractionController;
  late AnimationController _colorController;
  late AnimationController _explosionController;

  late Animation<double> _disintegrationAnimation;
  late Animation<double> _fillingAnimation;
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

    // Rotation controller - 4 seconds total (not repeating)
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Disintegration controller - 2 seconds (within the 4 second window)
    _disintegrationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Filling controller - 2 seconds (overlaps with disintegration)
    _fillingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Contraction controller - 4 seconds total (same as rotation)
    _contractionController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Color controller - 4 seconds total
    _colorController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Explosion controller - 2 seconds (after the 4 second formation)
    _explosionController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _disintegrationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _disintegrationController,
        curve: Curves.easeInOut,
      ),
    );

    _fillingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fillingController, curve: Curves.easeInOut),
    );

    _contractionAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _contractionController, curve: Curves.easeInOut),
    );

    _explosionAnimation = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(parent: _explosionController, curve: Curves.easeOut),
    );

    _colorAnimation =
        ColorTween(
          begin: Colors.black54,
          end: const Color(0xFF6B73FF),
        ).animate(
          CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
        );

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Wait 1 second, then start the 4-second formation sequence
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      await _generateImageParticles();

      setState(() {
        _showImageParticles = true;
      });

      // Start all formation animations together (4 seconds total)
      _rotationController.forward(); // 4 seconds of rotation
      _contractionController.forward(); // 4 seconds of contraction
      _colorController.forward(); // 4 seconds of color change
      _disintegrationController.forward(); // 2 seconds of disintegration

      // Hide asset image after 0.5 seconds
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _showAssetImage = false;
        });
      }

      // Start filling after 1 second (overlaps with disintegration)
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Total 1 second from start
      if (mounted) {
        _fillingController.forward(); // 2 seconds of filling
      }

      // Wait for the full 4-second formation to complete
      await Future.delayed(
        const Duration(milliseconds: 3000),
      ); // Remaining time to reach 4 seconds total

      if (mounted) {
        // Stop rotation and start explosion
        _rotationController.stop();
        _explosionController.forward();

        // Show success after explosion starts
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          setState(() {
            _showTick = true;
          });
          if (widget.onAnimationComplete != null) {
            widget.onAnimationComplete!();
          }
        }
      }
    }
  }

  Future<void> _generateImageParticles() async {
    try {
      final ByteData data = await DefaultAssetBundle.of(
        context,
      ).load('assets/images/icon_blue.png');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Image image = await decodeImageFromList(bytes);
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      if (byteData == null) return;

      final width = image.width;
      final height = image.height;
      final pixels = byteData.buffer.asUint8List();
      final random = math.Random();
      final tempParticles = <ImageParticle>[];
      final center = Offset(widget.size / 2, widget.size / 2);

      final outerRadius = widget.size * 0.4;
      final innerRadius = outerRadius - (widget.ringThickness * 0.8);

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

            final initialX = ((x - width / 2) * imageScale) + center.dx;
            final initialY = ((y - height / 2) * imageScale) + center.dy;
            final initialPos = Offset(initialX, initialY);

            final directionFromCenter = (initialPos - center);
            final distanceFromCenter = directionFromCenter.distance;

            final normalizedDirection = distanceFromCenter > 0
                ? directionFromCenter / distanceFromCenter
                : Offset(1, 0);

            final maxInnerDistance = innerRadius * 0.9;
            final targetDistance = random.nextDouble() * maxInnerDistance;

            final targetX =
                center.dx + (normalizedDirection.dx * targetDistance);
            final targetY =
                center.dy + (normalizedDirection.dy * targetDistance);
            final targetPos = Offset(targetX, targetY);

            tempParticles.add(
              ImageParticle(
                initialPosition: initialPos,
                disintegratedPosition: targetPos,
                position: initialPos,
                color: color,
                center: center,
                direction: normalizedDirection,
                targetDistance: targetDistance,
                speed: random.nextDouble() * 0.5 + 0.5,
                size: 0.8,
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
    _disintegrationController.dispose();
    _fillingController.dispose();
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
          AnimatedBuilder(
            animation: Listenable.merge([
              _rotationController,
              _disintegrationController,
              _fillingController,
              _contractionController,
              _explosionController,
              _colorController,
            ]),
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: UnifiedParticlePainter(
                  particleColor: _colorAnimation.value ?? widget.particleColor,
                  particleCount: widget.particleCount,
                  ringThickness: widget.ringThickness,
                  disintegrationFactor: _disintegrationAnimation.value,
                  fillingFactor: _fillingAnimation.value,
                  contractionFactor: _contractionAnimation.value,
                  explosionFactor: _explosionAnimation.value,
                  imageParticles: _imageParticles,
                  showImageParticles: _showImageParticles,
                  imageParticleColor:
                      _colorAnimation.value ?? widget.particleColor,
                  rotationAngle: _rotationController.value * 2 * -math.pi,
                ),
              );
            },
          ),

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
  final Offset initialPosition;
  final Offset disintegratedPosition;
  Offset position;
  final Color color;
  final Offset center;
  final Offset direction;
  final double targetDistance;
  final double speed;
  final double size;

  ImageParticle({
    required this.initialPosition,
    required this.disintegratedPosition,
    required this.position,
    required this.color,
    required this.center,
    required this.direction,
    required this.targetDistance,
    required this.speed,
    required this.size,
  });

  Offset getAnimatedPosition(
    double disintegrationProgress,
    double fillingProgress,
    double explosionProgress,
  ) {
    if (explosionProgress > 0) {
      final explosionDistance = explosionProgress * 400;
      return center + direction * (targetDistance + explosionDistance);
    } else if (fillingProgress > 0) {
      final fillSpread = 1.0 + (fillingProgress * 0.2);
      final expandedDistance = math.min(
        targetDistance * fillSpread,
        targetDistance,
      );
      return center + direction * expandedDistance;
    } else if (disintegrationProgress > 0) {
      return Offset.lerp(
        initialPosition,
        disintegratedPosition,
        disintegrationProgress,
      )!;
    } else {
      return initialPosition;
    }
  }
}

class UnifiedParticlePainter extends CustomPainter {
  final Color particleColor;
  final int particleCount;
  final double ringThickness;
  final double disintegrationFactor;
  final double fillingFactor;
  final double contractionFactor;
  final double explosionFactor;
  final List<ImageParticle> imageParticles;
  final bool showImageParticles;
  final Color imageParticleColor;
  final double rotationAngle;

  UnifiedParticlePainter({
    required this.particleColor,
    required this.particleCount,
    required this.ringThickness,
    required this.disintegrationFactor,
    required this.fillingFactor,
    required this.contractionFactor,
    required this.explosionFactor,
    required this.imageParticles,
    required this.showImageParticles,
    required this.imageParticleColor,
    required this.rotationAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseOuterRadius = size.width * 0.4;
    final baseInnerRadius = baseOuterRadius - ringThickness * 0.8;
    final random = math.Random(42);

    if (showImageParticles) {
      for (final particle in imageParticles) {
        final animatedPos = particle.getAnimatedPosition(
          disintegrationFactor,
          fillingFactor,
          explosionFactor,
        );

        particle.position = animatedPos;

        final opacity = (1.0 - explosionFactor).clamp(0.0, 1.0);
        final paint = Paint()
          ..color = imageParticleColor.withOpacity(opacity)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(animatedPos, particle.size, paint);
      }
    }

    if (explosionFactor >= 1.5) return;

    final currentOuterRadius = baseOuterRadius * contractionFactor;
    final currentInnerRadius = baseInnerRadius * contractionFactor;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);
    canvas.translate(-center.dx, -center.dy);

    final centerFillProgress = (1.0 - contractionFactor) * 5;
    final minRadius = math.max(
      0,
      currentInnerRadius - (currentInnerRadius * centerFillProgress),
    );

    for (int i = 0; i < particleCount; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final normalizedRadius = _generateRadiusWithFalloff(random);

      final radius =
          minRadius + (normalizedRadius * (currentOuterRadius - minRadius));

      final explosionOffset = explosionFactor * size.width * 1.5;
      final x = center.dx + math.cos(angle) * (radius + explosionOffset);
      final y = center.dy + math.sin(angle) * (radius + explosionOffset);

      final particleSize =
          (0.2 + (random.nextDouble() * 0.8)) * contractionFactor;

      double opacity = 1.0;
      if (radius < currentInnerRadius) {
        opacity = (1.0 - contractionFactor) * 3;
      }

      final dynamicOpacity = (opacity * (1 - explosionFactor)).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = particleColor.withOpacity(dynamicOpacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }

    canvas.restore();
  }

  double _generateRadiusWithFalloff(math.Random random) {
    return (random.nextDouble() + random.nextDouble() + random.nextDouble()) /
        3;
  }

  @override
  bool shouldRepaint(covariant UnifiedParticlePainter oldDelegate) {
    return oldDelegate.disintegrationFactor != disintegrationFactor ||
        oldDelegate.fillingFactor != fillingFactor ||
        oldDelegate.contractionFactor != contractionFactor ||
        oldDelegate.explosionFactor != explosionFactor ||
        oldDelegate.particleColor != particleColor ||
        oldDelegate.showImageParticles != showImageParticles ||
        oldDelegate.imageParticleColor != imageParticleColor ||
        oldDelegate.rotationAngle != rotationAngle;
  }
}
