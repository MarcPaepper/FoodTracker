import 'package:flutter/material.dart';
import 'package:food_tracker/widgets/meal_list.dart';

import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';

class MealsView extends StatefulWidget {
  const MealsView({super.key});

  @override
  State<MealsView> createState() => _MealsViewState();
}

class _MealsViewState extends State<MealsView> {
  late final DataService _dataService;
  
  @override
  void initState() {
    _dataService = DataService.current();
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _dataService.streamMeals(),
      builder: (contextM, snapshotM) {
        return StreamBuilder<List<Product>>(
          stream: _dataService.streamProducts(),
          builder: (contextP, snapshotP) {
            Map<int, Product>? productsMap;
            if (snapshotP.hasData) {
              final List<Product> products = snapshotP.data as List<Product>;
              productsMap = Map.fromEntries(products.map((prod) => MapEntry(prod.id, prod)));
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildListView(snapshotM, productsMap),
              ]
            );
          }
        );
      }
    );
  }
  
  Widget _buildListView(AsyncSnapshot snapshot, Map<int, Product>? productsMap) {
    if (snapshot.hasData) {
      final List<Meal> meals = snapshot.data;
      var now = DateTime.now();
      now = DateTime(now.year, now.month, now.day, now.hour);
      // find last recorded meal (except those in the future)
      DateTime? lastMeal;
      for (final meal in meals) {
        if (lastMeal == null || meal.dateTime.isBefore(lastMeal)) {
          lastMeal = meal.dateTime;
        }
      }
      
      return Expanded(
        child: MealList(
          productsMap: productsMap,
          meals: meals,
        )
      );
    } else {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        )
      );
    }
  }
}