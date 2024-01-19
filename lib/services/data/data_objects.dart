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

Unit unitFromString(String input) {
  switch (input) {
    case "x":
      return Unit.quantity;
    case "kg":
      return Unit.kg;
    case "g":
      return Unit.g;
    case "mg":
      return Unit.mg;
    case "l":
      return Unit.l;
    case "ml":
      return Unit.ml;
    case "ounce":
      return Unit.ounce;
    case "lbs":
      return Unit.lbs;
    default:
      throw ArgumentError("Invalid unit string: '$input'");
  }
}

String unitToString(Unit unit) {
  switch (unit) {
    case Unit.quantity:
      return "x";
    case Unit.kg:
      return "kg";
    case Unit.g:
      return "g";
    case Unit.mg:
      return "mg";
    case Unit.l:
      return "l";
    case Unit.ml:
      return "ml";
    case Unit.ounce:
      return "ounce";
    case Unit.lbs:
      return "lbs";
    default:
      throw ArgumentError("Invalid unit: '$unit'");
  }
}

class Conversion {
  final Unit from;
  final Unit to;
  final double factor;
  
  const Conversion(this.from, this.to, this.factor);
  // input has to be of the form "xx [unit] = yy [unit]"
  factory Conversion.fromString(String input) {
    
  }
}

class NutrionalValue {
	int id = -1; // unique identifier
	// the ids 0-6 are reserved for the preset nutrional values "energy", "fat", "saturated fat", "carbohydrates", "sugar", "protein", "salt"
	String name = ""; // must be unique
  String unit = "";
	
	NutrionalValue(this.id, this.name, this.unit);
  
  @override
  bool operator ==(covariant NutrionalValue other) => id == other.id;
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return "<NutrionalValue #$id '$name'>";
  }
}

class Product {
	int id = -1; // unique identifier
	String name = "example Product"; // must be unique
	List<(Product, double, Unit)> ingredients = []; // How much of different products the product is composed of
	CalcMethod nutValOrigin = CalcMethod.manual;
	Conversion densityConversion; // factor when volume is converted to weight
												// e.g. [("l", "kg", 1.035)] means 1 liter = 1.035 kg
  Conversion quantityConversion; // factor how much one quantity of the product weighs / contains
                        // e.g. [("kg", "quantity", 3)] means 3 kg = 1 quantity
	Map<NutrionalValue, double?> nutValues = {};
  
  Product(this.id, this.name);
  
  @override
  bool operator ==(covariant Product other) => id == other.id;
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return "<Product #$id '$name'>";
  }
}
