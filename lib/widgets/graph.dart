import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:food_tracker/utility/theme.dart';

import '../services/data/data_objects.dart';

// import 'dart:developer' as devtools show log;

import '../utility/text_logic.dart';

const double barWidth = 30;
const double targetMargin = 25;
const double buttonMargin = 45;
const double minMargin = 15;

class Graph extends StatefulWidget {
  final double maxWidth;
  final List<Target> targets;
  final List<Product> products;
  final Map<int, Color> colorMap;
  final List<NutritionalValue> nutritionalValues;
  final Map<Target, Map<Product?, double>> targetProgress;
  final bool othersOnTop;
  
  static bool hasRebuild = false;
  
  const Graph(
    this.maxWidth,
    this.targets,
    this.products,
    this.colorMap,
    this.nutritionalValues,
    this.targetProgress,
    this.othersOnTop,
    {super.key}
  );

  @override
  State<Graph> createState() => _GraphState();
}

class _GraphState extends State<Graph> {
  bool hasRebuild = false;
  bool showAll = false;
  
  @override
  Widget build(BuildContext context) {
    // rebuild for emoji loading
    if (!hasRebuild) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            hasRebuild = true;
          });
        }
      });
    }
    
    // remove secondary targets if they are not shown
    var activeProgress = Map<Target, Map<Product?, double>>.from(widget.targetProgress);
    var hasSecondary = activeProgress.keys.any((t) => !t.isPrimary);
    var btnMargin = hasSecondary ? buttonMargin : 0;
    if (!showAll && hasSecondary) {
      activeProgress.removeWhere((t, _) => !t.isPrimary);
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: hasRebuild ? 300 : 300,
          width: max(
            widget.maxWidth - btnMargin,
            minMargin * 2 + activeProgress.length * (2 * minMargin + barWidth) + targetMargin,
          ),
          child: CustomPaint(
            size: hasRebuild ? Size.infinite : Size.zero,
            painter: _GraphPainter(activeProgress, widget.products, widget.nutritionalValues, widget.colorMap, widget.othersOnTop),
          ),
        ),
        hasSecondary ? SizedBox(
          width: buttonMargin,
          height: 300,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 10, 12),
            child: ElevatedButton(
              style: importantButtonStyle.copyWith(
                backgroundColor: WidgetStateProperty.all(Colors.grey.shade400),
                visualDensity: VisualDensity.compact,
                padding: WidgetStateProperty.all(const EdgeInsets.all(0)),
                shape: WidgetStateProperty.all(const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                )),
              ),
              onPressed: () {
                setState(() {
                  showAll = !showAll;
                });
              },
              child: Icon(showAll ? Icons.chevron_left : Icons.chevron_right),
            ),
          ),
        ) : const SizedBox(width: 0),
      ],
    );
  }
}

class _GraphPainter extends CustomPainter {
  final Map<Target, Map<Product?, double>> targetProgress;
  final List<Product> products;
  final List<NutritionalValue> nutritionalValues;
  final Map<int, Color> colorMap;
  final bool othersOnTop;

  _GraphPainter(
    this.targetProgress,
    this.products,
    this.nutritionalValues,
    this.colorMap,
    this.othersOnTop,
  );

  @override
  void paint(Canvas canvas, Size size) {
    // sum up all products' relative contributions to each target
    Map<Target, double> totalProgress = {};
    targetProgress.forEach((target, productContributions) {
      totalProgress[target] = productContributions.values.fold(0.0, (a, b) => a + b) / target.amount;
    });
    
    // find the highest relative progress for any target
    double maximum = totalProgress.values.fold(0.0, (a, b) => a > b ? a : b);
    maximum = maximum < 1 ? 1 : maximum;
    
    // --- calculating dimensions ---
    double margin = minMargin;
    double entryWidth = barWidth + 2 * margin;
    double extraMargin = (size.width - (minMargin * 2 + targetProgress.length * (2 * minMargin + barWidth) + targetMargin)) / (2 * targetProgress.length + 2);
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
      if (othersOnTop && productContributions != null && productContributions.containsKey(null) == true) {
        // move the null product to the back
        var nullEntry = productContributions[null];
        productContributions.remove(null);
        productContributions[null] = nullEntry!;
      }

      // Draw product contributions
      double currentHeight = 0;
      productContributions?.forEach((product, contribution) {
        Color color;
        if (product == null) {
          const light = 90;
          color = const Color.fromARGB(255, light, light, light);
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
      
      var tooClose = (currentHeight - maxBarHeight).abs() < 20;
      var below = currentHeight > maxBarHeight && !tooClose;
      
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
      
      if (tooClose) {
        text += ' / ${truncateZeros(target.amount.toString())}';
      }
      
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
      double x = entryLeft + margin + barWidth / 2 - textPainter.width / 2;
      double y = baseline - currentHeight - textPainter.height - 2;
      if (tooClose) y = min(y, baseline - maxBarHeight - textPainter.height - 4);
      textPainter.paint(canvas, Offset(x, y));
      
      // Draw target line
      double targetY = baseline - maxBarHeight;
      canvas.drawLine(
        Offset(entryLeft, targetY),
        Offset(entryLeft + entryWidth, targetY),
        Paint()..color = Colors.black..strokeWidth = 1..style = PaintingStyle.stroke,
      );
      
      // Draw target amount
      textPainter = TextPainter(
        text: TextSpan(
          text: tooClose ? "" : targetText,
          style: const TextStyle(fontSize: 12, color: Colors.black),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(minWidth: 0, maxWidth: 100);
      x = entryLeft + margin + barWidth / 2 - textPainter.width / 2;
      // If the bar is above the target, draw the text below the bar
      y = baseline - maxBarHeight - textPainter.height - 4;
      
      if (below) {
        // paint a white outline around the text
        var whiteness = 230;
        var outlinePainter = TextPainter(
          text: TextSpan(
            text: tooClose ? "" : targetText,
            style: TextStyle(
              fontSize: 12,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.5
                ..color = Color.fromARGB(200, whiteness, whiteness, whiteness),
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        outlinePainter.layout(minWidth: 0, maxWidth: 100);
        outlinePainter.paint(canvas, Offset(x, y));
      }
      textPainter.paint(canvas, Offset(x, y));
      
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
    textPainter.paint(canvas, Offset(entryLeft + 10, baseline - maxBarHeight - 12));
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