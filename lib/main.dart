import 'package:flutter/material.dart';
import 'views/products_view.dart';
import 'constants/routes.dart';
import 'views/add_meal_view.dart';
import 'views/add_product_view.dart';
import 'views/stats_view.dart';

void main() {
  runApp(
    MaterialApp(
      title: "Food Tracker",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal.shade400,
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.grey),
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          filled: true,
          fillColor: Colors.grey.withAlpha(35),
          enabledBorder: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(
              width: 3,
              color: Colors.grey
            )
          ),
          focusedBorder: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              width: 2.5,
              color: Colors.teal.shade400
            )
          ),
          errorBorder: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(
              width: 2.5,
              color: Color.fromARGB(211, 154, 32, 32)
            )
          ),
          focusedErrorBorder: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              width: 3.5,
              color: Colors.red.shade500
            )
          ),
        ),
      ),
      home: const ProductsView(),
      routes: {
        addMealsRoute:		(context) => const AddMealView(),
        productsRoute:	  (context) => const ProductsView(),
        addProductRoute:	(context) => const AddProductView(),
        statsRoute:		  	(context) => const StatsView(),
      }
    )
  );
}