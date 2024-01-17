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

class NutrionalValue {
	int id = -1; // unique identifier
	// the ids 0-6 are reserved for the preset nutrional values "energy", "fat", "saturated fat", "carbohydrates", "sugar", "protein", "salt"
	String name = ""; // must be unique
	
	NutrionalValue(name) {
		// check whether name is unique
		// for (var nutVal in nutValues) {
		// 	if (nutVal.name == name) {
		// 		// throw 
				
		// 		devtools.log("Error: Nutrional value name must be unique");
		// 	}
		// }
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
  
  Product(this.id, this.name) {
    // check whether name is unique
    // for (var prod in products) {
    //   if (prod.name == name) {
		// 		devtools.log("Error: Product name must be unique");
    //   }
    // }
  }
  
  Product.empty() {
    name = "";
  }
  
  @override
  bool operator ==(covariant Product other) => id == other.id;
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return "<Product #$id '$name'>";
  }
}
