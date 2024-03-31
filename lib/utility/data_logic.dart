

import '../services/data/data_objects.dart';

enum ErrorType {
  none,
  warning,
  error,
}

String? validateIngredient({
  required Product productToCheck,
  required Product ingredient,
}) => getIngredientsRecursively(productToCheck, ingredient, [ingredient]) == null
    ? null
    : "Circular reference";

List<Product>? getIngredientsRecursively(Product checkProd, Product product, List<Product> alreadyVisited) {
  var ingredientsWithNulls = product.ingredients.map((ingr) => ingr.product).toList();
  // remove nulls
  var ingredients = ingredientsWithNulls.where((element) => element != null).toList() as List<Product>;
  if (ingredients.contains(checkProd)) return null;
  // recursion
  for (var ingr in ingredients) {
    if (!alreadyVisited.contains(ingr)) {
      alreadyVisited.add(ingr);
      var recursivelyVisited = getIngredientsRecursively(checkProd, ingr, alreadyVisited);
      if (recursivelyVisited == null) return null;
      alreadyVisited.addAll(recursivelyVisited);
    }
  }
  
  alreadyVisited.addAll(ingredients);
  // remove duplicates
  alreadyVisited = alreadyVisited.toSet().toList();
  return alreadyVisited;
}

double convertBetweenProducts({
  Unit? targetUnit,
  required Conversion conversion1,
  required Conversion conversion2,
  required ProductQuantity ingredient,
  required List<Product> products,
}) {
  if (targetUnit == null) return double.nan;
  
  var possibleUnits = [targetUnit];
  if (conversion1.enabled) {
    possibleUnits.add(conversion1.unit1);
    possibleUnits.add(conversion1.unit2);
  }
  if (conversion2.enabled) {
    possibleUnits.add(conversion2.unit1);
    possibleUnits.add(conversion2.unit2);
  }
  // remove duplicates
  possibleUnits = possibleUnits.toSet().toList();
  
  for (var unit in possibleUnits) {
    var conv = convertToUnit(
      unit,
      conversion1,
      conversion2,
      ingredient,
    );
    if (!conv.isNaN) return conv;
  }
  return double.nan;
}

double convertToUnit(
  Unit productUnit,
  Conversion densityConversion,
  Conversion quantityConversion,
  ProductQuantity ingredient,
) {
  var typeIngr = unitTypes[ingredient.unit];
  var typeProd = unitTypes[productUnit];
  
  if (typeProd == UnitType.quantity) return double.nan;
  
  if (typeIngr == UnitType.quantity) {
    // convert using quantity conversion
    if (quantityConversion.enabled) {
      var newUnit = quantityConversion.unit2;
      var newAmount = ingredient.amount * quantityConversion.amount2 / quantityConversion.amount1;
      ingredient = ProductQuantity(product: ingredient.product, amount: newAmount, unit: newUnit);
      typeIngr = unitTypes[newUnit];
    } else {
      return double.nan;
    }
  }
  // At this point, the ingredient unit is not a quantity unit
  // If the product type is different, try to use the density conversion
  if (typeIngr != typeProd) {
    if (densityConversion.enabled) {
      if (typeIngr == UnitType.volumetric) {
        // use the density conversion to convert the volumetric unit to the weight unit
        var newUnit = densityConversion.unit2;
        var newAmount = ingredient.amount * densityConversion.amount2 / densityConversion.amount1;
        ingredient = ProductQuantity(product: ingredient.product, amount: newAmount, unit: newUnit);
        typeIngr = unitTypes[newUnit];
      } else {
        // use the density conversion in reverse
        var newUnit = densityConversion.unit1;
        var newAmount = ingredient.amount * densityConversion.amount1 / densityConversion.amount2;
        ingredient = ProductQuantity(product: ingredient.product, amount: newAmount, unit: newUnit);
        typeIngr = unitTypes[newUnit];
      }
    } else {
      return double.nan;
    }
  }
  // At this point, the ingredient unit is the same as the product unit
  return ingredient.amount * unitTypeFactors[ingredient.unit]! / unitTypeFactors[productUnit]!;
}

bool conversionToUnitPossible(
  Unit unit1,
  Unit unit2,
  Conversion densityConversion,
  Conversion quantityConversion,
) {
  // If unit1 is of type quantity, swap the units
  if (unitTypes[unit1] == UnitType.quantity) {
    var temp = unit1;
    unit1 = unit2;
    unit2 = temp;
  }
  
  return convertToUnit(
    unit1,
    densityConversion,
    quantityConversion,
    ProductQuantity(product: null, amount: 1, unit: unit2),
  ).isFinite;
}

(ErrorType, String?) validateResultingAmount(
  Unit unit,
  Unit defUnit,
  bool autoCalc,
  List<ProductQuantity> ingredients,
  double resultingAmount,
  Conversion densityConversion,
  Conversion quantityConversion,
) {
  ErrorType errorType = ErrorType.none;
  String? errorMsg;
  
  if (unit == Unit.quantity && autoCalc) {
    errorMsg = "Auto calculation is not possible with quantity units";
    errorType = ErrorType.error;
  } else if (!conversionToUnitPossible(unit, defUnit, densityConversion, quantityConversion)) {
    errorMsg = "A conversion to the default unit (${unitToString(defUnit)}) is not possible";
    errorType = ingredients.isEmpty ? ErrorType.warning : ErrorType.error;
  } else if (errorType != ErrorType.error && ingredients.isNotEmpty && resultingAmount == 0) {
    errorMsg = "Amount must be greater than 0";
    errorType = ErrorType.error;
  }
  
  return (errorType, errorMsg);
}