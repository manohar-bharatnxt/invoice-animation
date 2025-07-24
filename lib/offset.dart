import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: OffsetVisualizer()));
}

class OffsetVisualizer extends StatefulWidget {
  const OffsetVisualizer({super.key});

  @override
  State<OffsetVisualizer> createState() => _OffsetVisualizerState();
}

class _OffsetVisualizerState extends State<OffsetVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  Offset _startOffset = Offset(0, 0);
  Offset _endOffset = Offset(0, 0);

  final _dxValues = [-1.0, -0.5, 0.0, 0.5, 1.0];
  final _dyValues = [-1.0, -0.5, 0.0, 0.5, 1.0];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: _startOffset,
      end: _endOffset,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.ease));
  }

  void _updateAnimation(Offset newOffset) {
    setState(() {
      _startOffset = Offset(0, 0); // Always start from center
      _endOffset = newOffset;
      _offsetAnimation = Tween<Offset>(
        begin: _startOffset,
        end: _endOffset,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.ease));
      _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildButton(Offset offset) {
    return GestureDetector(
      onTap: () => _updateAnimation(offset),
      child: Container(
        margin: EdgeInsets.all(4),
        padding: EdgeInsets.all(8),
        color: Colors.blueAccent,
        child: Text(
          'dx: ${offset.dx}, dy: ${offset.dy}',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Offset Visualizer")),
      body: Column(
        children: [
          SizedBox(height: 20),
          Text("Tap a button to apply an Offset"),
          Expanded(
            child: Center(
              child: ClipRect(
                child: SlideTransition(
                  position: _offsetAnimation,
                  child: Container(
                    width: 100,
                    height: 100,
                    color: Colors.deepOrange,
                    child: Center(
                      child: Text("Box", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              for (var dx in _dxValues)
                for (var dy in _dyValues) _buildButton(Offset(dx, dy)),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
