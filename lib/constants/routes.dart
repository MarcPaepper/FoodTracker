import 'package:flutter/material.dart';
import '../views/edit_meal_view.dart';
import '../views/edit_nutvalue_view.dart';
import '../views/edit_product_view.dart';
import '../views/edit_target_view.dart';
import '../views/main_view.dart';
import '../views/meals_view.dart';
import '../views/nutvalues_view.dart';
import '../views/products_view.dart';
import '../views/stats_view.dart';
import '../views/options_view.dart';
import '../views/targets_view.dart';
import '../views/test_view.dart';

String mainRoute                 = "/debug/";
String mealsRoute                = "/meals/";
String editMealRoute             = "/meals/edit/";
String productsRoute             = "/products/";
String addProductRoute           = "/products/add/";
String editProductRoute          = "/products/edit/";
String nutvaluesRoute            = "/nutvalues/";
String addNutritionalValueRoute  = "/nutvalues/add/";
String editNutritionalValueRoute = "/nutvalues/edit/";
String targetsRoute              = "/targets/";
String addTargetRoute            = "/targets/add/";
String editTargetRoute           = "/targets/edit/";
String statsRoute                = "/stats/";
String testRoute                 = "/test/";
String optionsRoute              = "/options/";

var routes = {
  mainRoute:			(context)   => const MainView(),
  mealsRoute:		(context)     => const MealsView(),
  editMealRoute:	(context) {
    var result = ModalRoute.of(context)!.settings.arguments as int?;
    return EditMealView(
      mealId: result ?? -1,
    );
  },
  productsRoute:	  (context) => const ProductsView(),
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
  nutvaluesRoute:	(context) => const NutritionalValueView(),
  addNutritionalValueRoute:	(context) => const EditNutritionalValueView(isEdit: false),
  editNutritionalValueRoute: (context) => EditNutritionalValueView(
    isEdit: true,
    nutvalueId: ModalRoute.of(context)!.settings.arguments as int?,
  ),
  targetsRoute:		  (context) => const TargetsView(),
  addTargetRoute:	  (context) => const EditTargetView(isEdit: false),
  editTargetRoute:	(context) => EditTargetView(
    isEdit: true,
    trackedId: ModalRoute.of(context)!.settings.arguments as int,
    
  ),
  statsRoute:		  	(context) => const StatsView(),
  testRoute:	  		(context) => const TestView(),
  optionsRoute:		  (context) => const OptionsView(),
};