// import "dart:developer" as devtools show log;

// enum CalcMethod {
// 	manual, // the nutrional values for the product are given by the user
// 	auto, // the nutrional values are calculated automatically from the ingredients list
// }

// enum Unit { // measurement units which products can be given in
// 	quantity, // the number of objects used / consumed, e.g. "3 bananas"
// 	kg,
// 	g,
// 	mg,
// 	l,
// 	ml,
// 	ounce,
// 	lbs,
// }

// // exceptions

// // user tried to input information that is in conflict to itself or other data. This includes assigning
// // impossible nutritional values, assigning already taken unique fields or creating a circular reference
// class InputConflictException implements Exception {
	
// }

// class NutrionalValue {
// 	int id = -1; // unique identifier
// 	// the ids 0-6 are reserved for the preset nutrional values "energy", "fat", "saturated fat", "carbohydrates", "sugar", "protein", "salt"
// 	String name = ""; // must be unique
	
// 	NutrionalValue(name) {
// 		// check whether name is unique
// 		for (var nutVal in nutValues) {
// 			if (nutVal.name == name) {
// 				// throw 
				
// 				devtools.log("Error: Nutrional value name must be unique");
// 			}
// 		}
// 	}
// }

// class Product {
// 	int id = -1; // unique identifier
// 	String name = "example Product"; // must be unique
// 	List<(Product, double, Unit)> ingredients = []; // How much of different products the product is composed of
// 	CalcMethod nutValOrigin = CalcMethod.manual;
// 	List<(Unit, Unit, double)> unitConversions = []; // factors when one dimension is converted to another
// 												// e.g. [("l", "kg", 1.035)] means 1 liter = 1.035 kg
// 												// there can only be one conversion between weight, volume and quantity respectively
// 	Map<NutrionalValue, double?> nutValues = {};
  
//   Product(this.name) {
//     // check whether name is unique
//     for (var prod in products) {
//       if (prod.name == name) {
// 				devtools.log("Error: Product name must be unique");
//       }
//     }
//   }
  
//   @override
//   String toString() {
//     return "<Product '$name'>";
//   }
// }

// List<Product> products = [];
// List<NutrionalValue> nutValues = [];

// Future<String> loadData() {
// 	return Future.delayed(
// 		const Duration(milliseconds: 500), () {
// 			// create the 7 default nutrional values
// 			nutValues.add(NutrionalValue(""));
// 			return "data loaded";
// 		});
// }

// List<Product> getProducts() {
//   return [
//     Product("Example Product 1"),
//     Product("Example Product 2"),
//     Product("Example Product 3"),
//   ];
// }

// String getFullName(String firstName, String lastName) => "$firstName $lastName";

// class Person {
// 	Family operator +(Person other) {
// 		return Family([this, other]);
// 	}
// }

// class Family {
// 	final List<Person> people;
// 	Family(this.people);
// }