// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:food_tracker/views/add_meal_view.dart';
import 'package:food_tracker/views/add_product_view.dart';
import 'package:food_tracker/views/stats_view.dart';

void main() {
	runApp(
		MaterialApp(
			title: "Flutter Demo",
			theme: 
			ThemeData(
				primaryColor: Colors.teal,
				primarySwatch: Colors.teal,
				appBarTheme: AppBarTheme(
					backgroundColor: Colors.teal.shade200
				),
				textButtonTheme: TextButtonThemeData(
					style: TextButton.styleFrom(
						foregroundColor: Colors.teal.shade500
					)
				)
			),
			home: const AddProductView(),
			routes: {
				"/stats/":			(context) => const StatsView(),
				"/meals/add/":		(context) => const AddMealView(),
				"/products/add/":	(context) => const AddProductView()
			}
		)
	);
}