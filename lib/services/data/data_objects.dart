import 'package:collection/collection.dart';

class Product {
	int id = -1; // unique identifier
	String name = "example Product"; // must be unique
	CalcMethod nutValOrigin = CalcMethod.manual;
  
  Unit defaultUnit;
	Conversion densityConversion; // factor when volume is converted to weight
												// e.g. [("l", "kg", 1.035)] means 1 liter = 1.035 kg
  Conversion quantityConversion; // factor how much one quantity of the product weighs / contains
                        // e.g. [("kg", "quantity", 3)] means 3 kg = 1 quantity
  String quantityName;
  bool autoCalcAmount; // if true, the amount of the product is calculated automatically from the ingredients list
  double amountForIngredients; // How much of the product is made out of the ingredients
  final Unit ingredientsUnit;
  
  List<ProductQuantity> ingredients;
  
	Map<NutrionalValue, double?> nutValues = {};
  
  // same as above but with named parameters
  Product({
    required this.id,
    required this.name,
    required this.defaultUnit,
    required this.densityConversion,
    required this.quantityConversion,
    required this.quantityName,
    required this.autoCalcAmount,
    required this.amountForIngredients,
    required this.ingredientsUnit,
    required this.ingredients,
  });
  
  // default values
  factory Product.defaultValues() {
    return Product(
      id: -1,
      name: "",
      defaultUnit: Unit.g,
      densityConversion: Conversion.defaultDensity(),
      quantityConversion: Conversion.defaultQuantity(),
      quantityName: "x",
      autoCalcAmount: false,
      amountForIngredients: 100,
      ingredientsUnit: Unit.g,
      ingredients: [],
    );
  }
  
  // same as above but as factory constructor
  factory Product.copyWithDifferentId(Product product, int newId) {
    return Product(
      id: newId,
      name:                 product.name,
      defaultUnit:          product.defaultUnit,
      densityConversion:    product.densityConversion,
      quantityConversion:   product.quantityConversion,
      quantityName:         product.quantityName,
      autoCalcAmount:       product.autoCalcAmount,
      amountForIngredients: product.amountForIngredients,
      ingredientsUnit:      product.ingredientsUnit,
      ingredients:           product.ingredients,
    );
  }
  
  @override
  bool operator ==(covariant Product other) => id == other.id;
  
  bool equals(Product other) {
    return id == other.id &&
           name == other.name &&
           defaultUnit == other.defaultUnit &&
           densityConversion == other.densityConversion &&
           quantityConversion == other.quantityConversion &&
           quantityName == other.quantityName &&
           autoCalcAmount == other.autoCalcAmount &&
           amountForIngredients == other.amountForIngredients &&
           ingredientsUnit == other.ingredientsUnit &&
           const ListEquality().equals(ingredients, other.ingredients);
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return "<Product #$id '$name'>";
  }
}

class ProductQuantity {
  final Product product;
  final double amount;
  final Unit unit;
  
  ProductQuantity({
    required this.product,
    required this.amount,
    required this.unit,
  });
  
  @override
  bool operator ==(covariant ProductQuantity other) => product == other.product && amount == other.amount && unit == other.unit;
  
  @override
  int get hashCode => product.hashCode ^ amount.hashCode ^ unit.hashCode;
  
  @override
  String toString() {
    return "<ProductQuantity $amount ${unitToString(unit)} of $product>";
  }
}

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
}
const List<Unit> volumetricUnits = [Unit.l, Unit.ml];
const List<Unit> weightUnits = [Unit.kg, Unit.g, Unit.mg];

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
      return "l";
    case Unit.ml:
      return "ml";
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
  
  const Conversion({
    required this.enabled,
    required this.unit1,
    required this.amount1,
    required this.unit2,
    required this.amount2,
  });
  
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
      
      return Conversion(
        enabled: enabled,
        unit1: unit1,
        amount1: amount1,
        unit2: unit2,
        amount2: amount2,
      );
    } catch (e) {
      throw ArgumentError("Invalid conversion string: '$input'");
    }
  }
  
  @override
  String toString() => "$amount1 ${unitToString(unit1)} = $amount2 ${unitToString(unit2)} ${enabled ? "enabled" : "disabled"}";
  
  Conversion switched(bool newEnabled) => Conversion(
    enabled: newEnabled,
    unit1: unit1,
    amount1: amount1,
    unit2: unit2,
    amount2: amount2,
  );
  
  Conversion withUnit1(Unit newUnit1) => Conversion(
    enabled: enabled,
    unit1: newUnit1,
    amount1: amount1,
    unit2: unit2,
    amount2: amount2,
  );
  
  Conversion withUnit2(Unit newUnit2) => Conversion(
    enabled: enabled,
    unit1: unit1,
    amount1: amount1,
    unit2: newUnit2,
    amount2: amount2,
  );
  
  Conversion withAmount1(double newAmount1) => Conversion(
    enabled: enabled,
    unit1: unit1,
    amount1: newAmount1,
    unit2: unit2,
    amount2: amount2,
  );
  
  Conversion withAmount2(double newAmount2) => Conversion(
    enabled: enabled,
    unit1: unit1,
    amount1: amount1,
    unit2: unit2,
    amount2: newAmount2,
  );
  
  factory Conversion.defaultDensity() => const Conversion(
    enabled: false,
    unit1: Unit.ml,
    amount1: 100,
    unit2: Unit.g,
    amount2: 100,
  );
  
  factory Conversion.defaultQuantity() => const Conversion(
    enabled: false,
    unit1: Unit.quantity,
    amount1: 1,
    unit2: Unit.g,
    amount2: 100,
  );
  
  @override
  bool operator ==(covariant Conversion other) => toString() == other.toString();
  
  @override
  int get hashCode => toString().hashCode;
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
