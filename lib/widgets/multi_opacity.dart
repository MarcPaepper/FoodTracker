import 'package:flutter/material.dart';

class MultiOpacity extends StatelessWidget {
  final int depth;
  final double opacity;
  final Duration duration;
  final Widget child;
  final Curve? curve;
  
  const MultiOpacity({
    required this.depth,
    required this.opacity,
    required this.duration,
    required this.child,
    this.curve,
    super.key
  });

  @override
  Widget build(BuildContext context) => _buildOpacity(depth);
  
  // recursive opacity
  Widget  _buildOpacity(int remainingDepth) {
    if (remainingDepth <= 0) return child;
    return AnimatedOpacity(
      opacity: opacity,
      duration: duration,
      curve: curve ?? Curves.linear,
      child: _buildOpacity(remainingDepth - 1),
    );
  }
}