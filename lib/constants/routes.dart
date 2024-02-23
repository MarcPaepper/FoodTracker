import 'package:flutter/material.dart';
import 'package:food_tracker/views/add_meal_view.dart';
import 'package:food_tracker/views/edit_nutvalue_view.dart';
import 'package:food_tracker/views/edit_product_view.dart';
import 'package:food_tracker/views/main_view.dart';
import 'package:food_tracker/views/nutvalues_view.dart';
import 'package:food_tracker/views/stats_view.dart';

String mainRoute       = "/debug/";
String addMealsRoute   = "/meals/add/";
String productsRoute   = "/products/";
String addProductRoute = "/products/add/";
String editProductRoute = "/products/edit/";
String addNutrionalValueRoute = "/nutvalues/add/";
String editNutrionalValueRoute = "/nutvalues/edit/";
String statsRoute      = "/stats/";

var routes = {
  mainRoute:			(context)   => const MainView(),
  addMealsRoute:		(context) => const AddMealView(),
  productsRoute:	  (context) => const NutrionalValueView(),
  addProductRoute:	(context) {
    return EditProductView(
      isEdit: false,
      productName: ModalRoute.of(context)!.settings.arguments as String?,
    );
  },
  editProductRoute: (context) {
    return EditProductView(
      isEdit: true,
      productName: ModalRoute.of(context)!.settings.arguments as String?,
    );
  },
  addNutrionalValueRoute:	(context) => const EditNutrionalValueView(isEdit: false),
  editNutrionalValueRoute: (context) {
    return EditNutrionalValueView(
      isEdit: true,
      nutvalueId: ModalRoute.of(context)!.settings.arguments as int?,
    );
  },
  statsRoute:		  	(context) => const StatsView(),
};