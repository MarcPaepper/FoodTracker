// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:food_tracker/data_manager.dart';

class AddProductView extends StatefulWidget {
	const AddProductView({super.key});

	@override
	State<AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends State<AddProductView> {
	late final TextEditingController _name;
	
	@override
	void initState() {
		_name = TextEditingController();
		super.initState();
	}
	
	@override
	void dispose() {
		_name.dispose();
		super.dispose();
	}
	
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text("Add product"),
			),
			body: FutureBuilder(
				future: loadData(),
				builder: (context, snapshot) {
					switch (snapshot.connectionState) {
						
						case ConnectionState.done:
							return Column(
								children: [
									TextField(
										controller: _name,
										decoration: const InputDecoration(
											hintText: "Name"
										),
									),
									TextButton(
										onPressed: () {
											final name = _name.text;
											print("name $name");
										},
										child: const Text("Add")
									)
								]
							);
						case ConnectionState.none:
						case ConnectionState.waiting:
						case ConnectionState.active:
							return Align(
								alignment: Alignment.topCenter,
								child: Padding(
									padding: const EdgeInsets.all(50.0),
									child: SizedBox(
										width: 30,
										height: 30,
										child: CircularProgressIndicator(
											color: Colors.teal.shade500
										),
									),
								)
							);
					}
				}
			)
		);
	}
}