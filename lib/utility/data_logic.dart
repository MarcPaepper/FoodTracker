// ignore_for_file: non_constant_identifier_names, dead_code, curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:food_tracker/utility/modals.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:archive/archive_io.dart';

import '../services/data/data_service.dart';
import '../services/data/data_exceptions.dart';
import '../services/data/data_objects.dart';

import "dart:developer" as devtools;

import '../services/data/object_mapping.dart';

enum ErrorType {
  none,
  warning,
  error,
}

List<String> validateIngredient({
  required Map<int, Product> products,
  required Product? product,
  required Product? ingrProd,
}) {
  List<String> errors = [];
  if (product == null || ingrProd == null)
    return ["Product not found"];
  if (getIngredientsRecursively(products, product, ingrProd, [ingrProd]) == null)
    errors.add("Circular reference");
  
  return errors;
}

List<Product>? getIngredientsRecursively(Map<int, Product> products, Product checkProd, Product product, List<Product> alreadyVisited) {
  var ingredientIdsWithNulls = product.ingredients.map((ingr) => ingr.productId).toList();
  // remove nulls
  var ingredientIds = ingredientIdsWithNulls.whereType<int>().toList();
  var ingredientsWithNulls = ingredientIds.map((id) => products[id]).toList();
  var ingredients = ingredientsWithNulls.whereType<Product>().toList();
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
  } else {
    possibleUnits.add(targetUnit);
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

// How many target units are for the given amount and unit
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
    if (typePrev == UnitType.quantity) return amount;
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
// returns a list of all updated products
List<Product> recalcProductNutrients(Product product, List<Product> products, Map<int, Product> productsMap) {
  Map<int, Product> alteredProductsMap = Map.from(productsMap);
  // create a tree of products that contain the product
  var safetyCounter = 0;
  var lastLevel = [product];
  List<List<Product>> dependenceLevels = [lastLevel]; // first level is the product itself, second level are the products that contain the product, etc.
  do {
    // find all products that contain one of the products in the last level
    var nextLevel = <Product>[];
    try {
      for (var product in lastLevel) {
        var containingProducts = products.where((p) => p.ingredients.any((i) => i.productId == product.id)).toList();
        // if there are products in containingProduct which are also in previous levels, remove them from the previous levels
        for (var level in dependenceLevels) {
          level.removeWhere((p) => containingProducts.contains(p));
        }
        nextLevel.addAll(containingProducts);
      }
    } catch (e) {
      devtools.log("Error while calculating dependence levels: $e");
    }
    if (nextLevel.isNotEmpty) dependenceLevels.add(List.from(nextLevel));
    lastLevel = List.from(nextLevel);
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

// recalculate the nutrients and amount for the product
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
        var ingrProd = productsMap[ingredient.productId];
        if (ingrProd == null) {
          convertedIngredients[i] = false;
          continue;
        }
        var ingrNutr = ingrProd.nutrients.firstWhere((n) => n.nutritionalValueId == nutrient.nutritionalValueId);
        // convert from ingredients nutrients unit to ingredient used
        var valuePerIngrNutrUnit = ingrNutr.value / ingrProd.amountForNutrients;
        var valueForIngrUsed = convertToUnit(ingrProd.nutrientsUnit, ingredient.unit, valuePerIngrNutrUnit, ingrProd.densityConversion, ingrProd.quantityConversion, enableTargetQuantity: true) * ingredient.amount;
        // convert between products
        var valuePerProdIngrUnit = valueForIngrUsed / amountForIngredients;
        value += valuePerProdIngrUnit;
      } catch (e) {
        devtools.log("Error while calculating nutrient ${nutrient.nutritionalValueId}: $e");
        convertedIngredients[i] = false;
      }
    }
    // convert from the ingredients amount to nutrients amount
    if (value != 0.0) value = convertToUnit(ingredientsUnit, nutrientsUnit, value, densityConversion, quantityConversion, enableTargetQuantity: true) * amountForNutrients;
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

List<Target> sortTargets(List<Target> targets) => targets..sort((a, b) => a.orderId.compareTo(b.orderId));

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
  // load
  
  var service = DataService.current();
  
  var nutritionalValues = await service.getAllNutritionalValues();
  var products = await service.getAllProducts();
  var meals = await service.getAllMeals();
  var targets = await service.getAllTargets();
  
  // convert to json
  
  Map<String, dynamic> nutValuesJson = {}, productsJson = {}, mealsJson = {};
  List<Map<String, dynamic>> targetsJson = [];
  
  for (var nutValue in nutritionalValues) {
    nutValuesJson[nutValue.id.toString()] = nutValueToMap(nutValue);
  }
  
  for (var product in products) {
    productsJson[product.id.toString()] = productToMap(product);
  }
  
  for (var meal in meals) {
    mealsJson[meal.id.toString()] = mealToMap(meal);
  }
  
  for (var target in targets) {
    targetsJson.add(targetToMap(target));
  }
  
  // convert to products.json and nutritional_values.json
  const encoder = JsonEncoder.withIndent("  ");
  
  var pJsonUtf8  = utf8.encode(encoder.convert(productsJson));
  var nvJsonUtf8 = utf8.encode(encoder.convert(nutValuesJson));
  var mJsonUtf8  = utf8.encode(encoder.convert(mealsJson));
  var tJsonUtf8  = utf8.encode(encoder.convert(targetsJson));
  
  var date = DateTime.now().toString().split(" ")[0]; // format: YYYY-MM-DD
  var nameP = "products_$date.json";
  var nameNv = "nutritional_values_$date.json";
  var nameM = "meals_$date.json";
  var nameT = "targets_$date.json";
  
  // create a zip file
  var archive = Archive()
    ..addFile(ArchiveFile(nameP, pJsonUtf8.length, pJsonUtf8))
    ..addFile(ArchiveFile(nameNv, nvJsonUtf8.length, nvJsonUtf8))
    ..addFile(ArchiveFile(nameM, mJsonUtf8.length, mJsonUtf8))
    ..addFile(ArchiveFile(nameT, tJsonUtf8.length, tJsonUtf8));
  
  var zip = ZipEncoder().encode(archive);
  if (kIsWeb) {
    
    if (zip != null) {
      // use the download function
      final url = "data:application/zip;base64,${base64Encode(zip)}";
      await launchUrl(Uri.parse(url), webOnlyWindowName: "export.zip");
    }
  } else {
    // convert to Uint8List
    Uint8List zipUint8 = Uint8List.fromList(zip!);
    
    var pathZip = await storeFileTemporarily(zipUint8, "foodtracker_$date.zip");
    
    await Share.shareXFiles(
      [
        XFile(pathZip),
      ],
    );
    
    // delete
    await File(pathZip).delete();
  }
}

Future<void> importData(BuildContext context) async {
  // show file picker
  var fileList = await FilePicker.platform.pickFiles(
    withData: true,
    type: FileType.custom,
    allowedExtensions: ["zip"],
  );
  
  if (fileList == null || fileList.files.isEmpty) {
    if (context.mounted) showSnackbar(context, "No files selected");
    return;
  }
  if (fileList.files.none((file) => file.extension == "zip")) {
    // throw error
    if (context.mounted) showSnackbar(context, "Please select a zip archive");
    return;
  }
  
  if ( fileList.files.length > 1) {
    if (context.mounted) showSnackbar(context, "Please select only one archive");
    return;
  }
  // extract
  var zip = fileList.files.first;
  var bytes = zip.bytes;
  if (bytes == null) {
    if (context.mounted) showSnackbar(context, "Error while reading the file");
    return;
  }
  var archive = ZipDecoder().decodeBytes(bytes);
  var files = archive.files;
  
  // load the files
  var productsJson = <String, dynamic>{};
  var nutritionalValuesJson = <String, dynamic>{};
  var mealsJson = <String, dynamic>{};
  var targetsJson = List<Map<String, dynamic>>.empty(growable: true);
  for (var file in files) {
    String name = file.name;
    dynamic data = file.content;
    
    if (data == null) {
      if (context.mounted) showSnackbar(context, "Error while reading the file");
      return;
    }
    var json = jsonDecode(utf8.decode(data));
    
    if (name.startsWith("products")) {
      productsJson = json as Map<String, dynamic>;
    } else if (name.startsWith("nutritional_values")) {
      nutritionalValuesJson = json;
    } else if (name.startsWith("meals")) {
      mealsJson = json;
    } else if (name.startsWith("targets") && (json as List).isNotEmpty) {
      // json is of type List<dynamic> and must be converted to Iterable<Map<String, dynamic>>
      for (var entry in json) {
        targetsJson.add(Map<String, dynamic>.from(entry as Map));
      }
    }
  }
  if (context.mounted) {
    // ask the user if they want to proceed
    var result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Proceed?"),
        content: const Text("All your current data will be deleted and replaced."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No"),
          ),
        ],
      ),
    );
    if (result != true) return;
    
    // import the data
    var service = DataService.current();
    
    try {
      devtools.log("Data cleaning");
      await service.cleanUp();
      devtools.log("Data cleaned up");
      devtools.log("Data reset");
      await service.reset("test");
      devtools.log("Data resetted");
      
      // map old ids to new ids
      var nutValIds = <int, int>{};
      
      // import nutritional values
      var nutritionalValues = nutritionalValuesJson.values.map((value) => mapToNutritionalValue(value)).toList();
      nutritionalValues.sort((a, b) => a.orderId.compareTo(b.orderId));
      for (var nutValue in nutritionalValues) {
        try {
          var n = await service.createNutritionalValue(nutValue);
          nutValIds[nutValue.id] = n.id;
        } catch (e) {
          // nothing
        }
      }
      
      // map old ids to new ids
      var productIds = <int, int>{};
      // save the ingredients, so they can be added later with the updated product ids
      // maps the old parent product id to the ingredients (with old ingredient product ids)
      var ingredientsMap = <int, List<ProductQuantity>>{};
      
      // import products
      devtools.log("Importing products");
      var importProducts = productsJson.values.map((value) {
        value = Map<String, dynamic>.from(value);
        // give the nutrients a dummy id which is changed later
        value["nutrients"] = (value["nutrients"] as List).map((nut) {
          nut["product_id"] = -1;
          return nut;
        }).toList();
        
        return mapToProduct(value);
      }).toList();
      for (var importProduct in importProducts) {
        Product product = importProduct;
        // change the nutritional value ids
        product.nutrients = product.nutrients.map((nut) {
          var newId = nutValIds[nut.nutritionalValueId];
          if (newId == null) throw Exception("Nutritional value id not found");
          return ProductNutrient(
            nutritionalValueId: newId,
            productId: product.id,
            autoCalc: nut.autoCalc,
            value: nut.value,
          );
        }).toList();
        // save the ingredients
        ingredientsMap[product.id] = product.ingredients;
        product.ingredients = [];
      }
      List<int> oldIds = importProducts.map((p) => p.id).toList();
      var newProducts = await service.createProducts(importProducts);
      for (var i = 0; i < importProducts.length; i++) {
        productIds[oldIds[i]] = newProducts[i].id;
      }
      
      // add the ingredients
      devtools.log("Adding ingredients");
      List<Product> updatedProducts = [];
      for (var entry in ingredientsMap.entries) {
        var newParentId = productIds[entry.key];
        if (newParentId == null) throw Exception("Parent id not found");
        var ingredientsOld = entry.value;
        // change all product ids
        var ingredientsNew = ingredientsOld.map((ingr) {
          var newIngredientProductId = productIds[ingr.productId];
          if (newIngredientProductId == null) throw Exception("Ingredient Product id not found");
          return ProductQuantity(
            productId: newIngredientProductId,
            amount: ingr.amount,
            unit: ingr.unit,
          );
        }).toList();
        var product = updatedProducts.firstWhereOrNull((p) => p.id == newParentId);
        product ??= importProducts.firstWhere((p) => p.id == newParentId);
        product.ingredients = ingredientsNew;
        updatedProducts.add(product);
      }
      await service.updateProducts(updatedProducts);
      
      // import meals
      devtools.log("Importing meals");
      var meals = mealsJson.values.map((value) => mapToMeal(value)).toList();
      for (var meal in meals) {
        // change the product id
        var newId = productIds[meal.productQuantity.productId];
        if (newId == null) throw Exception("Product id not found");
        meal.productQuantity = ProductQuantity(
          productId: newId,
          amount: meal.productQuantity.amount,
          unit: meal.productQuantity.unit,
        );
      }
      await service.createMeals(meals);
      
      // import targets
      devtools.log("Importing targets");
      var targets = targetsJson.map((value) => mapToTarget(value)).toList();
      targets.sort((a, b) => a.orderId.compareTo(b.orderId));
      for (var target in targets) {
        // change the tracked id
        if (target.trackedType == Product) {
          var newId = productIds[target.trackedId];
          if (newId == null) throw Exception("Product id not found");
          target.trackedId = newId;
        } else if (target.trackedType == NutritionalValue) {
          var newId = nutValIds[target.trackedId];
          if (newId == null) throw Exception("Nutritional value id not found");
          target.trackedId = newId;
        }
        await service.createTarget(target);
      }
      
      if(context.mounted) showSnackbar(context, "Data imported successfully");
    } catch (e) {
     // log
     devtools.log("Error while importing the data: $e");
     if(context.mounted) showSnackbar(context, "Error while importing the data: $e");
    }
  }
}

Future<String> storeFileTemporarily(Uint8List image, String name) async {
  WidgetsFlutterBinding.ensureInitialized();
  final tempDir = await getTemporaryDirectory();
  
  final path = '${tempDir.path}/$name';
  final file = await File(path).create();
  file.writeAsBytesSync(image);

  return path;
}

// get a reorder map when an item was moved
Map<dynamic, int>? getReorderMap(List<(dynamic, int)> IdsAndOrderIds, int oldIndex, int newIndex) {
  if (newIndex > oldIndex) {
    newIndex -= 1;
  }
  if (oldIndex == newIndex) return null;
  
  var reorderMap = <dynamic, int>{};
  reorderMap[IdsAndOrderIds[oldIndex].$1] = IdsAndOrderIds[newIndex].$2;
  
  if (newIndex > oldIndex) {
    // reduce all other order ids by 1
    for (var i = oldIndex + 1; i <= newIndex; i++) {
      reorderMap[IdsAndOrderIds[i].$1] = IdsAndOrderIds[i].$2 - 1;
    }
  } else {
    // increase all other order ids by 1
    for (var i = newIndex; i < oldIndex; i++) {
      reorderMap[IdsAndOrderIds[i].$1] = IdsAndOrderIds[i].$2 + 1;
    }
  }
  
  return reorderMap;
}

// index according to the meal datetime
int findInsertIndex(List<Meal> meals, Meal newMeal) {
  // find the index where the new meal should be inserted
  // the index should be the one after the last meal that has the same or an earlier datetime
  int min = 0;
  int max = meals.length - 1;
  while (min <= max) {
    var mid = min + ((max - min) ~/ 2);
    var midMeal = meals[mid];
    if (midMeal.dateTime.isAfter(newMeal.dateTime)) {
      max = mid - 1;
    } else {
      min = mid + 1;
    }
  }
  return min;
}

// calculate how relevant a product currently is to the user
(double, ProductQuantity?) calcProductRelevancy(List<Meal> meals, Product product, DateTime compDT) {
  var now = DateTime.now();
  // filter for the meals that contain the product
  meals = meals.where((m) => m.productQuantity.productId == product.id).toList();
  
  // make the meals more relevant if they have more recent meals
  compDT = DateTime(compDT.year, compDT.month, compDT.day, compDT.hour, compDT.minute);
  var mealTimeDeltas = meals.map((m) => max(0, compDT.difference(m.dateTime).inHours / 24)).toList();
  var mealRelevancy = 1 + mealTimeDeltas.fold(0.0, (prev, delta) => prev + 1 / (delta + 1));
  
  // make the product more relevant if it was created or edited more recently
  double productRelevancy;
  var creationDelta = product.creationDate != null ? now.difference(product.creationDate!).inMinutes / 60 : 0;
  if (creationDelta < 0) creationDelta = 0;
  productRelevancy = max(7 * pow(1/7, creationDelta / 48) as double, 1);
  
  var editDelta = product.lastEditDate != null ? now.difference(product.lastEditDate!).inMinutes / 60 : 0;
  if (editDelta < 0) editDelta = 0;
  productRelevancy = max(4 * pow(1/4, editDelta / 24) as double, productRelevancy);
  
  // triple the relevancy if the product is temporary and compDT is inside the temporary interval
  var temporaryRelevancy = 1.0;
  if (product.isTemporary) {
    if (product.temporaryBeginning != null && product.temporaryEnd != null) {
      if (isDateInsideInterval(compDT, product.temporaryBeginning!, product.temporaryEnd!) == 0) {
        temporaryRelevancy = 2;
      } else {
        temporaryRelevancy = 0.25;
      }
    }
  }
  
  bool debugLog = false;
  
  if (debugLog) {
    // var total = mealRelevancy * productRelevancy * temporaryRelevancy;
    
    String name = product.name;
    name = name.padRight(30).substring(0, 30);
    
    String mealRelevancyStr = mealRelevancy.toStringAsFixed(3);
    String productRelevancyStr = productRelevancy.toStringAsFixed(3);
    String temporaryRelevancyStr = temporaryRelevancy.toStringAsFixed(3);
    // String totalStr = total.toStringAsFixed(3);
    
    devtools.log("::: $name : $mealRelevancyStr : $productRelevancyStr : $temporaryRelevancyStr");
  }
  
  double relevancy = mealRelevancy * productRelevancy * temporaryRelevancy;
  
  // A product has a common amount if it is used at least 65% of meals and has been used at least 5 times
  List<ProductQuantity> productQuantities = meals.map((m) => m.productQuantity).toList();
  Map<ProductQuantity, int> productQuantitiesMap = {};
  for (var pq in productQuantities) {
    if (productQuantitiesMap.containsKey(pq)) {
      productQuantitiesMap[pq] = productQuantitiesMap[pq]! + 1;
    } else {
      productQuantitiesMap[pq] = 1;
    }
  }
  // find most common among them
  MapEntry<ProductQuantity, int>? commonQuantity;
  if (productQuantitiesMap.isNotEmpty) commonQuantity = productQuantitiesMap.entries.reduce((a, b) => a.value > b.value ? a : b); // Fix: StateError (Bad state: No element)
  
  if (commonQuantity != null) {
    Unit unit = commonQuantity.key.unit;
    Unit defUnit = product.defaultUnit;
    double defAmount = defaultUnitAmounts[unit]!;
    if (
      commonQuantity.key.unit != defUnit ||
      commonQuantity.value < 5 ||
      commonQuantity.value / meals.length < 0.65 ||
      commonQuantity.key.amount == defAmount
    ) {
      commonQuantity = null;
    }
  }
  
  return (relevancy, commonQuantity?.key);
}

// daily target progress
// Returns a map of all targets and how much of the target was fulfilled by every product
// If more than 7 products contributed to a target, the additional ones are combined into the null product
// Products in the oldMeals list are also combined into the null product
(Map<Target, Map<Product?, double>>, List<Product>) getDailyTargetProgress(
  DateTime? dT,
  List<Target> targets,
  Map<int, Product> productsMap,
  List<NutritionalValue> nutritionalValues,
  List<Meal> meals,
  List<Meal>? oldMeals,
  bool sortByRelevancy,
  {
    int maxProducts = 7,
  }
) {
  if (targets.isEmpty) return ({}, []);
  
  Map<Target, Map<Product?, double>> targetProgress = {}; // contains each target and how many units of the target were fulfilled by each product
  List<Product> contributingProducts = []; // contains all products that contributed to any target at all
  
  // filter oldMeals for the current date
  if (oldMeals != null) {
    if (dT != null) {
      oldMeals = oldMeals.where((m) => m.dateTime.year == dT.year && m.dateTime.month == dT.month && m.dateTime.day == dT.day).toList();
    } else {
      oldMeals = [];
    }
  }
  
  // sort the products by their first appearance in the meals
  Map<Product, int> mealSorting = {};
  for (int i = 0; i < meals.length; i++) {
    int? id = meals[i].productQuantity.productId;
    if (id != null && productsMap.containsKey(id) && !mealSorting.containsKey(productsMap[id])) {
      mealSorting[productsMap[id]!] = i;
    }
  }
  
  // calculate the progress for each target
  targetLoop:
  for (var t in targets) {
    var isProduct = t.trackedType == Product;
    dynamic trackedObject = isProduct ? productsMap[t.trackedId] : nutritionalValues.firstWhereOrNull((nv) => nv.id == t.trackedId);
    if (trackedObject == null) {
      devtools.log("Error: Tracked ${isProduct ? "product" : "nutritional value"} #${t.trackedId} not found");
      continue;
    }
    Map<Product?, double> progress = {null: 0.0};
    
    // calculate the progress for each product
    for (int i = 0; i < meals.length + (oldMeals?.length ?? 0); i++) {
      var old = i >= meals.length;
      var meal = old ? oldMeals![i - meals.length] : meals[i];
      var pQ = meal.productQuantity;
      var p = productsMap[pQ.productId];
      
      if (p == null) continue;
      
      double amount = 0.0;
      if (isProduct) {
        // check how much of the target product is in the meal
        // this also includes cases if it is as an ingredient
        // A recursive search is used to find out if any ingredient downstream is the targetProduct
        var targetProduct = trackedObject as Product;
        var targetUnit = t.unit!;
        if (p.id == -1) continue;
        var safetyCounter = 0;
        amount = calcProductTargetRecursively(productsMap, targetUnit, pQ, targetProduct, safetyCounter);
      } else {
        // check how much of the target nutritional value is in the meal
        var nutVal = trackedObject as NutritionalValue;
        // convert from the productQuantity unit to the unit used for the nutritional values
        amount = convertToUnit(p.nutrientsUnit, pQ.unit, pQ.amount, p.densityConversion, p.quantityConversion, enableTargetQuantity: true); // in nutrient units
        var nutrient = p.nutrients.firstWhere((n) => n.nutritionalValueId == nutVal.id);
        if (p.id == -1 && !old && !nutrient.autoCalc) {
          // override
          progress = {p: amount * nutrient.value / p.amountForNutrients};
          targetProgress[t] = progress;
          if (!contributingProducts.contains(p)) contributingProducts.add(p);
          continue targetLoop;
        }
        amount *= nutrient.value / p.amountForNutrients;
      }
      if (amount <= 0) continue;
      if (!old && !contributingProducts.contains(p)) contributingProducts.add(p);
      progress[old ? null : p] = (progress[old ? null : p] ?? 0.0) + amount;
    }
    
    targetProgress[t] = progress;
  }
  
  // rank the products by relevancy. The most relevant products are the ones that contributed the most to the target
  // For each target, the products contribution to it is calulated. For each product, the root mean square of the contributions is calculated
  
  Map<Product, double> relevancy = {};
  for (var p in contributingProducts) {
    if (p.id == -1) {
      relevancy[p] = double.infinity;
      continue;
    }
    List<double> contributions = [];
    for (var entry in targetProgress.entries) {
      var progress = entry.value;
      var target = entry.key;
      
      var absoluteContribution = progress[p] ?? 0.0;
      if (!target.isPrimary) absoluteContribution *= 0.5;
      contributions.add(absoluteContribution / target.amount);
    }
    
    // rms
    relevancy[p] = sqrt(contributions.fold(0.0, (prev, contribution) => prev + contribution * contribution) / contributions.length);
  }
  
  // sort the products by relevancy descending
  contributingProducts.sort((a, b) => relevancy[b]!.compareTo(relevancy[a]!));
  
  // combine the products that contributed the least to the target
  for (int i = maxProducts; i < contributingProducts.length; i++) {
    var p = contributingProducts[i];
    // combine the product into the null product
    for (var t in targets) {
      var progress = targetProgress[t]!;
      var pProgress = progress[p] ?? 0.0;
      progress[null] = (progress[null] ?? 0.0) + pProgress;
      progress.remove(p);
    }
  }
  
  // shorten the contributingProducts list
  contributingProducts = contributingProducts.sublist(0, min(maxProducts, contributingProducts.length));
  
  if (sortByRelevancy) {
    // make all progress maps in targetProgress have the same order as contributingProducts
    for (var t in targets) {
      var progress = targetProgress[t];
      if (progress == null) continue;
      
      // sort the map entries by the relevancy of their product
      var sortedEntries = progress.entries.toList()..sort((a, b) {
        // if a or b is null, it will be ranked top
        if (a.key == null) return -1;
        if (b.key == null) return 1;
        return relevancy[b.key]!.compareTo(relevancy[a.key]!);
      });
      var newProgress = <Product?, double>{};
      for (var entry in sortedEntries) {
        newProgress[entry.key] = entry.value;
      }
      
      targetProgress[t] = newProgress;
    }
  } else {
    // apply original sorting to contributingProducts
    contributingProducts.sort((a, b) => mealSorting[a]!.compareTo(mealSorting[b]!));
  }
  // devtools.log("Progress: ");
  // for (var entry in targetProgress.entries) {
  //   var t = entry.key;
  //   var progress = entry.value;
  //   devtools.log("${t.toString()}: $progress");
  // }
  return (targetProgress, contributingProducts);
}

// calculate the amount of the target product in the meal
double calcProductTargetRecursively(Map<int, Product> productsMap, Unit targetUnit, ProductQuantity pQ, Product targetProduct, int safetyCounter) {
  if (safetyCounter >= 128) throw InfiniteLoopException();
  
  var p = productsMap[pQ.productId];
  
  if (p == null) return 0;
  if (p.id == targetProduct.id) {
    // Convert from pQ.unit to specified
    return convertToUnit(targetUnit, pQ.unit, pQ.amount, p.densityConversion, p.quantityConversion, enableTargetQuantity: true);
  }
  if (p.ingredients.isEmpty) return 0;
  
  // We know pQ.amount pQ.unit of p is used
  // Now we need to convert that to p.ingredientsUnit to know how much of each ingredient is used
  var ingredientsAmount = convertToUnit(p.ingredientsUnit, pQ.unit, pQ.amount, p.densityConversion, p.quantityConversion, enableTargetQuantity: true);
  var ingredientsFactor = ingredientsAmount / p.amountForIngredients;
  // check the ingredients
  var amount = 0.0;
  for (var ingr in p.ingredients) {
    double ingredientAmount = ingredientsFactor * ingr.amount;
    ProductQuantity ingrPQ = ProductQuantity(
      productId: ingr.productId,
      amount: ingredientAmount,
      unit: ingr.unit,
    );
    var ingrAmount = calcProductTargetRecursively(productsMap, targetUnit, ingrPQ, targetProduct, safetyCounter + 1);
    amount += ingrAmount;
  }
  
  return amount;
}

// returns -1 if the date is before the interval, 0 if it is inside the interval, 1 if it is after the interval
int isDateInsideInterval(DateTime refDate, DateTime start, DateTime end) {
  start = start.subtract(const Duration(days: 1));
  
  start = DateTime(start.year, start.month, start.day, 23, 59, 59);
  end = DateTime(end.year, end.month, end.day, 23, 59, 59);
  if (refDate.isBefore(start)) return -1;
  if (refDate.isAfter(end)) return 1;
  return 0;
}

int daysBetween(DateTime earlier, DateTime later) {
  later = DateTime.utc(later.year, later.month, later.day);
  earlier = DateTime.utc(earlier.year, earlier.month, earlier.day);

  return later.difference(earlier).inDays;
}

DateTime roundToDay(DateTime dt) {
  return DateTime.utc(dt.year, dt.month, dt.day);
}

DateTime roundToHour(DateTime dt) {
  return DateTime.utc(dt.year, dt.month, dt.day, dt.hour);
}