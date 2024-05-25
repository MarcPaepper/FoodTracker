import 'package:flutter/material.dart';
// import '../views/add_meal_view.dart';
import '../views/edit_nutvalue_view.dart';
import '../views/edit_product_view.dart';
import '../views/main_view.dart';
import '../views/meals_view.dart';
import '../views/nutvalues_view.dart';
import '../views/stats_view.dart';
import '../views/options_view.dart';
import '../views/test_view.dart';

String mainRoute                 = "/debug/";
String mealsRoute                = "/meals/";
// String addMealsRoute             = "/meals/add/";
String productsRoute             = "/products/";
String addProductRoute           = "/products/add/";
String editProductRoute          = "/products/edit/";
String addNutritionalValueRoute  = "/nutvalues/add/";
String editNutritionalValueRoute = "/nutvalues/edit/";
String statsRoute                = "/stats/";
String testRoute                 = "/test/";
String optionsRoute              = "/options/";

var routes = {
  mainRoute:			(context)   => const MainView(),
  mealsRoute:		(context)     => const MealsView(),
  // addMealsRoute:		(context) => const AddMealView(),
  productsRoute:	  (context) => const NutritionalValueView(),
  addProductRoute:	(context) {
    var result = ModalRoute.of(context)!.settings.arguments as (String?, bool?)?;
    return EditProductView(
      isEdit: false,
      productName: result?.$1,
      isCopy: result?.$2 ?? false,
    );
  },
  editProductRoute: (context) {
    var result = ModalRoute.of(context)!.settings.arguments as (String?, bool?)?;
    return EditProductView(
      isEdit: true,
      productName: result?.$1,
    );
  },
  addNutritionalValueRoute:	(context) => const EditNutritionalValueView(isEdit: false),
  editNutritionalValueRoute: (context) {
    return EditNutritionalValueView(
      isEdit: true,
      nutvalueId: ModalRoute.of(context)!.settings.arguments as int?,
    );
  },
  statsRoute:		  	(context) => const StatsView(),
  testRoute:	  		(context) => const TestView(),
  optionsRoute:		  (context) => const OptionsView(),
};