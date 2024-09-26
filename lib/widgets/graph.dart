import 'package:flutter/material.dart';
// import 'dart:developer' as devtools show log;

import '../services/data/data_objects.dart';

class Graph extends StatefulWidget {
  final DateTime dateTime;
  final List<Target> targets;
  final List<Product> products;
  final List<NutritionalValue> nutritionalValues;
  final List<Meal> meals;
  
  const Graph(
    this.dateTime,
    this.targets,
    this.products,
    this.nutritionalValues,
    this.meals,
    {super.key}
  );

  @override
  State<Graph> createState() => _GraphState();
}

class _GraphState extends State<Graph> {
  @override
  Widget build(BuildContext context) {
    
    
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