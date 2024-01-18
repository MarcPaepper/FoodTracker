import 'package:flutter/material.dart';
import 'package:food_tracker/utility/theme.dart';
import 'package:food_tracker/views/main_view.dart';
import 'views/nutvalues_view.dart';
import 'constants/routes.dart';
import 'views/add_meal_view.dart';
import 'views/edit_product_view.dart';
import 'views/stats_view.dart';

// import "dart:developer" as devtools show log;

void main() {
  runApp(
    MaterialApp(
      title: "Food Tracker",
      debugShowCheckedModeBanner: false,
      theme: getTheme(),
      home: const MainView(),
      routes: {
        addMealsRoute:		(context) => const AddMealView(),
        productsRoute:	  (context) => const NutrionalValueView(),
        addProductRoute:	(context) => const EditProductView(isEdit: false),
        editProductRoute: (context) {
          return EditProductView(
            isEdit: true,
            productId: ModalRoute.of(context)!.settings.arguments as int?,
          );
        },
        statsRoute:		  	(context) => const StatsView(),
      }
    )
  );
}