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
          filled: true,
          fillColor: Colors.grey.shade100,
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