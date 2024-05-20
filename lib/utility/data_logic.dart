import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// import 'package:archive/archive_io.dart';

import '../services/data/data_service.dart';
import '../services/data/data_exceptions.dart';
import '../services/data/data_objects.dart';

import "dart:developer" as devtools show log;

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
    return convertIngredientToProductUnit(
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
    var commonAmount = convertIngredientToProductUnit(
      commonUnit,
      ingrProd.densityConversion,
      ingrProd.quantityConversion,
      ingredient,
    );
    // convert to target unit
    return convertIngredientToProductUnit(
      targetUnit,
      conversion1,
      conversion2,
      ProductQuantity(productId: null, amount: commonAmount, unit: commonUnit),
    );
  }
}

List<Unit> getConvertibleUnits(Unit targetUnit, Conversion densityConversion, Conversion quantityConversion) {
  List<Unit> possibleUnits = [];
  if (volumetricUnits.contains(targetUnit)) {
    possibleUnits.addAll(volumetricUnits);
  } else if (weightUnits.contains(targetUnit)) {
    possibleUnits.addAll(weightUnits);
  }
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

double convertIngredientToProductUnit(
  Unit targetUnit,
  Conversion densityConversion,
  Conversion quantityConversion,
  ProductQuantity ingredient,
) => convertToUnit(
  targetUnit,
  ingredient.unit,
  ingredient.amount,
  densityConversion,
  quantityConversion,
);

double convertToUnit(
  Unit targetUnit,
  Unit unit,
  double amount,
  Conversion densityConversion,
  Conversion quantityConversion,
  {bool enableTargetQuantity = false}
) {
  if (amount == 0) return 0;
  
  var typePrev = unitTypes[unit];
  var typeTarg = unitTypes[targetUnit];
  
  if (typeTarg == UnitType.quantity) {
    if (!enableTargetQuantity) return double.nan;
    // convert using quantity conversion
    if (quantityConversion.enabled) {
      targetUnit = quantityConversion.unit2;
      typeTarg = unitTypes[targetUnit];
      amount *= quantityConversion.amount1 / quantityConversion.amount2;
    } else {
      return double.nan;
    }
  }
  
  if (typePrev == UnitType.quantity) {
    // convert using quantity conversion
    if (quantityConversion.enabled) {
      unit = quantityConversion.unit2;
      amount *= quantityConversion.amount2 / quantityConversion.amount1;
      typePrev = unitTypes[unit];
    } else {
      return double.nan;
    }
  }
  // At this point, the unit is not a quantity unit
  // If the product type is different, try to use the density conversion
  if (typePrev != typeTarg) {
    if (densityConversion.enabled) {
      if (typePrev == UnitType.volumetric) {
        // use the density conversion to convert the volumetric unit to the weight unit
        amount *= unitTypeFactors[unit]! / unitTypeFactors[densityConversion.unit1]!;
        // unit = densityConversion.unit1;
        amount *= densityConversion.amount2 / densityConversion.amount1;
        unit = densityConversion.unit2;
        typePrev = unitTypes[unit];
      } else {
        // use the density conversion in reverse
        amount *= unitTypeFactors[unit]! / unitTypeFactors[densityConversion.unit2]!;
        // unit = densityConversion.unit2;
        amount *= densityConversion.amount1 / densityConversion.amount2;
        unit = densityConversion.unit1;
        typePrev = unitTypes[unit];
      }
    } else {
      return double.nan;
    }
  }
  // At this point, the unit is the same as the product unit
  return amount * unitTypeFactors[unit]! / unitTypeFactors[targetUnit]!;
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
    unit2,
    1,
    densityConversion,
    quantityConversion,
  ).isFinite;
}

(ErrorType, String?) validateAmount(
  Unit unit,
  Unit defUnit,
  bool autoCalc,
  bool isEmpty, // Whether the list of ingredients or nutrients is empty
  double amount,
  Conversion densityConversion,
  Conversion quantityConversion,
) {
  ErrorType errorType = ErrorType.none;
  String? errorMsg;
  
  // if (unit == Unit.quantity && autoCalc) {
  //   errorMsg = "Auto calculation is not possible with quantity units";
  //   errorType = ErrorType.error;
  // } else 
  if (unit != defUnit && !conversionToUnitPossible(unit, defUnit, densityConversion, quantityConversion)) {
    errorMsg = "A conversion to the default unit (${unitToString(defUnit)}) is not possible";
    errorType = isEmpty ? ErrorType.warning : ErrorType.error;
  } else if (errorType != ErrorType.error && !isEmpty && amount == 0) {
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
      var updatedProduct = updateProductNutrients(updateProduct, alteredProductsMap);
      updatedProducts.add(updatedProduct);
      alteredProductsMap[updateProduct.id] = updatedProduct;
    }
  }
  return updatedProducts;
}

Product updateProductNutrients(Product product, Map<int, Product> productsMap) {
  // calc the resulting amount of the product
  if (product.autoCalc) {
    var ingredients = product.ingredients;
    List<(ProductQuantity, Product?)> ingredientsWithProducts = [];
    for (var ingredient in ingredients) {
      ingredientsWithProducts.add((ingredient, productsMap[ingredient.productId]));
    }
    product.amountForIngredients = calcResultingAmount(
      ingredientsWithProducts,
      product.ingredientsUnit,
      product.densityConversion,
      product.quantityConversion,
    ).$1;
  }
  
  // calc the nutrients for the product
  product.nutrients = calcNutrients(
    nutrients: product.nutrients,
    ingredients: product.ingredients,
    productsMap: productsMap,
    ingredientsUnit: product.ingredientsUnit,
    nutrientsUnit: product.nutrientsUnit,
    densityConversion: product.densityConversion,
    quantityConversion: product.quantityConversion,
    amountForIngredients: product.amountForIngredients,
    amountForNutrients: product.amountForNutrients,
  ).$1;
  
  return product;
}

(List<ProductNutrient>, List<bool>) calcNutrients({
  required List<ProductNutrient> nutrients,
  required List<ProductQuantity> ingredients,
  required Map<int, Product> productsMap,
  required Unit ingredientsUnit,
  required Unit nutrientsUnit,
  required Conversion densityConversion,
  required Conversion quantityConversion,
  required double amountForIngredients,
  required double amountForNutrients,
}) {
  // create a list of booleans that indicate which ingredients were converted successfully
  var convertedIngredients = List.filled(ingredients.length, true);
  // calc the nutrients for the product
  for (var nutrient in nutrients) {
    if (!nutrient.autoCalc) continue;
    var value = 0.0;
    // add up the nutrients of all ingredients
    for (var i = 0; i < ingredients.length; i++) {
      var ingredient = ingredients[i];
      if (!convertedIngredients[i]) continue;
      try {
        var ingrProd = productsMap[ingredient.productId]!;
        var ingrNutr = ingrProd.nutrients.firstWhere((n) => n.nutritionalValueId == nutrient.nutritionalValueId);
        // convert from ingredients nutrients unit to ingredient used
        var valuePerIngrNutrUnit = ingrNutr.value / ingrProd.amountForNutrients;
        var valueForIngrUsed = convertToUnit(ingrProd.nutrientsUnit, ingredient.unit, valuePerIngrNutrUnit, ingrProd.densityConversion, ingrProd.quantityConversion, enableTargetQuantity: true) * ingredient.amount;
        // convert between products
        var valuePerProdIngrUnit = valueForIngrUsed / amountForIngredients;
        value += valuePerProdIngrUnit;
      } catch (e) {
        devtools.log("Error while calculating nutrients: $e");
        convertedIngredients[i] = false;
      }
    }
    // convert from the ingredients amount to nutrients amount
    if (value != 0.0) value = convertToUnit(ingredientsUnit, nutrientsUnit, value, densityConversion, quantityConversion) * amountForNutrients;
    nutrient.value = value;
  }
  
  return (nutrients, convertedIngredients);
}

(double, List<double>) calcResultingAmount(
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
  var resAmount = amounts.where((amount) => !amount.isNaN).fold(0.0, (prev, amount) => prev + amount);
  return (resAmount, amounts);
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

List<NutritionalValue> sortNutValues(List<NutritionalValue> nutValues) => nutValues..sort((a, b) => a.orderId.compareTo(b.orderId));

// check whether the product nutrients match the nutritional values
List<ProductNutrient> checkNutrients(
  int productId,
  List<ProductNutrient> checkList,
  List<NutritionalValue> nutritionalValues
) {
  // var checkMap = { for (var pN in checkList) pN : false }; // true if the nutrient is correct
  var newList = <ProductNutrient>[];
  for (var nutValue in nutritionalValues) {
    var nId = nutValue.id;
    var checkNut = checkList.firstWhereOrNull((n) => n.nutritionalValueId == nId);
    if (checkNut == null) {
      // create a new nutrient
      newList.add(ProductNutrient(
        productId: productId,
        nutritionalValueId: nId,
        autoCalc: true,
        value: 0,
      ));
    } else {
      newList.add(ProductNutrient(
        productId: productId,
        nutritionalValueId: nId,
        autoCalc: checkNut.autoCalc,
        value: checkNut.value,
      ));
    }
  }
  
  return newList;
}

String? validateTemporaryInterval(DateTime? begin, DateTime? end) {
  if (begin != null && end != null && begin.isAfter(end)) {
    return "Interval must start before it ends";
  }
  return null;
}

DateTime? condParse(String? date) => date == null ? null : DateTime.parse(date);

Future<void> exportData() async {
  // export nutritional values and products separately as json
  
  // load nutritional values, products, ingredients, and product nutrients
  
  var service = DataService.current();
  
  var nutritionalValues = await service.getAllNutritionalValues();
  var products = await service.getAllProducts();
  
  // convert nutritional values to json
  Map<String, dynamic> nutValuesJson = {};
  for (var nutValue in nutritionalValues) {
    nutValuesJson[nutValue.id.toString()] = {
      "id":           nutValue.id,
      "order_id":     nutValue.orderId,
      "name":         nutValue.name,
      "unit":         nutValue.unit,
      "showFullName": nutValue.showFullName,
    };
  }
  
  // convert products to json
  Map<String, dynamic> productsJson = {};
  for (var product in products) {
    productsJson[product.id.toString()] = {
      "id":                     product.id,
      "name":                   product.name,
      "auto_calc":              product.autoCalc,
      "ingredients_unit":       product.ingredientsUnit.toString(),
      "nutrients_unit":         product.nutrientsUnit.toString(),
      "amount_for_ingredients": product.amountForIngredients,
      "amount_for_nutrients":   product.amountForNutrients,
      "density_conversion":     product.densityConversion.toString(),
      "quantity_conversion":    product.quantityConversion.toString(),
      "ingredients": product.ingredients.map((ingr) => {
        "product_id": ingr.productId,
        "amount":     ingr.amount,
        "unit":       ingr.unit.toString(),
      }).toList(),
      "nutrients": product.nutrients.map((nut) => {
        "nutritional_value_id": nut.nutritionalValueId,
        "auto_calc":            nut.autoCalc,
        "value":                nut.value,
      }).toList(),
    };
  }
  
  // convert to products.json and nutritional_values.json
  const encoder = JsonEncoder.withIndent("  ");
  
  var pJsonUtf8 = utf8.encode(encoder.convert(productsJson));
  var nvJsonUtf8 = utf8.encode(encoder.convert(nutValuesJson));
  
  var date = DateTime.now().toString().split(" ")[0]; // format: YYYY-MM-DD
  var nameP = "products_$date.json";
  var nameNv = "nutritional_values_$date.json";
  
  var pathP = await storeFileTemporarily(pJsonUtf8, nameP);
  var pathNv = await storeFileTemporarily(nvJsonUtf8, nameNv);
  
  // share both files separately
  await Share.shareXFiles(
    [
      XFile(pathP),
      XFile(pathNv),
    ],
  );
  
  // delete
  await File(pathP).delete();
  await File(pathNv).delete();
}

Future<String> storeFileTemporarily(Uint8List image, String name) async {
  final tempDir = await getTemporaryDirectory();
  
  final path = '${tempDir.path}/$name';
  final file = await File(path).create();
  file.writeAsBytesSync(image);

  return path;
}