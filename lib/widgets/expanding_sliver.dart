import 'package:flutter/material.dart';
import '../constants/ui.dart';

class ExpandingSliver extends StatelessWidget {
  final String text;
  final double widthProgress;   // Controls horizontal expansion
  final double scrollProgress;  // Controls how much of the container is revealed from the top

  const ExpandingSliver({
    Key? key,
    required this.text,
    required this.widthProgress,
    required this.scrollProgress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        // Measure the intrinsic width of the text
        const textStyle = TextStyle(fontSize: 15.5 * gsf);
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: textStyle),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        final intrinsicWidth = textPainter.size.width;

        // Container width: 0.3..1.0 portion of maxWidth
        final computedWidth = intrinsicWidth +
            (maxWidth - intrinsicWidth) * (0.7 * widthProgress + 0.3);

        // Calculate vertical translation based on scrollProgress.
        // You can adjust 'slideRange' to control how far it slides in from above.
        const double slideRange = 47.5 * gsf; 
        // If scrollProgress == 0, offsetY == slideRange (i.e. fully hidden above).
        // If scrollProgress == 1, offsetY == 0 (i.e. fully visible).
        final double offsetY = slideRange * (1 - scrollProgress);
        double borderRadius = (0.75 * (1 - widthProgress ) + 0.25) * 8 * gsf;
        
        return Padding(
          padding: const EdgeInsets.only(top: 6 * gsf),
          // Transform to move the container from above to its final position
          child: Transform.translate(
            offset: Offset(0, -offsetY),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: computedWidth,
                  height: 32 * gsf,
                  // Center the text within the box
                  alignment: Alignment.center,
                  // color: const Color.fromARGB(255, 200, 200, 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    color: const Color.fromARGB(255, 200, 200, 200),
                  ),
                  child: Text(text, style: textStyle),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
