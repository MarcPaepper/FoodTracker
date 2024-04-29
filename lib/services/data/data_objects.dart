import 'package:collection/collection.dart';

class Product {
	int id = -1; // unique identifier
	String name = "example Product"; // must be unique
  
  Unit defaultUnit;
	Conversion densityConversion; // factor when volume is converted to weight
												// e.g. [("l", "kg", 1.035)] means 1 liter = 1.035 kg
  Conversion quantityConversion; // factor how much one quantity of the product weighs / contains
                        // e.g. [("kg", "quantity", 3)] means 3 kg = 1 quantity
  String quantityName;
  bool autoCalc; // if true, the amount of the product is calculated automatically from the ingredients list
  double amountForIngredients; // How much of the product is made out of the ingredients
  final Unit ingredientsUnit;
  double amountForNutrients;
  final Unit nutrientsUnit;
  
  List<ProductQuantity> ingredients;
  List<ProductNutrient> nutrients;
  
  // same as above but with named parameters
  Product({
    required this.id,
    required this.name,
    required this.defaultUnit,
    required this.densityConversion,
    required this.quantityConversion,
    required this.quantityName,
    required this.autoCalc,
    required this.amountForIngredients,
    required this.ingredientsUnit,
    required this.amountForNutrients,
    required this.nutrientsUnit,
    required this.ingredients,
    required this.nutrients,
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
      autoCalc: false,
      amountForIngredients: 100,
      ingredientsUnit: Unit.g,
      amountForNutrients: 100,
      nutrientsUnit: Unit.g,
      ingredients: [],
      nutrients: [],
    );
  }
  
  // same as above but as factory constructor
  factory Product.copyWithDifferentId(Product product, int newId) {
    // change nutrients product id
    List<ProductNutrient> newNutrients = product.nutrients.map((n) => ProductNutrient(
      productId: newId,
      nutritionalValueId: n.nutritionalValueId,
      autoCalc: n.autoCalc,
      value: n.value,
    )).toList();
    
    return Product(
      id: newId,
      name:                 product.name,
      defaultUnit:          product.defaultUnit,
      densityConversion:    product.densityConversion,
      quantityConversion:   product.quantityConversion,
      quantityName:         product.quantityName,
      autoCalc:             product.autoCalc,
      amountForIngredients: product.amountForIngredients,
      ingredientsUnit:      product.ingredientsUnit,
      amountForNutrients:   product.amountForNutrients,
      nutrientsUnit:        product.nutrientsUnit,
      ingredients:          product.ingredients,
      nutrients:            newNutrients,
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
           autoCalc == other.autoCalc &&
           amountForIngredients == other.amountForIngredients &&
           ingredientsUnit == other.ingredientsUnit &&
           amountForNutrients == other.amountForNutrients &&
           nutrientsUnit == other.nutrientsUnit &&
           const ListEquality().equals(ingredients, other.ingredients) &&
           const ListEquality().equals(nutrients, other.nutrients);
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return "<Product #$id '$name'>";
  }
  
  List<Unit> getAvailableUnits() => getAvailableUnitsForConversions(defaultUnit, densityConversion, quantityConversion);
}
  
List<Unit> getAvailableUnitsForConversions(
  Unit defaultUnit,
  Conversion densityConversion,
  Conversion quantityConversion,
) {
  Set<Unit> availableUnits = {};
  
  if (defaultUnit == Unit.quantity) {
    availableUnits.add(Unit.quantity);
  } else if (weightUnits.contains(defaultUnit)) {
    availableUnits.addAll(weightUnits);
  } else if (volumetricUnits.contains(defaultUnit)) {
    availableUnits.addAll(volumetricUnits);
  } else {
    throw ArgumentError("Invalid default unit: '$defaultUnit'");
  }
  
  if (densityConversion.enabled) {
    availableUnits.addAll(weightUnits);
    availableUnits.addAll(volumetricUnits);
  }
  
  if (quantityConversion.enabled) {
    availableUnits.add(Unit.quantity);
    if (weightUnits.contains(quantityConversion.unit2)) {
      availableUnits.addAll(weightUnits);
    } else {
      availableUnits.addAll(volumetricUnits);
    }
  }
  
  return availableUnits.toList();
}

class ProductQuantity {
  final int? productId;
  final double amount;
  final Unit unit;
  
  ProductQuantity({
    required this.productId,
    required this.amount,
    required this.unit,
  });
  
  @override
  bool operator ==(covariant ProductQuantity other) => productId == other.productId && amount == other.amount && unit == other.unit;
  
  @override
  int get hashCode => productId.hashCode ^ amount.hashCode ^ unit.hashCode;
  
  @override
  String toString() {
    return "<ProductQuantity $amount ${unitToString(unit)} prod id $productId>";
  }
}

enum Unit { // measurement units which products can be given in
	quantity, // the number of objects, e.g. "3 bananas"
	kg,
	g,
	mg,
	l,
	ml,
}
enum UnitType {
  weight,
  volumetric,
  quantity,
}
const Map<Unit, UnitType> unitTypes = {
  Unit.quantity: UnitType.quantity,
  Unit.kg:       UnitType.weight,
  Unit.g:        UnitType.weight,
  Unit.mg:       UnitType.weight,
  Unit.l:        UnitType.volumetric,
  Unit.ml:       UnitType.volumetric,
};
const Map<Unit, double> unitTypeFactors = {
  Unit.kg: 1,
  Unit.g: 0.001,
  Unit.mg: 0.000001,
  Unit.l: 1000,
  Unit.ml: 1,
};
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

class NutritionalValue {
	int id = -1; // unique identifier
  int orderId = -1; // order in which the values are displayed
	String name = ""; // must be unique
  String unit = "";
  bool showFullName = true;
	
	NutritionalValue(this.id, this.orderId, this.name, this.unit, this.showFullName);
  
  @override
  bool operator ==(covariant NutritionalValue other) => id == other.id;
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return "<NutritionalValue #$id '$name'>";
  }
}

class ProductNutrient {
  final int productId;
  final int nutritionalValueId;
  final bool autoCalc;
  double value;
  
  ProductNutrient({
    required this.productId,
    required this.nutritionalValueId,
    required this.autoCalc,
    required this.value,
  });
  
  @override
  bool operator ==(covariant ProductNutrient other) => productId == other.productId && nutritionalValueId == other.nutritionalValueId;
  
  @override
  int get hashCode => productId.hashCode ^ nutritionalValueId.hashCode;
  
  @override
  String toString() {
    return "<ProductNutrient of prod $productId containing $value of nutr $nutritionalValueId${autoCalc ? " (autocalc)":""}>";
  }
}
