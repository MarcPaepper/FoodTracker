import 'package:flutter/material.dart';

class ColorIndicatorStrip extends StatefulWidget {
  final Color color;
  final double width;
  final double extra;
  
  const ColorIndicatorStrip(
    this.color,
    this.width,
    this.extra,
    {super.key}
  );

  @override
  State<ColorIndicatorStrip> createState() => _ColorIndicatorStripState();
}

class _ColorIndicatorStripState extends State<ColorIndicatorStrip> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width, // Adjust the total width (6px red + 6px fade)
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.color.withOpacity(1.0),
            widget.color.withOpacity(1.0),
            widget.color.withOpacity(0.9),
            widget.color.withOpacity(0.5),
            widget.color.withOpacity(0.25),
            widget.color.withOpacity(0.1),
            widget.color.withOpacity(0.0),
          ],
          stops: [
            widget.extra + (1 - widget.extra) * 0.0,
            widget.extra + (1 - widget.extra) * 0.2,
            widget.extra + (1 - widget.extra) * 0.2666,
            widget.extra + (1 - widget.extra) * 0.3333,
            widget.extra + (1 - widget.extra) * 0.4666,
            widget.extra + (1 - widget.extra) * 0.6666,
            widget.extra + (1 - widget.extra) * 0.95,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }
}