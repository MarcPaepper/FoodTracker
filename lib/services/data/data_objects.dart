import 'package:collection/collection.dart';

import 'dart:developer' as devtools show log;

class Product {
	int id = -1; // unique identifier
	String name = "example Product"; // must be unique
  
  DateTime? creationDate;
  DateTime? lastEditDate;
  DateTime? temporaryBeginning;
  DateTime? temporaryEnd;
  
  bool isTemporary;
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
             this.creationDate,
             this.lastEditDate,
             this.temporaryBeginning,
             this.temporaryEnd,
    required this.isTemporary,
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
      isTemporary: false,
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
  
  copyWith({
    int? newId,
    String? newName,
    DateTime? newCreationDate,
    DateTime? newLastEditDate,
    Unit? newDefaultUnit,
    DateTime? newTemporaryBeginning,
    DateTime? newTemporaryEnd,
    bool? newIsTemporary,
    Conversion? newDensityConversion,
    Conversion? newQuantityConversion,
    String? newQuantityName,
    bool? newAutoCalc,
    double? newAmountForIngredients,
    Unit? newIngredientsUnit,
    double? newAmountForNutrients,
    Unit? newNutrientsUnit,
    List<ProductQuantity>? newIngredients,
    List<ProductNutrient>? newNutrients,
  }) {
    // change nutrients product id
    
    if (newId != null && newNutrients == null) {
      newNutrients = nutrients.map((n) => ProductNutrient(
        productId: newId,
        nutritionalValueId: n.nutritionalValueId,
        autoCalc: n.autoCalc,
        value: n.value,
      )).toList();
    }
    
    return Product(
      id:                   newId ?? id,
      name:                 newName ?? name,
      defaultUnit:          newDefaultUnit ?? defaultUnit,
      creationDate:         newCreationDate ?? creationDate,
      lastEditDate:         newLastEditDate ?? lastEditDate,
      temporaryBeginning:   newTemporaryBeginning ?? temporaryBeginning,
      temporaryEnd:         newTemporaryEnd ?? temporaryEnd,
      isTemporary:          newIsTemporary ?? isTemporary,
      densityConversion:    newDensityConversion ?? densityConversion,
      quantityConversion:   newQuantityConversion ?? quantityConversion,
      quantityName:         newQuantityName ?? quantityName,
      autoCalc:             newAutoCalc ?? autoCalc,
      amountForIngredients: newAmountForIngredients ?? amountForIngredients,
      ingredientsUnit:      newIngredientsUnit ?? ingredientsUnit,
      amountForNutrients:   newAmountForNutrients ?? amountForNutrients,
      nutrientsUnit:        newNutrientsUnit ?? nutrientsUnit,
      ingredients:          newIngredients ?? ingredients,
      nutrients:            newNutrients ?? nutrients,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (other is Product) {
      return id == other.id;
    }
    return false;
  }
  
  // bool equals(Product other) {
  //   // order other nutrients by id
  //   var otherNutrients = other.nutrients.toList();
  //   otherNutrients.sort((a, b) => a.nutritionalValueId - b.nutritionalValueId);
    
  //   return id == other.id &&
  //          name == other.name &&
  //          temporaryBeginning == other.temporaryBeginning &&
  //          temporaryEnd == other.temporaryEnd &&
  //          isTemporary == other.isTemporary &&
  //          defaultUnit == other.defaultUnit &&
  //          densityConversion == other.densityConversion &&
  //          quantityConversion == other.quantityConversion &&
  //          quantityName == other.quantityName &&
  //          autoCalc == other.autoCalc &&
  //          amountForIngredients == other.amountForIngredients &&
  //          ingredientsUnit == other.ingredientsUnit &&
  //          amountForNutrients == other.amountForNutrients &&
  //          nutrientsUnit == other.nutrientsUnit &&
  //          const ListEquality().equals(ingredients, other.ingredients) &&
  //          const ListEquality().equals(nutrients, otherNutrients);
  // }
  
  bool equals(Product other) {
    List<bool> equalities = [
      id == other.id,
      name == other.name,
      temporaryBeginning == other.temporaryBeginning,
      temporaryEnd == other.temporaryEnd,
      isTemporary == other.isTemporary,
      defaultUnit == other.defaultUnit,
      densityConversion == other.densityConversion,
      quantityConversion == other.quantityConversion,
      quantityName == other.quantityName,
      autoCalc == other.autoCalc,
      amountForIngredients == other.amountForIngredients,
      ingredientsUnit == other.ingredientsUnit,
      amountForNutrients == other.amountForNutrients,
      nutrientsUnit == other.nutrientsUnit,
      const ListEquality().equals(ingredients, other.ingredients),
      const ListEquality().equals(nutrients, other.nutrients),
    ];
    // log if any of the equalities is false
    if (equalities.contains(false)) {
      for (int i = 0; i < equalities.length; i++) {
        if (!equalities[i]) {
          devtools.log("Equality $i of ${equalities.length} is false: ${equalities[i]}");
          if (i == 15) {
            devtools.log("nutrients: $nutrients[0]");
            devtools.log("other nutrients: ${other.nutrients[1]}");
            for (int j = 0; j < nutrients.length; j++) {
              if (nutrients[j] != other.nutrients[j]) {
                devtools.log("nutrient $j: ${nutrients[j]} != ${other.nutrients[j]}");
              }
            }
          }
          break;
        }
      }
    }
    return equalities.every((e) => e);
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

class Meal {
  int id;
  DateTime dateTime;
  ProductQuantity productQuantity;
  
  DateTime? creationDate;
  DateTime? lastEditDate;
  
  Meal({
    required this.id,
    required this.dateTime,
    required this.productQuantity,
             this.creationDate,
             this.lastEditDate,
  });
  
  Meal copyWith({
    int? newId,
    DateTime? newDateTime,
    ProductQuantity? newProductQuantity,
    DateTime? newCreationDate,
    DateTime? newLastEditDate,
  }) => Meal(
    id:               newId ?? id,
    dateTime:         newDateTime ?? dateTime,
    productQuantity:  newProductQuantity ?? productQuantity,
    creationDate:     newCreationDate ?? creationDate,
    lastEditDate:     newLastEditDate ?? lastEditDate,
  );
  
  @override
  bool operator ==(covariant Meal other) =>
    dateTime == other.dateTime &&
    productQuantity == other.productQuantity &&
    creationDate == other.creationDate;
  @override
  int get hashCode => dateTime.hashCode ^ productQuantity.hashCode;
  
  @override
  String toString() {
    return "<Meal $dateTime: $productQuantity.amount ${unitToString(productQuantity.unit)} prod id ${productQuantity.productId}>";
  }
}

enum TimeFrame {
  hour,
  day,
  week,
  month,
}

enum  Unit { // measurement units which products can be given in
	quantity, // the number of objects, e.g. "3 bananas"
	kg,
	g,
	mg,
	l,
	ml;
  
  @override
  String toString() => unitToString(this);
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
  
  copyWith({
    int? newId,
    int? newOrderId,
    String? newName,
    String? newUnit,
    bool? newShowFullName,
  }) => NutritionalValue(
    newId ?? id,
    newOrderId ?? orderId,
    newName ?? name,
    newUnit ?? unit,
    newShowFullName ?? showFullName,
  );
  
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
  bool autoCalc;
  double value;
  
  ProductNutrient({
    required this.productId,
    required this.nutritionalValueId,
    required this.autoCalc,
    required this.value,
  });
  
  ProductNutrient copy() => ProductNutrient(
    productId: productId,
    nutritionalValueId: nutritionalValueId,
    autoCalc: autoCalc,
    value: value,
  );
  
  @override
  bool operator ==(covariant ProductNutrient other) =>
      productId == other.productId
      && nutritionalValueId == other.nutritionalValueId
      && autoCalc == other.autoCalc
      && value == other.value;
  
  @override
  int get hashCode => productId.hashCode ^ nutritionalValueId.hashCode;
  
  @override
  String toString() {
    return "<ProductNutrient of prod $productId containing $value of nutr $nutritionalValueId${autoCalc ? " (autocalc)":""}>";
  }
}

class Target{
  bool isPrimary;
  Type trackedType;
  int trackedId;
  double amount;
  Unit? unit;
  int orderId;
  
  Target({
    required this.isPrimary,
    required this.trackedType,
    required this.trackedId,
    required this.amount,
    required this.unit,
    required this.orderId,
  });
  
  Target copyWith({
    bool? newIsPrimary,
    Type? newTrackedType,
    int? newTrackedId,
    double? newAmount,
    bool changeUnit = false,
    Unit? newUnit,
    int? newOrderId,
  }) => Target(
    isPrimary:   newIsPrimary   ?? isPrimary,
    trackedType: newTrackedType ?? trackedType,
    trackedId:   newTrackedId   ?? trackedId,
    amount:      newAmount      ?? amount,
    unit:        changeUnit     ?  newUnit : unit,
    orderId:     newOrderId     ?? orderId,
  );
  
  @override
  bool operator ==(covariant Target other) =>
    isPrimary == other.isPrimary &&
    trackedType == other.trackedType &&
    trackedId == other.trackedId &&
    amount == other.amount &&
    unit == other.unit;
  
  @override
  int get hashCode => isPrimary.hashCode ^ trackedType.hashCode ^ trackedId.hashCode ^ amount.hashCode ^ unit.hashCode;
  
  @override
  String toString() {
    return "<Target $amount${unit != null ? unitToString(unit!) : ""} of $trackedType #$trackedId${isPrimary ? " primary" : ""}>";
  }
}