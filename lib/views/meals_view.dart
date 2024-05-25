import 'package:flutter/material.dart';
import 'package:food_tracker/services/data/data_objects.dart';
import 'package:food_tracker/subviews/add_meal_box.dart';

import '../services/data/data_service.dart';
import '../utility/theme.dart';

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
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildListView(snapshot),
            _buildAddButton(snapshot.hasData ? snapshot.data as List<Meal> : []),
          ]
        );
      }
    );
  }
  
  Widget _buildListView(AsyncSnapshot snapshot) {
    if (snapshot.hasData) {
      // final List<Meal> meals = snapshot.data;
      // var now = DateTime.now();
      // now = DateTime(now.year, now.month, now.day, now.hour);
      // // find last recorded meal (except those in the future)
      
      
      return Expanded(
        child: ListView(
          reverse: true,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(0.0),
          children: [
            AddMealBox()
          ],
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
  
  Widget _buildAddButton(List<Meal> meals) {
    return ElevatedButton.icon(
      style: addButtonStyle,
      icon: const Icon(Icons.add),
      label: const Padding(
        padding: EdgeInsets.only(left: 5.0),
        child: Text("Add Meal"),
      ),
      onPressed: () {},
    );
  }
}