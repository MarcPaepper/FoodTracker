import "package:flutter/material.dart";

import "../services/data/data_objects.dart";
import "add_meal_box.dart";

class MealList extends StatefulWidget {
  final Map<int, Product>? productsMap;
  
  const MealList({
    required this.productsMap,
    super.key,
  });

  @override
  State<MealList> createState() => _MealListState();
}

class _MealListState extends State<MealList> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      reverse: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(0.0),
      children: [
        AddMealBox(
          copyDateTime: DateTime.now(),
          onDateTimeChanged: (newDateTime) => {},
          productsMap: widget.productsMap ?? {},
        ),
        const SizedBox(height: 6),
        ListTile(
          title: Text('Apples'),
          subtitle: Text('100g'),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => {},
          ),
        ),
        getHorizontalLine(),
        ListTile(
          title: Text('Apples'),
          subtitle: Text('100g'),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => {},
          ),
        ),
        getHorizontalLine(),
      ],
    );
  }
}

Widget getHorizontalLine() =>
  const Divider(
    indent: 10,
    endIndent: 10,
    height: 1,
  );