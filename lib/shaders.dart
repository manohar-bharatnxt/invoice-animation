import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Dissolve Demo',
      theme: ThemeData.dark(),
      home: const DissolveDemoPage(),
    );
  }
}

/// A host page to manage the AnimationController and display the effect.
class DissolveDemoPage extends StatefulWidget {
  const DissolveDemoPage({Key? key}) : super(key: key);

  @override
  State<DissolveDemoPage> createState() => _DissolveDemoPageState();
}

class _DissolveDemoPageState extends State<DissolveDemoPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Create a looping animation (consolidate -> pause -> disintegrate -> pause -> repeat)
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _controller.reverse();
          }
        });
      } else if (status == AnimationStatus.dismissed) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _controller.forward();
          }
        });
      }
    });

    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pixel Dissolve Effect')),
      body: Center(
        child: PixelDissolveImage(
          imagePath:
              'assets/images/icon_blue.png', // Make sure this path is correct
          controller: _controller,
          gridSize: 50.0, // Controls the "blockiness" of the effect
        ),
      ),
    );
  }
}

// The final reusable widget
class PixelDissolveImage extends StatefulWidget {
  final String imagePath;
  final double gridSize;
  final AnimationController controller;

  const PixelDissolveImage({
    Key? key,
    required this.imagePath,
    required this.controller,
    this.gridSize = 64.0,
  }) : super(key: key);

  @override
  _PixelDissolveImageState createState() => _PixelDissolveImageState();
}

class _PixelDissolveImageState extends State<PixelDissolveImage> {
  Future<dynamic>? _loadingFuture;

  Future<dynamic> _loadAssets() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'assets/shaders/pixel_dissolve.frag',
      );
      final imageData = await rootBundle.load(widget.imagePath);
      final image = await decodeImageFromList(imageData.buffer.asUint8List());
      return {'program': program, 'image': image};
    } catch (e) {
      // Return the error to be handled by the FutureBuilder
      return e;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadingFuture = _loadAssets();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadingFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError || (snapshot.hasData && snapshot.data is! Map)) {
          return Center(
            child: Text(
              'Error loading assets: ${snapshot.error ?? snapshot.data}',
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          final assets = snapshot.data as Map<String, dynamic>;
          final program = assets['program'] as ui.FragmentProgram;
          final image = assets['image'] as ui.Image;

          return AnimatedBuilder(
            animation: widget.controller,
            builder: (context, child) {
              return SizedBox(
                width: image.width.toDouble(),
                height: image.height.toDouble(),
                child: CustomPaint(
                  painter: ShaderPainter(
                    shader: program.fragmentShader(),
                    image: image,
                    progress: widget.controller.value,
                    gridSize: widget.gridSize,
                  ),
                ),
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

// The ShaderPainter from Section 3
class ShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final ui.Image image;
  final double progress;
  final double gridSize;

  ShaderPainter({
    required this.shader,
    required this.image,
    required this.progress,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Set uniforms by index. The order MUST match the declaration order in the.frag file.
    shader.setImageSampler(0, image); // uniform sampler2D uImage;
    shader.setFloat(0, size.width); // uniform vec2 uResolution; (index 0 = x)
    shader.setFloat(1, size.height); // uniform vec2 uResolution; (index 1 = y)
    shader.setFloat(2, progress); // uniform float uProgress;
    shader.setFloat(3, gridSize); // uniform float uGridSize;

    final paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant ShaderPainter oldDelegate) {
    // Repaint whenever progress or grid size changes
    return oldDelegate.progress != progress || oldDelegate.gridSize != gridSize;
  }
}
