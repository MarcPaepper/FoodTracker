import "package:flutter/material.dart";
import "package:food_tracker/services/data/async_provider.dart";

import "../constants/routes.dart";
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
          onDateTimeChanged: (newDateTime) => Future.delayed(const Duration(milliseconds: 100), () => AsyncProvider.changeCompDT(newDateTime)),
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
  DateTime lastHeader = DateTime(0);
  if (meals.isNotEmpty) {
    var lastMeal = meals[meals.length - 1];
    var lastDate = lastMeal.dateTime;
    lastHeader = DateTime(lastDate.year, lastDate.month, lastDate.day);
  }
  for (int i = meals.length - 1; i >= 0; i--) {
    final meal = meals[i];
    final product = productsMap?[meal.productQuantity.productId];
    final mealDate = DateTime(meal.dateTime.year, meal.dateTime.month, meal.dateTime.day);
    
    if (lastHeader.isBefore(mealDate)) {
      devtools.log('MealList: meals are not sorted by date');
    } else if (lastHeader.isAfter(mealDate)) {
      children.add(getDateStrip(context, lastHeader));
      lastHeader = mealDate;
    } else if (i < meals.length - 1) {
      children.add(_buildHorizontalLine());
    }
    
    var unitName = unitToString(meal.productQuantity.unit);
    var productName = product?.name ?? 'Unknown';
    var amountText = '${truncateZeros(meal.productQuantity.amount)}\u2009$unitName';
    var hourText = '${meal.dateTime.hour}h';
    
    children.add(
      ListTile(
        title: Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2.5),
                  Text(productName, style: const TextStyle(fontSize: 16.5)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(amountText, style: const TextStyle(fontSize: 14)),
                      Text(hourText, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
            PopupMenuButton(
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 0,
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: 1,
                  child: Text('Delete'),
                ),
              ],
              onSelected: (int value) {
                if (value == 0) {
                  // edit
                  // navigate to edit meal view
                  Navigator.pushNamed(context, editMealRoute, arguments: meal.id);
                } else if (value == 1) {
                  // delete
                  dataService.deleteMeal(meal.id);
                }
              },
            ),
          ],
        ),
        minVerticalPadding: 0,
        visualDensity: const VisualDensity(vertical: -4, horizontal: 0),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
  
  if (meals.isNotEmpty) {
    children.add(getDateStrip(context, lastHeader));
  }
  
  return children;
}

Widget _buildHorizontalLine() =>
  const Divider(
    indent: 7,
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
  
  return Column(
    children: [
      //const SizedBox(height: 5),
      Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 200, 200, 200),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(text, style: const TextStyle(fontSize: 15.5)),
          ),
        ),
      ),
    ],
  );
}