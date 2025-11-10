import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Circular progress ring matching Figma design
/// Animated progress indicator with center content
class CircularProgressRing extends StatefulWidget {
  const CircularProgressRing({
    super.key,
    required this.progress,
    required this.color,
    required this.centerText,
    this.subtitle,
    this.size = 240,
    this.strokeWidth = 12,
    this.animationDuration = const Duration(milliseconds: 500),
  });

  final double progress; // 0-100
  final Color color;
  final String centerText;
  final String? subtitle;
  final double size;
  final double strokeWidth;
  final Duration animationDuration;

  @override
  State<CircularProgressRing> createState() => _CircularProgressRingState();
}

class _CircularProgressRingState extends State<CircularProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(CircularProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular progress
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CircularProgressPainter(
                  progress: _animation.value,
                  color: widget.color,
                  strokeWidth: widget.strokeWidth,
                ),
              );
            },
          ),
          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.centerText,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress; // 0-100
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * (progress / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
