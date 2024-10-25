import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/data/data_objects.dart';

import 'dart:developer' as devtools show log;

class Graph extends StatefulWidget {
  final DateTime dateTime;
  final List<Target> targets;
  final List<Product> products;
  final Map<int, Color> colorMap;
  final List<NutritionalValue> nutritionalValues;
  // final List<Meal> oldMeals;
  // final List<Meal> newMeals;
  final Map<Target, Map<Product?, double>> targetProgress;
  
  const Graph(
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
  @override
  Widget build(BuildContext context) {
    // log colors
    // for (var color in widget.colorMap) {
    //   // devtools.log(color.toString());
    // }
    
    return LimitedBox(
      maxHeight: 300,
      child: CustomPaint(
        size: Size.infinite,
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
    
    double barWidth = 30;
    double margin = 15;
    double entryWidth = barWidth + 2 * margin;
    double spacing = barWidth / (targetProgress.length + 1);
    double maxBarHeight = size.height * 0.8;
    double baseline = size.height * 0.9;

    var entryLeft = spacing;
    
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
    }
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