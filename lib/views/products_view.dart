import 'package:flutter/material.dart';
import 'package:food_tracker/constants/routes.dart';

class ProductsView extends StatelessWidget {
	const ProductsView({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold (
			appBar: AppBar(
				title: const Text("Products"),
				actions: [
					IconButton(
						onPressed: () {
							Navigator.of(context).pushNamed(addProductRoute);
						},
						icon: const Icon(Icons.add)
					)
				]
			),
			body: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					TextButton(
						onPressed: () {
							Navigator.of(context).pushNamed(addMealsRoute);
						},
						child: const Text("Add Meal")
					),
					TextButton(
						onPressed: () {
							Navigator.of(context).pushNamedAndRemoveUntil(statsRoute, (route) => false);
						},
						child: const Text("Stats")
					),
				],
			),
		);
	}
}
