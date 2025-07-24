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

    // Rotation controller - runs for exactly 4 seconds
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Disintegration controller - runs for 4 seconds (same as rotation)
    _disintegrationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Filling controller - runs for 4 seconds
    _fillingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Contraction controller - runs for 4 seconds
    _contractionController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Color controller - runs for 4 seconds
    _colorController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Explosion controller - runs for 2 seconds (total animation time = 6 seconds)
    _explosionController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Animation definitions
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

    _explosionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      await _generateImageParticles();

      setState(() {
        _showImageParticles = true;
      });

      // Start formation animations
      _rotationController.forward();
      _contractionController.forward();
      _colorController.forward();
      _disintegrationController.forward();

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _showAssetImage = false;
        });
      }

      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        _fillingController.forward();
      }

      // Wait for the full 4-second formation to complete
      await Future.delayed(const Duration(milliseconds: 3000));

      if (mounted) {
        // Stop rotation after 4 seconds
        _rotationController.stop();
        _explosionController.forward();

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
          // Rotating ring particles
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
                painter: RingParticlePainter(
                  particleColor: _colorAnimation.value ?? widget.particleColor,
                  particleCount: widget.particleCount,
                  ringThickness: widget.ringThickness,
                  disintegrationFactor: _disintegrationAnimation.value,
                  fillingFactor: _fillingAnimation.value,
                  contractionFactor: _contractionAnimation.value,
                  explosionFactor: _explosionAnimation.value,
                  rotationAngle: _rotationController.value * -math.pi,
                ),
              );
            },
          ),

          // Non-rotating image particles
          if (_showImageParticles)
            AnimatedBuilder(
              animation: Listenable.merge([
                _disintegrationController,
                _fillingController,
                _contractionController,
                _explosionController,
                _colorController,
              ]),
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: ImageParticlePainter(
                    imageParticles: _imageParticles,
                    disintegrationFactor: _disintegrationAnimation.value,
                    contractionFactor: _contractionAnimation.value,
                    explosionFactor: _explosionAnimation.value,
                    particleColor:
                        _colorAnimation.value ?? widget.particleColor,
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
    double explosionProgress,
    double contractionFactor,
  ) {
    if (explosionProgress > 0) {
      // Use the same explosion distance calculation as ring particles
      final baseDistance = targetDistance * contractionFactor;
      final explosionDistance = explosionProgress * 400;
      return center + direction * (baseDistance + explosionDistance);
    } else {
      final easedProgress = Curves.easeInOut.transform(disintegrationProgress);
      return Offset.lerp(
        initialPosition,
        center + direction * (targetDistance * contractionFactor),
        easedProgress,
      )!;
    }
  }
}

class RingParticlePainter extends CustomPainter {
  final Color particleColor;
  final int particleCount;
  final double ringThickness;
  final double disintegrationFactor;
  final double fillingFactor;
  final double contractionFactor;
  final double explosionFactor;
  final double rotationAngle;

  RingParticlePainter({
    required this.particleColor,
    required this.particleCount,
    required this.ringThickness,
    required this.disintegrationFactor,
    required this.fillingFactor,
    required this.contractionFactor,
    required this.explosionFactor,
    required this.rotationAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseOuterRadius = size.width * 0.4;
    final baseInnerRadius = baseOuterRadius - ringThickness;
    final random = math.Random(42);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);
    canvas.translate(-center.dx, -center.dy);

    // Draw ring particles
    final currentOuterRadius = baseOuterRadius * contractionFactor;
    final currentInnerRadius = baseInnerRadius * contractionFactor;

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

      // Apply the same explosion calculation as image particles
      final explosionOffset = explosionFactor * 400;
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
  bool shouldRepaint(covariant RingParticlePainter oldDelegate) {
    return oldDelegate.disintegrationFactor != disintegrationFactor ||
        oldDelegate.fillingFactor != fillingFactor ||
        oldDelegate.contractionFactor != contractionFactor ||
        oldDelegate.explosionFactor != explosionFactor ||
        oldDelegate.particleColor != particleColor ||
        oldDelegate.rotationAngle != rotationAngle;
  }
}

class ImageParticlePainter extends CustomPainter {
  final List<ImageParticle> imageParticles;
  final double disintegrationFactor;
  final double contractionFactor;
  final double explosionFactor;
  final Color particleColor;

  ImageParticlePainter({
    required this.imageParticles,
    required this.disintegrationFactor,
    required this.contractionFactor,
    required this.explosionFactor,
    required this.particleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in imageParticles) {
      final animatedPos = particle.getAnimatedPosition(
        disintegrationFactor,
        explosionFactor,
        contractionFactor,
      );
      particle.position = animatedPos;

      final opacity = (1.0 - explosionFactor).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = particleColor.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      final contractedSize = particle.size * contractionFactor;
      canvas.drawCircle(particle.position, contractedSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ImageParticlePainter oldDelegate) {
    return oldDelegate.disintegrationFactor != disintegrationFactor ||
        oldDelegate.contractionFactor != contractionFactor ||
        oldDelegate.explosionFactor != explosionFactor ||
        oldDelegate.particleColor != particleColor;
  }
}
