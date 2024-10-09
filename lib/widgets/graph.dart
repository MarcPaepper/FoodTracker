import 'package:flutter/material.dart';

import '../services/data/data_objects.dart';
import '../utility/data_logic.dart';

import 'dart:developer' as devtools show log;

class Graph extends StatefulWidget {
  final DateTime dateTime;
  final List<Target> targets;
  final List<Product> products;
  final List<NutritionalValue> nutritionalValues;
  final List<Meal> oldMeals;
  final List<Meal> newMeals;
  
  const Graph(
    this.dateTime,
    this.targets,
    this.products,
    this.nutritionalValues,
    this.oldMeals,
    this.newMeals,
    {super.key}
  );

  @override
  State<Graph> createState() => _GraphState();
}

class _GraphState extends State<Graph> {
  @override
  Widget build(BuildContext context) {
    // convert product list to map
    Map<int, Product> productMap = widget.products.asMap().map((key, value) => MapEntry(value.id, value));
    
    Map<Target, Map<Product?, double>> targetProgress = getDailyTargetProgress(widget.dateTime, widget.targets, productMap, widget.nutritionalValues, widget.newMeals, widget.oldMeals);
    // this is a map of all targets and how much of the target was fulfilled by every product
    
    List<Color> productColors = [
      Colors.red,      // red
      Colors.orange,   // orange
      Colors.yellow,   // yellow
      Colors.green,    // green
      Colors.blue, 		// blue
      Colors.indigo,	// indigo
      Colors.purple,	// purple
    ];
    
    return LimitedBox(
      maxHeight: 300,
      child: CustomPaint(
        size: Size.infinite,
        painter: _GraphPainter(targetProgress, widget.products, widget.nutritionalValues, productColors),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final Map<Target, Map<Product?, double>> targetProgress;
  final List<Product> products;
  final List<NutritionalValue> nutritionalValues;
  final List<Color> productColors;

  _GraphPainter(
    this.targetProgress,
    this.products,
    this.nutritionalValues,
    this.productColors,
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
    
    final double barWidth = 30;
    final double margin = 15;
    final double entryWidth = barWidth + 2 * margin;
    final double spacing = barWidth / (targetProgress.length + 1);
    final double maxBarHeight = size.height * 0.8;
    final double baseline = size.height * 0.9;

    var entryLeft = spacing;

    targetProgress.forEach((target, productContributions) {
      // Draw product contributions
      double currentHeight = 0;
      productContributions.forEach((product, contribution) {
        Color color = product == null ? const Color.fromARGB(255, 83, 83, 83) : productColors[product.id % productColors.length];
        double contributionHeight = (contribution / target.amount) * maxBarHeight;
        
        canvas.drawRect(
          Rect.fromLTWH(entryLeft + margin, baseline - currentHeight - contributionHeight, barWidth, contributionHeight),
          Paint()..color = color,
        );
        
        currentHeight += contributionHeight;
      });

      // Draw target line
      canvas.drawLine(
        Offset(entryLeft, baseline - maxBarHeight),
        Offset(entryLeft + barWidth, baseline - maxBarHeight),
        Paint()..color = Colors.black..strokeWidth = 1..style = PaintingStyle.stroke,
      );

      // Draw target name
      String name = target.trackedType == Product ?
        products.firstWhere((product) => product.id == target.trackedId).name :
        nutritionalValues.firstWhere((nutVal) => nutVal.id == target.trackedId).name;
      
      TextPainter(
        text: TextSpan(
          text: name,
          style: const TextStyle(fontSize: 12, color: Colors.black),
        ),
        textDirection: TextDirection.ltr,
      )
        ..layout(minWidth: 0, maxWidth: entryWidth)
        ..paint(canvas, Offset(entryLeft, baseline + 5));

      entryLeft += entryWidth + spacing;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is _GraphPainter) {
      var shouldRepaint = false;
      shouldRepaint = shouldRepaint || oldDelegate.targetProgress != targetProgress;
      shouldRepaint = shouldRepaint || oldDelegate.products != products;
      shouldRepaint = shouldRepaint || oldDelegate.nutritionalValues != nutritionalValues;
      shouldRepaint = shouldRepaint || oldDelegate.productColors != productColors;
      devtools.log("shouldRepaint: $shouldRepaint");
      return shouldRepaint;
    } else {
      devtools.log("shouldRepaint: true");
      return true;
    }
  }
}