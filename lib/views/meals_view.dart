import 'package:flutter/material.dart';
import 'package:food_tracker/widgets/meal_list.dart';

import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../widgets/multi_stream_builder.dart';

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
    return MultiStreamBuilder(
      streams: [
        _dataService.streamMeals(),
        _dataService.streamProducts(),
      ],
      builder: (context, snapshots) {
        Map<int, Product>? productsMap;
        if (snapshots[1].hasData) {
          final List<Product> products = snapshots[1].data as List<Product>;
          productsMap = Map.fromEntries(products.map((prod) => MapEntry(prod.id, prod)));
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          verticalDirection: VerticalDirection.down,
          children: [
            _buildListView(snapshots[0], productsMap),
          ]
        );
      }
    );
  }
  
  Widget _buildListView(AsyncSnapshot snapshot, Map<int, Product>? productsMap) {
    List<Meal> meals = [];
    
    if (snapshot.hasData) meals = snapshot.data;
      // var now = DateTime.now();
      // now = DateTime(now.year, now.month, now.day, now.hour);
      // find last recorded meal (except those in the future)
      // DateTime? lastMeal;
      // for (final meal in meals) {
      //   if (lastMeal == null || meal.dateTime.isBefore(lastMeal)) {
      //     lastMeal = meal.dateTime;
      //   }
      // }
      
      // // only keep last 1000 meals
      // if (meals.length > 1000) {
      //   meals.removeRange(0, meals.length - 1000);
      // }
    // } else {
    //   return const Expanded(
    //     child: Center(
    //       child: CircularProgressIndicator(),
    //     )
    //   );
    // }
    
    return Expanded(
      child: MealList(
        productsMap: productsMap,
        meals: meals,
        loaded: snapshot.hasData,
      )
    );
  }
}