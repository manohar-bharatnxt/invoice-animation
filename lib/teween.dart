import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: TweenExample());
  }
}

class TweenExample extends StatefulWidget {
  const TweenExample({super.key});

  @override
  State<TweenExample> createState() => _TweenExampleState();
}

class _TweenExampleState extends State<TweenExample>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _doubleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _doubleAnimation = Tween<double>(begin: 100, end: 200).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.bounceIn,
      ),
    );
    _colorAnimation =
        ColorTween(
          begin: Colors.amber,
          end: Colors.cyan,
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
    _controller.forward();
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 180.0,
    ).animate(_controller);
    print('Rotation: ${_rotationAnimation.value}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tween Example')),
      // body: Center(
      //   child: AnimatedBuilder(
      //     animation: _controller,
      //     builder: (context, child) {
      //       return Transform.rotate(
      //         angle: _rotationAnimation.value,
      //         child: Container(
      //           width: _doubleAnimation.value,
      //           height: _doubleAnimation.value,
      //           color: _colorAnimation.value,
      //         ),
      //       );
      //     },
      //   ),
      // ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder(
            curve: Curves.easeInOut,
            tween: Tween(
              begin: 0,
              end: _isExpanded ? 0.5 : 0,
            ),
            duration: Duration(milliseconds: 300),
            builder: (context, value, child) {
              print(value);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Center(
                  child: Transform.rotate(
                    angle: value * 3.14 * 2,
                    child: Icon(
                      Icons.arrow_downward,
                      size: 50,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
