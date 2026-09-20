import 'package:flutter/material.dart';
import 'dart:math';

class ConfettiPiece {
  late double x;
  late double y;
  late double vx;
  late double vy;
  late double rotation;
  late double rotationSpeed;
  final Color color;
  final double size;

  ConfettiPiece({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
  }) {
    final random = Random();
    vx = (random.nextDouble() - 0.5) * 8;
    vy = -random.nextDouble() * 12 - 4;
    rotation = random.nextDouble() * 2 * pi;
    rotationSpeed = (random.nextDouble() - 0.5) * 0.3;
  }

  void update(double gravity) {
    x += vx;
    y += vy;
    vy += gravity;
    rotation += rotationSpeed;
  }

  bool isOffScreen(double screenHeight) {
    return y > screenHeight;
  }
}

class ConfettiWidget extends StatefulWidget {
  final Duration duration;

  const ConfettiWidget({
    Key? key,
    this.duration = const Duration(milliseconds: 2000),
  }) : super(key: key);

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<ConfettiPiece> _pieces = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.forward().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pieces.isEmpty) {
      _createConfetti();
    }
  }

  void _createConfetti() {
    _pieces = [];
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
    ];

    for (int i = 0; i < 30; i++) {
      _pieces.add(
        ConfettiPiece(
          x: MediaQuery.of(context).size.width / 2,
          y: MediaQuery.of(context).size.height * 0.7,
          color: colors[_random.nextInt(colors.length)],
          size: _random.nextDouble() * 8 + 4,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        for (var piece in _pieces) {
          piece.update(0.3);
        }

        return CustomPaint(
          painter: ConfettiPainter(_pieces),
          size: Size.infinite,
        );
      },
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiPiece> pieces;

  ConfettiPainter(this.pieces);

  @override
  void paint(Canvas canvas, Size size) {
    for (var piece in pieces) {
      if (!piece.isOffScreen(size.height)) {
        canvas.save();
        canvas.translate(piece.x, piece.y);
        canvas.rotate(piece.rotation);

        final paint = Paint()..color = piece.color;
        canvas.drawRect(
          Rect.fromCenter(
            center: const Offset(0, 0),
            width: piece.size,
            height: piece.size,
          ),
          paint,
        );

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}

void showConfetti(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    barrierDismissible: false,
    builder: (context) => const ConfettiWidget(),
  );
}
