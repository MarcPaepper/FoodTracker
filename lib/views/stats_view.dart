

import 'package:flutter/material.dart';

class StatsView extends StatelessWidget {
	const StatsView({Key? key}) : super(key: key);

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text("Stats")
			),
			body: Center(
				child: TextButton(
					child: const Text("data"),
					onPressed: () {},
				)
			)
		);
	}
}