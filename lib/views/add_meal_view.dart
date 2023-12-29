// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

class AddMealView extends StatefulWidget {
	const AddMealView({super.key});

	@override
	State<AddMealView> createState() => _AddMealViewState();
}

class _AddMealViewState extends State<AddMealView> {
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text("Add meal"),
			),
			body: const Column(
				children: [
					Text("Datum:")
				],
			)
		);
	}
}