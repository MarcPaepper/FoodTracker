import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/data/data_objects.dart';

import 'dart:developer' as devtools show log;

import '../utility/text_logic.dart';

const double barWidth = 30;
const double targetMargin = 25;
const double minMargin = 15;

class Graph extends StatefulWidget {
  final double maxWidth;
  final DateTime dateTime;
  final List<Target> targets;
  final List<Product> products;
  final Map<int, Color> colorMap;
  final List<NutritionalValue> nutritionalValues;
  // final List<Meal> oldMeals;
  // final List<Meal> newMeals;
  final Map<Target, Map<Product?, double>> targetProgress;
  
  static bool hasRebuild = false;
  
  const Graph(
    this.maxWidth,
    this.dateTime,
    this.targets,
    this.products,
    this.colorMap,
    this.nutritionalValues,
    this.targetProgress,
    // this.oldMeals,
    // this.newMeals,
    {super.key}
  );

  @override
  State<Graph> createState() => _GraphState();
}

class _GraphState extends State<Graph> {
  bool hasRebuild = false;
  
  @override
  Widget build(BuildContext context) {
    if (!hasRebuild) {
      Future.delayed(const Duration(milliseconds: 200), () {
        setState(() {
          hasRebuild = true;
        });
      });
    }
    
    return SizedBox(
      height: hasRebuild ? 300 : 300,
      width: max(
        widget.maxWidth,
        minMargin * 2 + widget.targets.length * (2 * minMargin + barWidth) + targetMargin,
      ),
      child: CustomPaint(
        size: hasRebuild ? Size.infinite : Size.zero,
        painter: _GraphPainter(widget.targetProgress, widget.products, widget.nutritionalValues, widget.colorMap),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final Map<Target, Map<Product?, double>> targetProgress;
  final List<Product> products;
  final List<NutritionalValue> nutritionalValues;
  final Map<int, Color> colorMap;

  _GraphPainter(
    this.targetProgress,
    this.products,
    this.nutritionalValues,
    this.colorMap,
  );

  @override
  void paint(Canvas canvas, Size size) {
    // sum up all products' contributions to each target
    
    Map<Target, double> totalProgress = {};
    targetProgress.forEach((target, productContributions) {
      totalProgress[target] = productContributions.values.fold(0.0, (a, b) => a + b) / target.amount;
    });
    double maximum = totalProgress.values.fold(0.0, (a, b) => a > b ? a : b);
    maximum = maximum < 1 ? 1 : maximum;
    
    double margin = minMargin;
    double entryWidth = barWidth + 2 * margin;
    double extraMargin = (size.width - entryWidth * targetProgress.length - margin * 2 - targetMargin) / (2 * targetProgress.length + 2);
    if (extraMargin > 0) margin += extraMargin;
           entryWidth = barWidth + 2 * margin;

    var entryLeft = margin;
    
    // --- testing text dimensions ---
    
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Find out which texts fit in one or two lines and which need to have a word cut off
    List<String> names = [];
    List<double> maxLengths = [];
    bool allOneLiners = true;
    
    for (int i = 0; i < targetProgress.length; i++) {
      Target target = targetProgress.keys.elementAt(i);
      String name = target.trackedType == Product ?
        products.firstWhere((product) => product.id == target.trackedId).name :
        nutritionalValues.firstWhere((nutVal) => nutVal.id == target.trackedId).name;
      names.add(name);

      // Create TextPainter to measure the width of the text
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: name,
          style: const TextStyle(fontSize: 12, color: Colors.black),
        ),
        textDirection: TextDirection.ltr,
      );
      
      // Measure the width of the text
      textPainter.layout(minWidth: 0, maxWidth: double.infinity);
      if (textPainter.width > entryWidth - 10) allOneLiners = false;

      var nameFragments = name.split(' ');
      var maxLength = 0.0;
      for (var fragment in nameFragments) {
        textPainter.text = TextSpan(
          text: fragment,
          style: const TextStyle(fontSize: 12, color: Colors.black),
        );
        textPainter.layout(minWidth: 0, maxWidth: double.infinity);
        if (textPainter.width > maxLength) maxLength = textPainter.width;
      }
      maxLengths.add(maxLength);
    }
    
    var baseShift = allOneLiners ? 20 : 34;
    double maxBarHeight = (size.height - baseShift - 20) / maximum;
    double baseline = size.height - baseShift;
    
    // --- drawing texts ---

    for (int i = 0; i < targetProgress.length; i++) {
      String name = names[i];
      
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: name,
          style: const TextStyle(fontSize: 12, color: Colors.black),
        ),
        textDirection: TextDirection.ltr,
      );

      // Layout text with infinite width to calculate its actual width
      textPainter.layout(minWidth: 0, maxWidth: entryWidth - 10);
      bool overflows = maxLengths[i] > entryWidth - 10;
      
      textPainter = TextPainter(
        text: TextSpan(
          text: name,
          style: const TextStyle(fontSize: 12, color: Colors.black),
        ),
        textAlign: overflows ? TextAlign.left : TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(minWidth: 0, maxWidth: entryWidth - 10);
      
      Offset offset;
      if (overflows) {
        offset = Offset(entryLeft + (entryWidth - textPainter.width) / 2, baseline + 5);
      } else {
        offset = Offset(entryLeft + (entryWidth - textPainter.width) / 2, baseline + 5);
      }
      
      textPainter.paint(canvas, offset);

      entryLeft += entryWidth;
    }
    
    // --- drawing bars ---
    
    entryLeft = margin;
    for (int i = 0; i < targetProgress.length; i++) {
      Target target = targetProgress.keys.elementAt(i);
      Map<Product?, double>? productContributions = targetProgress[target];

      // Draw product contributions
      double currentHeight = 0;
      productContributions?.forEach((product, contribution) {
        Color color;
        if (product == null) {
          color = const Color.fromARGB(255, 83, 83, 83);
        } else {
          color = colorMap[product.id] ?? Colors.white;
        }

        double contributionHeight = (contribution / target.amount) * maxBarHeight;
        if (contributionHeight > 0) {
          canvas.drawRect(
            Rect.fromLTWH(entryLeft + margin, baseline - currentHeight - contributionHeight, barWidth, contributionHeight),
            Paint()..color = color,
          );
        }

        currentHeight += contributionHeight;
      });
      // the number of decimal places for the full target.amount precision
      int targetPrecision;
      String targetText = truncateZeros(target.amount);
      if (targetText.contains('.')) {
        targetPrecision = targetText.length - targetText.indexOf('.') - 1;
      } else {
        // the number of digits after which only zeros follow
        String truncatedText = targetText;
        while (truncatedText.endsWith('0')) {
          truncatedText = truncatedText.substring(0, truncatedText.length - 1);
        }
        targetPrecision = - (targetText.length - truncatedText.length);
      }
      
      // Draw current progress
      
      // determine a good precision for the current amount
      int precision;
      int order = (log(target.amount) / ln10).floor() + 1;
      if (target.amount < 10) {
        precision = order;
      } else if (target.amount < 17) {
        precision = 1;
      } else {
        precision = 3 - order;
        if (precision > 0) precision = 0;
      }
      if (precision < targetPrecision) precision = targetPrecision;
      
      // apply precision
      double amount = (totalProgress[target]! * target.amount);
      String text;
      if (amount == 0 || amount.isNaN) {
        text = '0';
      } else if (precision > 0) {
        text = amount.toStringAsFixed(precision);
      } else {
        amount = toDouble((amount * pow(10, precision)).round() * pow(10, -precision));
        text = amount.toString();
      }
      text = truncateZeros(text);
      
      // paint the text
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(fontSize: 12, color: Colors.black),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(minWidth: 0, maxWidth: 100);
      textPainter.paint(canvas, Offset(
        entryLeft + margin + barWidth / 2 - textPainter.width / 2,
        baseline - currentHeight - textPainter.height - 2
      ));
      
      // Draw target line
      canvas.drawLine(
        Offset(entryLeft, baseline - maxBarHeight),
        Offset(entryLeft + entryWidth, baseline - maxBarHeight),
        Paint()..color = Colors.black..strokeWidth = 1..style = PaintingStyle.stroke,
      );
      
      // Draw target amount
      text = target.amount.toString();
      text = truncateZeros(text);
      textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(fontSize: 12, color: Colors.black),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(minWidth: 0, maxWidth: 100);
      textPainter.paint(canvas, Offset(
        entryLeft + margin + barWidth / 2 - textPainter.width / 2,
        baseline - maxBarHeight - textPainter.height - 2
      ));
      
      entryLeft += entryWidth;
    }
    
    // --- drawing target emoji ---
    
    TextPainter textPainter = TextPainter(
      text: const TextSpan(
        text: '🏁',
        style: TextStyle(fontSize: 19, color: Colors.black),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: targetMargin);
    
    // draw normally
    textPainter.paint(canvas, Offset(entryLeft + 10, baseline - maxBarHeight - 12));
    
    // // draw rotated
    // var x = entryLeft + 20, y = baseline - maxBarHeight + 0;
    // canvas.drawRotatedText(
    //   pivot: Offset(x, y),
    //   textPainter: textPainter,
    //   angle: - pi / 2,
    // );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is _GraphPainter) {
      var shouldRepaint = false;
      if (!const DeepCollectionEquality().equals(targetProgress, oldDelegate.targetProgress)) shouldRepaint = true;
      if (!listEquals(products, oldDelegate.products)) shouldRepaint = true;
      if (!listEquals(nutritionalValues, oldDelegate.nutritionalValues)) shouldRepaint = true;
      if (!const DeepCollectionEquality().equals(colorMap, oldDelegate.colorMap)) shouldRepaint = true;
      return shouldRepaint;
    } else {
      return true;
    }
  }
}

// extension RotatedTextExt on Canvas {
//   /// [angle] is in radians. Set `isInDegrees = true` if it is in degrees.
//   void drawRotatedText({
//     required Offset pivot,
//     required TextPainter textPainter,
//     TextPainter? superTextPainter,
//     TextPainter? subTextPainter,
//     required double angle,
//     bool isInDegrees = false,
//     Alignment alignment = Alignment.center,
//   }) {
//     //
//     // Convert angle from degrees to radians
//     angle = isInDegrees ? angle * pi / 180 : angle;

//     textPainter.layout();
//     superTextPainter?.layout();
//     subTextPainter?.layout();

//     // Calculate delta. Delta is the top left offset with reference
//     // to which the main text will paint. The centre of the text will be
//     // at the given pivot unless [alignment] is set.
//     final w = textPainter.width;
//     final h = textPainter.height;
//     final delta = pivot.translate(
//         -w / 2 + w / 2 * alignment.x, -h / 2 + h / 2 * alignment.y);
//     //
//     final supDelta =
//         delta.translate(w, h - h * 0.6 - (superTextPainter?.size.height ?? 0));
//     //
//     final subDelta = delta.translate(w, h - (subTextPainter?.size.height ?? 0));

//     // Rotate the text about pivot
//     save();
//     translate(pivot.dx, pivot.dy);
//     rotate(angle);
//     translate(-pivot.dx, -pivot.dy);
//     textPainter.paint(this, delta);
//     superTextPainter?.paint(this, supDelta);
//     subTextPainter?.paint(this, subDelta);
//     restore();
//   }
// }