import "package:flutter/material.dart";

import "../services/data/data_objects.dart";
import "../utility/text_logic.dart";
import "add_meal_box.dart";

import "dart:developer" as devtools show log;

class MealList extends StatefulWidget {
  final Map<int, Product>? productsMap;
  final List<Meal> meals;
  
  const MealList({
    required this.productsMap,
    required this.meals,
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
        const SizedBox(height: 5),
        getMealTiles(context, widget.productsMap, widget.meals),
      ],
    );
  }
}

Widget getMealTiles(BuildContext context, Map<int, Product>? productsMap, List<Meal> meals) {
  List<Widget> children = [];
  
  DateTime lastHeader = DateTime(0);
  for (int i = meals.length - 1; i >= 0; i--) {
    final meal = meals[i];
    final product = productsMap?[meal.productQuantity.productId];
    final mealDate = DateTime(meal.dateTime.year, meal.dateTime.month, meal.dateTime.day);
    
    if (lastHeader.isAfter(mealDate)) {
      // print error
      devtools.log('MealList: meals are not sorted by date');
    } else if (lastHeader.isBefore(mealDate)) {
      lastHeader = mealDate;
      // Convert date to natural string
      String text;
      int relativeDays = mealDate.difference(DateTime.now()).inDays.abs();
      if (relativeDays <= 7) {
        text = "${relativeDaysNatural(mealDate)} (${conditionallyRemoveYear(context, [mealDate], showWeekDay: true)[0]})";
      } else {
        text = conditionallyRemoveYear(context, [mealDate], showWeekDay: true)[0];
      }
      children.add(
        Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 200, 200, 200),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(text),
            ),
          ),
        ),
      );
    }
    
    var unitName = unitToString(meal.productQuantity.unit);
    
    children.add(
      ListTile(
        title: Text(product?.name ?? 'Unknown', style: const TextStyle(fontSize: 16)),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${meal.productQuantity.amount}\u2009$unitName', style: const TextStyle(fontSize: 14)),
            Text('  ${meal.dateTime.hour}h', style: const TextStyle(fontSize: 14)),
          ],
        ),
        dense: true,
        minVerticalPadding: 0,
        visualDensity: const VisualDensity(vertical: -2),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => {},
        ),
      ),
    );
    if (i < meals.length - 1) {
      children.add(const Divider(
        indent: 10,
        endIndent: 10,
        height: 1,
      ));
    }
  }
  
  return Column(
    children: children,
  );
}

Widget getHorizontalLine() =>
  const Divider(
    indent: 10,
    endIndent: 10,
    height: 1,
  );