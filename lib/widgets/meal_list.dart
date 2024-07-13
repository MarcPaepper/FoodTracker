import "package:flutter/material.dart";

import "../services/data/data_objects.dart";
import "../services/data/data_service.dart";
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
  final DataService dataService = DataService.current();
  
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
        ...getMealTiles(context, dataService, widget.productsMap, widget.meals),
      ],
    );
  }
}

List<Widget> getMealTiles(BuildContext context, DataService dataService, Map<int, Product>? productsMap, List<Meal> meals) {
  List<Widget> children = [];                                                                                                         
  DateTime lastHeader = meals.isNotEmpty
    ? DateTime(meals[0].dateTime.year, meals[0].dateTime.month, meals[0].dateTime.day)
    : DateTime(0);
  devtools.log('----');
  for (int i = 0; i < meals.length; i++) {
    final meal = meals[i];
    final product = productsMap?[meal.productQuantity.productId];
    final mealDate = DateTime(meal.dateTime.year, meal.dateTime.month, meal.dateTime.day);
    devtools.log('mealDate: $mealDate');
    
    if (lastHeader.isAfter(mealDate)) {
      // print error
      devtools.log('MealList: meals are not sorted by date');
    } else if (lastHeader.isAfter(mealDate)) {
      children.add(getDateStrip(context, lastHeader));
      lastHeader = mealDate;
    } else {
      // add divider
      children.add(getHorizontalLine());
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
        trailing: // three dot menu
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 0,
                child: const Text('Edit'),
              ),
              PopupMenuItem(
                value: 1,
                child: const Text('Delete'),
              ),
            ],
            onSelected: (int value) {
              if (value == 0) {
                // edit
              } else if (value == 1) {
                // delete
                dataService.deleteMeal(meal.id);
              }
            },
          ),
      ),
    );
  }
  
  if (meals.isNotEmpty) {
    children.add(getDateStrip(context, lastHeader));
  }
  
  return children;
}

Widget getHorizontalLine() =>
  const Divider(
    indent: 10,
    endIndent: 10,
    height: 1,
  );

Widget getDateStrip(BuildContext context, DateTime dateTime) {
  // Convert date to natural string
      String text;
      int relativeDays = dateTime.difference(DateTime.now()).inDays.abs();
      if (relativeDays <= 7) {
        text = "${relativeDaysNatural(dateTime)} (${conditionallyRemoveYear(context, [dateTime], showWeekDay: true)[0]})";
      } else {
        text = conditionallyRemoveYear(context, [dateTime], showWeekDay: true)[0];
      }
  
  return Container(
    decoration: const BoxDecoration(
      color: Color.fromARGB(255, 200, 200, 200),
    ),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Text(text),
      ),
    ),
  );
}