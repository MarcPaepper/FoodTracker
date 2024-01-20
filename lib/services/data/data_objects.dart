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
    case Unit.kg:
      return "kg";
    case Unit.g:
      return "g";
    case Unit.mg:
      return "mg";
    case Unit.l:
      return "L";
    case Unit.ml:
      return "ml";
    case Unit.ounce:
      return "ounce";
    case Unit.lbs:
      return "lbs";
    case Unit.quantity:
      return "x";
    default:
      throw ArgumentError("Invalid unit: '$unit'");
  }
}

String unitToLongString(Unit unit) {
  switch (unit) {
    case Unit.kg:
      return "Kilogram";
    case Unit.g:
      return "Gram";
    case Unit.mg:
      return "Milligram";
    case Unit.l:
      return "Liter";
    case Unit.ml:
      return "Milliliter";
    case Unit.ounce:
      return "Ounce";
    case Unit.lbs:
      return "Pound";
    case Unit.quantity:
      return "Quantity";
    default:
      throw ArgumentError("Invalid unit: '$unit'");
  }
}

class Conversion {
  final bool enabled;
  final Unit unit1;
  final double amount1;
  final Unit unit2;
  final double amount2;
  
  const Conversion(this.enabled, this.unit1, this.amount1, this.unit2, this.amount2);
  
  // input has to be of the form "xxx [fromUnit] = yyy [toUnit] [enabled|disabled]"
  factory Conversion.fromString(String input) {
    try {
      var parts = input.split(" ");
      if (parts.length != 6) {
        throw ArgumentError("Invalid conversion string: '$input'");
      }
      
      var amount1 = double.parse(parts[0]);
      var unit1 = unitFromString(parts[1]);
      var amount2 = double.parse(parts[3]);
      var unit2 = unitFromString(parts[4]);
      var enabled = parts[5] == "enabled";
      
      return Conversion(enabled, unit1, amount1, unit2, amount2);
    } catch (e) {
      throw ArgumentError("Invalid conversion string: '$input'");
    }
  }
  
  @override
  String toString() => "$amount1 ${unitToString(unit1)} = $amount2 ${unitToString(unit2)} ${enabled ? "enabled" : "disabled"}";
  
  Conversion switched(bool newEnabled) => Conversion(newEnabled, unit1, amount1, unit2, amount2);
  Conversion withUnit1(Unit newUnit1) => Conversion(enabled, newUnit1, amount1, unit2, amount2);
  Conversion withUnit2(Unit newUnit2) => Conversion(enabled, unit1, amount1, newUnit2, amount2);
  Conversion withAmount1(double newAmount1) => Conversion(enabled, unit1, newAmount1, unit2, amount2);
  Conversion withAmount2(double newAmount2) => Conversion(enabled, unit1, amount1, unit2, newAmount2);
  
  
  factory Conversion.defaultDensity() => const Conversion(false, Unit.ml, 100, Unit.g, 100);
  
  factory Conversion.defaultQuantity() => const Conversion(false, Unit.quantity, 1, Unit.g, 100);
}

class NutrionalValue {
	int id = -1; // unique identifier
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
  
  Unit defaultUnit;
	Conversion densityConversion; // factor when volume is converted to weight
												// e.g. [("l", "kg", 1.035)] means 1 liter = 1.035 kg
  Conversion quantityConversion; // factor how much one quantity of the product weighs / contains
                        // e.g. [("kg", "quantity", 3)] means 3 kg = 1 quantity
  String quantityUnit;
  
	Map<NutrionalValue, double?> nutValues = {};
  
  Product(this.id, this.name, this.defaultUnit, this.densityConversion, this.quantityConversion, this.quantityUnit);
  
  // same as above but as factory constructor
  factory Product.copyWithDifferentId(Product product, int newId) {
    return Product(
      newId,
      product.name,
      product.defaultUnit,
      product.densityConversion,
      product.quantityConversion,
      product.quantityUnit,
    );
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
