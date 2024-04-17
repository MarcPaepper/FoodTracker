

import '../services/data/data_exceptions.dart';
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
  if (targetUnit != Unit.quantity) possibleUnits.add(targetUnit);
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

double calcResultingAmount(
  List<(ProductQuantity, Product?)> ingredientsWithProducts,
  Unit productUnit,
  Conversion densityConversion,
  Conversion quantityConversion,
) {
  List<double>? amounts = ingredientsWithProducts.map((pair) => convertBetweenProducts(
    targetUnit: productUnit,
    conversion1: densityConversion,
    conversion2: quantityConversion,
    ingredient: pair.$1,
    ingrProd: pair.$2,
  )).toList();
  // sum up all non-NaN amounts to get the resulting amount
  return amounts.where((amount) => !amount.isNaN).fold(0.0, (prev, amount) => prev + amount);
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


  
  // recalculate the nutrients for the product and all products that contain it
  List<Product> recalcProductNutrients(Product product, List<Product> products, Map<int, Product> productsMap) {
    Map<int, Product> alteredProductsMap = Map.from(productsMap);
    // create a tree of products that contain the product
    var safetyCounter = 0;
    var lastLevel = [product];
    List<List<Product>> dependenceLevels = [lastLevel]; // first level is the product itself, second level are the products that contain the product, etc.
    do {
      // find all products that contain one of the products in the last level
      var nextLevel = <Product>[];
      for (var product in lastLevel) {
        var containingProducts = products.where((p) => p.ingredients.any((i) => i.productId == product.id));
        // if there are products in containingProduct which are also in previous levels, remove them from the previous levels
        for (var level in dependenceLevels) {
          level.removeWhere((p) => containingProducts.contains(p));
        }
        nextLevel.addAll(containingProducts);
      }
      if (nextLevel.isNotEmpty) dependenceLevels.add(nextLevel);
      lastLevel = nextLevel;
      safetyCounter++;
    } while (lastLevel.isNotEmpty && safetyCounter < 128);
    if (safetyCounter >= 128) throw InfiniteLoopException();
    
    var updatedProducts = <Product>[];
    for (var level in dependenceLevels) {
      for (var updateProduct in level) {
        var updatedProduct = calcProductNutrients(updateProduct, alteredProductsMap);
        if (updatedProduct.id != updateProduct.id) {
          updatedProducts.add(updatedProduct);
        }
        alteredProductsMap[updateProduct.id] = updatedProduct;
      }
    }
    return updatedProducts;
  }
  
  Product calcProductNutrients(Product product, Map<int, Product> productsMap) {
    List<ProductQuantity>? ingredients;
    // calc the resulting amount of the product
    if (product.autoCalc) {
      ingredients ??= product.ingredients;
      List<(ProductQuantity, Product?)> ingredientsWithProducts = [];
      for (var ingredient in ingredients) {
        ingredientsWithProducts.add((ingredient, productsMap[ingredient.productId]));
      }
      product.amountForIngredients = calcResultingAmount(
        ingredientsWithProducts,
        product.ingredientsUnit,
        product.densityConversion,
        product.quantityConversion,
      );
    }
    // calc the nutrients for the product
    for (var nutrient in product.nutrients) {
      if (!nutrient.autoCalc) continue;
      var value = 0.0;
      ingredients ??= product.ingredients;
      // add up the nutrients of all ingredients
      for (var ingredient in ingredients) {
        var ingrProd = productsMap[ingredient.productId]!;
        var ingrNutr = ingrProd.nutrients.firstWhere((n) => n.nutritionalValueId == nutrient.nutritionalValueId);
        value +=
            ingrNutr.value
          * ingredient.amount
          * convertToUnit(ingredient.unit, ingrProd.densityConversion, ingrProd.quantityConversion, ingredient);
      }
      // convert from the ingredients amount to nutrients amount
      value = convertBetweenProducts(
        targetUnit: product.nutrientsUnit,
        conversion1: product.densityConversion,
        conversion2: product.quantityConversion,
        ingredient: ProductQuantity(productId: product.id, amount: value, unit: product.ingredientsUnit),
        ingrProd: product,
      ) / product.amountForIngredients * product.amountForNutrients;
      nutrient.value = value;
    }
    
    return product;
  }
  
  // remove the product itself and all ingredient products from the map
  Map<int, Product> reduceProducts(Map<int, Product> productsMap, List<ProductQuantity> ingredients, int? id) {
    var reducedProducts = Map<int, Product>.from(productsMap);
    for (var ingredient in ingredients) {
      if (ingredient.productId != null) {
        reducedProducts.remove(ingredient.productId);
      }
    }
    // remove product itself
    if (id != null && id >= 0) reducedProducts.remove(id);
    return reducedProducts;
  }