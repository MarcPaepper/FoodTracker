

import '../services/data/data_objects.dart';

enum ErrorType {
  none,
  warning,
  error,
}

String? validateIngredient({
  required Map<int, Product> products,
  required Product? product,
  required Product? ingrProd,
}) {
  if (product == null || ingrProd == null) return null;
  return getIngredientsRecursively(products, product, ingrProd, [ingrProd]) == null
    ? "Circular reference"
    : null;
}

List<Product>? getIngredientsRecursively(Map<int, Product> products, Product checkProd, Product product, List<Product> alreadyVisited) {
  var ingredientIdsWithNulls = product.ingredients.map((ingr) => ingr.productId).toList();
  // remove nulls
  var ingredientIds = ingredientIdsWithNulls.whereType<int>().toList();
  var ingredients = ingredientIds.map((id) => products[id]!).toList();
  if (ingredients.contains(checkProd)) return null;
  // recursion
  for (var ingr in ingredients) {
    if (!alreadyVisited.contains(ingr)) {
      alreadyVisited.add(ingr);
      var recursivelyVisited = getIngredientsRecursively(products, checkProd, ingr, alreadyVisited);
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
  required Product? ingrProd,
}) {
  if (targetUnit == null || ingrProd == null) return double.nan;
  
  var possibleUnitsTarget = getConvertibleUnits(targetUnit, conversion1, conversion2);
  var possibleUnitsIngred = getConvertibleUnits(ingredient.unit, ingrProd.densityConversion, ingrProd.quantityConversion);
  
  // convert ingredient to a common unit
  if (possibleUnitsIngred.contains(targetUnit)) {
    // direct conversion
    return convertToUnit(
      targetUnit,
      ingrProd.densityConversion,
      ingrProd.quantityConversion,
      ingredient,
    );
  } else {
    // find common unit
    var commonUnits = possibleUnitsTarget.toSet().intersection(possibleUnitsIngred.toSet()).toList();
    if (commonUnits.isEmpty) return double.nan;
    var commonUnit = commonUnits.first;
    // convert ingredient to common unit
    var commonAmount = convertToUnit(
      commonUnit,
      ingrProd.densityConversion,
      ingrProd.quantityConversion,
      ingredient,
    );
    // convert to target unit
    return convertToUnit(
      targetUnit,
      conversion1,
      conversion2,
      ProductQuantity(productId: null, amount: commonAmount, unit: commonUnit),
    );
  }
}

List<Unit> getConvertibleUnits(Unit targetUnit, Conversion densityConversion, Conversion quantityConversion) {
  List<Unit> possibleUnits = [];
  if (densityConversion.enabled) {
    possibleUnits.addAll(volumetricUnits);
    possibleUnits.addAll(weightUnits);
  }
  if (quantityConversion.enabled) {
    if (volumetricUnits.contains(quantityConversion.unit2)) {
      possibleUnits.addAll(volumetricUnits);
    } else {
      possibleUnits.addAll(weightUnits);
    }
  }
  // remove duplicates
  return possibleUnits;
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
      ingredient = ProductQuantity(productId: ingredient.productId, amount: newAmount, unit: newUnit);
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
        ingredient = ProductQuantity(productId: ingredient.productId, amount: newAmount, unit: newUnit);
        typeIngr = unitTypes[newUnit];
      } else {
        // use the density conversion in reverse
        var newUnit = densityConversion.unit1;
        var newAmount = ingredient.amount * densityConversion.amount1 / densityConversion.amount2;
        ingredient = ProductQuantity(productId: ingredient.productId, amount: newAmount, unit: newUnit);
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
    ProductQuantity(productId: null, amount: 1, unit: unit2),
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