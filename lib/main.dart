// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

enum CalcMethod {
	manual, // the nutrional values for the product are given by the user
	auto, // the nutrional values are calculated automatically from the ingredients list
}

enum Unit { // measurement units which products can be given in
	quantity, // the number of objects used / consumed, e.g. "3 bananas"
	kg,
	g,
	mg,
	l,
	ml,
	ounce,
	lbs,
}

// exceptions

// user tried to input information that is in conflict to itself or other data. This includes assigning
// impossible nutritional values, assigning already taken unique fields or creating a circular reference
class InputConflictException implements Exception {
	
}

class NutrionalValue {
	int id = -1; // unique identifier
	// the ids 0-6 are reserved for the preset nutrional values "energy", "fat", "saturated fat", "carbohydrates", "sugar", "protein", "salt"
	String name = ""; // must be unique
	
	NutrionalValue(name) {
		// check whether name is unique
		for (var nutVal in nutValues) {
			if (nutVal.name == name) {
				throw 
				
				//print("Error: Nutrional value name must be unique");
			}
		}
	}
}

class Product {
	int id = -1; // unique identifier
	String name = "example Product"; // must be unique
	List<(Product, double, Unit)> ingredients = []; // How much of different products the product is composed of
	CalcMethod nutValOrigin = CalcMethod.manual;
	List<(Unit, Unit, double)> unitConversions = []; // factors when one dimension is converted to another
												// e.g. [("l", "kg", 1.035)] means 1 liter = 1.035 kg
												// there can only be one conversion between weight, volume and quantity respectively
	Map<NutrionalValue, double?> nutValues = {};
}

List<Product> products = [];
List<NutrionalValue> nutValues = [];

void main() {
	runApp(const MyApp());
}

loadData() {
	// create the 7 default nutrional values
	nutValues.add(NutrionalValue(""));
}

String getFullName(String firstName, String lastName) => "$firstName $lastName";

class Person {
	Family operator +(Person other) {
		return Family([this, other]);
	}
}

class Family {
	final List<Person> people;
	Family(this.people);
}

class MyApp extends StatelessWidget {
	const MyApp({super.key});
	
	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			title: 'Flutter Demo',
			theme: ThemeData(
				colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
				useMaterial3: true,
			),
			home: const MyHomePage(title: 'Flutter Demo Home Page'),
		);
	}
}

class MyHomePage extends StatefulWidget {
	const MyHomePage({super.key, required this.title});

	final String title;

	@override
	State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
	int _counter = 0;

	void _incrementCounter() {
		setState(() {
			// This call to setState tells the Flutter framework that something has
			// changed in this State, which causes it to rerun the build method below
			// so that the display can reflect the updated values. If we changed
			// _counter without calling setState(), then the build method would not be
			// called again, and so nothing would appear to happen.
			_counter++;
		});
	}

	@override
	Widget build(BuildContext context) {
		// This method is rerun every time setState is called, for instance as done
		// by the _incrementCounter method above.
		//
		// The Flutter framework has been optimized to make rerunning build methods
		// fast, so that you can just rebuild anything that needs updating rather
		// than having to individually change instances of widgets.
		return Scaffold(
			appBar: AppBar(
				// TRY THIS: Try changing the color here to a specific color (to
				// Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
				// change color while the other colors stay the same.
				backgroundColor: Theme.of(context).colorScheme.inversePrimary,
				// Here we take the value from the MyHomePage object that was created by
				// the App.build method, and use it to set our appbar title.
				title: Text(widget.title),
			),
			body: Center(
				// Center is a layout widget. It takes a single child and positions it
				// in the middle of the parent.
				child: Column(
					// Column is also a layout widget. It takes a list of children and
					// arranges them vertically. By default, it sizes itself to fit its
					// children horizontally, and tries to be as tall as its parent.
					//
					// Column has various properties to control how it sizes itself and
					// how it positions its children. Here we use mainAxisAlignment to
					// center the children vertically; the main axis here is the vertical
					// axis because Columns are vertical (the cross axis would be
					// horizontal).
					//
					// TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
					// action in the IDE, or press "p" in the console), to see the
					// wireframe for each widget.
					mainAxisAlignment: MainAxisAlignment.center,
					children: <Widget>[
						const Text(
							'You have pushed the button this many times:',
						),
						Text(
							'$_counter',
							style: Theme.of(context).textTheme.headlineMedium,
						),
					],
				),
			),
			floatingActionButton: FloatingActionButton(
				onPressed: _incrementCounter,
				tooltip: 'Increment',
				child: const Icon(Icons.add),
			), // This trailing comma makes auto-formatting nicer for build methods.
		);
	}
}
