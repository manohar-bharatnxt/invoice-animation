import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: VerticalTickerReveal()));
}

class VerticalTickerReveal extends StatefulWidget {
  const VerticalTickerReveal({super.key});

  @override
  State<VerticalTickerReveal> createState() => _VerticalTickerRevealState();
}

class _VerticalTickerRevealState extends State<VerticalTickerReveal>
    with TickerProviderStateMixin {
  final List<String> suggestions = [
    "Search books",
    "Search music",
    "Search videos",
    "Search podcasts",
  ];

  int _currentIndex = 0;
  int _nextIndex = 1;
  Timer? _timer;

  late AnimationController _controller;
  late Animation<Offset> _currentSlide;
  late Animation<Offset> _nextSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _currentSlide = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(0, -1),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _nextSlide = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _timer = Timer.periodic(Duration(seconds: 2), (_) {
      _controller.forward(from: 0).then((_) {
        setState(() {
          _currentIndex = _nextIndex;
          _nextIndex = (_nextIndex + 1) % suggestions.length;
        });
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double tickerHeight = 40;

    return Scaffold(
      appBar: AppBar(title: Text("Ticker Style Text Reveal")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: suggestions[_currentIndex],
              ),
            ),
            SizedBox(height: 30),
            ClipRect(
              child: SizedBox(
                height: tickerHeight,
                child: Stack(
                  children: [
                    SlideTransition(
                      position: _currentSlide,
                      child: SizedBox(
                        height: tickerHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            suggestions[_currentIndex],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SlideTransition(
                      position: _nextSlide,
                      child: SizedBox(
                        height: tickerHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            suggestions[_nextIndex],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
