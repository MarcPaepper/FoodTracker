import 'package:flutter/material.dart';

TableRow getSpacerRow({
  required int elements,
  required double height,
}) {
  return TableRow(
    children: List.generate(
      elements,
      (index) => SizedBox(height: height),
    ),
  );
}