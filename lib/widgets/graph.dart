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
    
    // load daily target progress
    Map<Target, Map<Product?, double>> targetProgress = getDailyTargetProgress(widget.dateTime, widget.targets, productMap, widget.nutritionalValues, widget.oldMeals, widget.newMeals);
    devtools.log("targetProgress = $targetProgress");
    
    return const LimitedBox(
      maxWidth: 400,
      maxHeight: 400,
      child: CustomPaint(
        size: Size.infinite,
        // painter: _GraphPainter(),
      ),
    );
  }
}