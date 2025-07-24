import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;

import 'package:flutter_animations/image_disintegration.dart';

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
  late AnimationController _imageFadeController;

  late Animation<double> _contractionAnimation;
  late Animation<double> _explosionAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _imageFadeAnimation;

  bool _hideCenterCard = false;
  bool _showTick = false;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _contractionController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _colorController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _explosionController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _imageFadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _contractionAnimation = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _contractionController, curve: Curves.easeInOut),
    );

    _explosionAnimation = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(parent: _explosionController, curve: Curves.easeOut),
    );

    _colorAnimation =
        ColorTween(begin: Colors.black54, end: const Color(0xFF6B73FF)).animate(
          CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
        );

    _imageFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _imageFadeController, curve: Curves.easeIn),
    );

    // Start the animation sequence
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Start image fade immediately (0.5s duration)
        _imageFadeController.forward();

        // Start contraction and color change after image transition
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _contractionController.forward();
            _colorController.forward();
          }
        });
      }
    });

    _contractionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _hideCenterCard = true;
        });
        _explosionController.forward();
      }
    });

    _explosionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _rotationController.stop();
        setState(() {
          _showTick = true;
        });
        if (widget.onAnimationComplete != null) {
          widget.onAnimationComplete!();
        }
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _contractionController.dispose();
    _colorController.dispose();
    _explosionController.dispose();
    _imageFadeController.dispose();
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
              _contractionController,
              _explosionController,
              _colorController,
            ]),
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * -math.pi,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: ParticleRingPainter(
                    particleColor:
                        _colorAnimation.value ?? widget.particleColor,
                    particleCount: widget.particleCount,
                    ringThickness: widget.ringThickness,
                    contractionFactor: _contractionAnimation.value,
                    explosionFactor: _explosionAnimation.value,
                    showCenter: false,
                  ),
                ),
              );
            },
          ),
          if (!_hideCenterCard)
            DisintegratingImage(
              size: 150,
              assetPath: 'assets/images/icon_blue.png',
              onDisintegrationComplete: () {
                // Optional callback when disintegration ends
              },
            ),

          if (_showTick)
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
        ],
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
    if (explosionFactor >= 1.5) return;

    final center = Offset(size.width / 2, size.height / 2);
    final baseOuterRadius = size.width * 0.4;
    final baseInnerRadius = baseOuterRadius - ringThickness * 0.8;

    final effectiveFactor = contractionFactor + explosionFactor;

    final outerRadius = baseOuterRadius * effectiveFactor;
    final innerRadius = baseInnerRadius * contractionFactor;
    final currentRingThickness = ringThickness * contractionFactor;

    final random = math.Random(42);

    // Calculate how much to cover the center during contraction
    final centerCoverage = (1.0 - contractionFactor) * 1.5;
    final centerCoverageFactor = centerCoverage.clamp(0.0, 1.0);

    for (int i = 0; i < particleCount; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final normalizedRadius = _generateRadiusWithFalloff(random);

      // Adjust radius to cover center during contraction
      final radius =
          innerRadius +
          (normalizedRadius * currentRingThickness) *
              (1.0 - centerCoverageFactor * 0.8);

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
  bool shouldRepaint(covariant ParticleRingPainter oldDelegate) {
    return oldDelegate.particleColor != particleColor ||
        oldDelegate.particleCount != particleCount ||
        oldDelegate.ringThickness != ringThickness ||
        oldDelegate.contractionFactor != contractionFactor ||
        oldDelegate.explosionFactor != explosionFactor ||
        oldDelegate.showCenter != showCenter;
  }
}

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
