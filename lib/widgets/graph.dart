import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

import '../services/data/data_objects.dart';

class Graph extends StatefulWidget {
  final List<NutritionalValue> nutritionalValues;
  final List<Meal> meals;
  
  const Graph(
    {
      required this.nutritionalValues,
      required this.meals,
      super.key
    }
  );

  @override
  State<Graph> createState() => _GraphState();
}

class _GraphState extends State<Graph> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}