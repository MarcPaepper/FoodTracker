// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';

import 'package:food_tracker/constants/tables.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:rxdart/rxdart.dart';
  
import 'package:food_tracker/services/data/data_exceptions.dart';
import 'package:food_tracker/services/data/data_objects.dart';
import 'package:food_tracker/services/data/data_provider.dart';

import "dart:developer" as devtools show log;

import '../../utility/data_logic.dart';
import 'async_provider.dart';
import 'object_mapping.dart';

const productTable          = "product";
const mealTable             = "meal";
const nutritionalValueTable = "nutritional_value";
const ingredientTable       = "ingredient";
const productNutrientTable  = "product_nutrient";
const targetTable           = "target";

const forceReset = false;

const relevancyUpdateDelay = 10;

class SqfliteDataProvider implements DataProvider {
  Database? _db;
  var _loaded = false;
  
  // cached data
  List<Product> _products = [];
  Map<int, Product> _productsMap = {};
  List<NutritionalValue> _nutritionalValues = [];
  List<Meal> _meals = [];
  List<Target> _targets = [];
  
  final _productsStreamController = BehaviorSubject<List<Product>>();
  final _nutritionalValuesStreamController = BehaviorSubject<List<NutritionalValue>>();
  final _mealsStreamController = BehaviorSubject<List<Meal>>();
  final _targetsStreamController = BehaviorSubject<List<Target>>();

  SqfliteDataProvider(String dbName);
  
  @override
  bool isLoaded() => _loaded;
  
  @override
  Future<String> open(String dbName, {bool addDefNutVals = true}) async {
    if (isLoaded()) return Future.value("data already loaded");
    devtools.log("Opening sqflite database");
    
    var tables = {
      productTable: (createProductTable, productColumns, missingProductColumns),
      nutritionalValueTable: (createNutritionalValueTable, nutritionalValueColumns, missingNutritionalValueColumns),
      ingredientTable: (createIngredientTable, ingredientColumns, missingIngredientColumns),
      productNutrientTable: (createProductNutrientTable, productNutrientColumns, missingProductNutrientColumns),
      mealTable: (createMealTable, mealColumns, missingMealColumns),
      targetTable: (createTargetTable, targetColumns, missingTargetColumns),
    };
    try {
      // Find file
      String dbPath;
      if (kIsWeb) {
        dbPath = "/assets/db";
      } else {
        var docsPath = await getApplicationDocumentsDirectory();
        dbPath = join(docsPath.path, dbName);
        // log
        devtools.log("Database path: $dbPath");
        // delete file if forceReset
        if (forceReset) {
          try {
            await deleteDatabase(dbPath);
            devtools.log("Database deleted");
          } catch (e) {
            devtools.log("Error deleting database: $e");
          }
        }
      }
      _db = await openDatabase(dbPath);
      
      for (final entry in tables.entries) {
        var (createTable, columns, missingColumns) = entry.value;
        
        // Check whether the table exists
        var result = await _db!.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='${entry.key}'");
        if (result.isEmpty) {
          devtools.log("Creating table ${entry.key}");
          await _db!.execute(createTable);
          
          // If table is Nutritional Value, insert the default values
          if (entry.key == nutritionalValueTable && addDefNutVals) {
            for (var value in defaultNutritionalValues) {
              await createNutritionalValue(value, ignoreLoaded: true);
            }
          }
        } else {
          // Extract all columns from table
          var existingColumnsMap = await _db!.rawQuery("SELECT name FROM PRAGMA_TABLE_INFO('${entry.key}')");
          var existingColumns = existingColumnsMap.map((e) => e.values.first).toList();
          
          // Check whether the table has all columns
          for (var column in columns) {
            // Extract column name from the string
            var columnName = column.split(" ")[0].replaceAll('"', '');
            
            if (!existingColumns.contains(columnName)) {
              devtools.log("Adding column $column to table ${entry.key}");
              await _db!.execute("ALTER TABLE ${entry.key} ADD COLUMN $column");
              if (missingColumns.containsKey(columnName)) {
                devtools.log("Executing missing column query for $columnName");
                await _db!.execute(missingColumns[columnName]!());
              }
            }
          }
        }
      }
      _loaded = true;
      
      await getAllProducts(cache: false);
      await getAllNutritionalValues(cache: false);
      await getAllMeals(cache: false);
      await getAllTargets(cache: false);
      await cleanUp();
      
      Future.delayed(const Duration(milliseconds: relevancyUpdateDelay), () => AsyncProvider.getRelevancies(useCached: false));
      
      return "data loaded";
    } on MissingPlatformDirectoryException {
       throw NoDocumentsDirectoryException();
    }
  }
  
  @override
  Future<void> reset(String dbName) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    try {
      await deleteDatabase(_db!.path);
      devtools.log("Database deleted");
    } catch (e) {
      devtools.log("Error deleting database: $e");
    }
    devtools.log("Database reset");
    _db = null;
    _loaded = false;
    await open(dbName, addDefNutVals: false);
  }
  
  @override
  Future<String> reload() async {
    await _db!.close();
    devtools.log("reloading");
    _db = null;
    _loaded = false;
    return await open("test");
  }
  
  @override
  Future<void> close() async {
    _productsStreamController.close();
    _nutritionalValuesStreamController.close();
    _mealsStreamController.close();
    await _db!.close();
    devtools.log("closing");
    _db = null;
    _loaded = false;
  }
  
  @override
  Future<void> cleanUp() async {
    if (!isLoaded()) throw DataNotLoadedException();
    // remove all meals with invalid product ids
    int invalidProductCount = 0;
    var mealRows = await _db!.query(mealTable);
    for (var row in mealRows) {
      var productId = row[productIdColumn] as int;
      if (!_productsMap.containsKey(productId)) {
        await _db!.delete(mealTable, where: '$idColumn = ?', whereArgs: [row[idColumn] as int]);
        _meals.removeWhere((m) => m.id == row[idColumn]);
        invalidProductCount++;
      }
    }
    if (invalidProductCount > 0) _mealsStreamController.add(_meals);
  }
  
  // ----- Products -----
  
  @override
  Stream<List<Product>> streamProducts() => _productsStreamController.stream;
  
  @override
  void reloadProductStream() => isLoaded() ? _productsStreamController.add(_products) : null;
  
  @override
  Future<Iterable<Product>> getAllProducts({bool cache = true}) async {
    if (!isLoaded()) throw DataNotLoadedException();
    if (cache && _products.isNotEmpty) return _products;
    
    var productRows = await _db!.query(productTable);
    _products = <Product>[];
    _productsMap = {};
    for (var row in productRows) {
      var product = mapToProduct(row);
      _products.add(product);
      _productsMap[product.id] = product;
    }
    // add ingredients to products
    var ingredientRows = await _db!.query(ingredientTable);
    for (var row in ingredientRows) {
      var id = row[isContainedInIdColumn] as int;
      var containedInProduct = _productsMap[id]!;
      containedInProduct.ingredients.add(mapToProductQuantity(row));
    }
    // add nutrients to products
    var nutrientRows = await _db!.query(productNutrientTable);
    for (var row in nutrientRows) {
      var id = row[productIdColumn] as int;
      var product = _productsMap[id]!;
      product.nutrients.add(mapToProductNutrient(row));
    }
    
    _productsStreamController.add(_products);
    
    return _products;
  }
  
  @override
  Future<Product> getProduct(int id) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    if (_productsMap.containsKey(id)) return _productsMap[id]!;
    else throw NotFoundException();
  }
  
  @override
  Future<Product> createProduct(Product product) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final results = await _db!.query(productTable, where: '$nameColumn = ?', whereArgs: [product.name]);
    if (results.isNotEmpty) throw NotUniqueException();
    
    var now = DateTime.now();
    product.lastEditDate ??= now;
    product.creationDate ??= now;
    var map = productToMap(product);
    // remove id, ingredients, nutrients
    map.remove(idColumn);
    map.remove("ingredients");
    map.remove("nutrients");
    // set creation and last edit date
    map[creationDateColumn] = now.toIso8601String();
    map[lastEditDateColumn] = now.toIso8601String();
    
    final id = await _db!.insert(productTable, map);
    
    product = product.copyWith(newId: id);
    
    _addIngredients(product: product, containedInId: id);
    _addProductNutrientsForProduct(product: product, productId: id);
    
    _products.add(product);
    _productsMap[id] = product;
    _productsStreamController.add(_products);
    Future.delayed(const Duration(milliseconds: relevancyUpdateDelay), () => AsyncProvider.updateRelevancyFor([id]));
    
    return product;
  }
  
  @override
  Future<Product> updateProduct(Product product, {bool recalc = true}) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    if (recalc) {
      var updatedProducts = recalcProductNutrients(product, _products, _productsMap);
      for (var updatedProduct in updatedProducts) {
        await updateProduct(updatedProduct, recalc: false);
      }
    }
    
    product.lastEditDate = DateTime.now();
    
    var map = productToMap(product);
    // remove id, ingredients, nutrients
    map.remove(idColumn);
    map.remove("ingredients");
    map.remove("nutrients");
    
    final updatedCount = await _db!.update(productTable, map, where: '$idColumn = ?', whereArgs: [product.id]);
    if (updatedCount != 1) throw InvalidUpdateException();
    
    await _deleteIngredients(containedInId: product.id);
    await _addIngredients(product: product, containedInId: product.id);
    
    await _deleteProductNutrientsForProduct(productId: product.id);
    await _addProductNutrientsForProduct(product: product, productId: product.id);
    
    _products.removeWhere((p) => p.id == product.id);
    _products.add(product);
    _productsMap[product.id] = product;
    _productsStreamController.add(_products);
    if(recalc) Future.delayed(const Duration(milliseconds: relevancyUpdateDelay), () => AsyncProvider.updateRelevancyFor([product.id]));
    
    return product;
  }
  
  @override
  Future<void> deleteProduct(int id) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final deletedCount = await _db!.delete(productTable, where: '$idColumn = ?', whereArgs: [id]);
    if (deletedCount != 1) throw InvalidDeletionException();
    
    _deleteIngredients(containedInId: id);
    _deleteProductNutrientsForProduct(productId: id);
    
    _products.removeWhere((p) => p.id == id);
    _productsMap.remove(id);
    _productsStreamController.add(_products);
    Future.delayed(const Duration(milliseconds: relevancyUpdateDelay), () => AsyncProvider.updateRelevancyFor([id]));
  }
  
  @override
  Future<void> deleteProductWithName(String name) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final results = await _db!.query(productTable, where: '$nameColumn = ?', whereArgs: [name]);
    if (results.isEmpty) throw NotFoundException();
    if (results.length > 1) throw NotUniqueException();
    final id = results.first[idColumn] as int;
    
    return deleteProduct(id);
  }
  
  // ----- Ingredients -----
  
  Future<void> _addIngredients({required Product product, required int containedInId}) async {
    for (final ingredient in product.ingredients) {
      if (ingredient.productId == null) throw ArgumentError("Ingredient product id is null");
      await _db!.insert(ingredientTable, {
        productIdColumn:        ingredient.productId!,
        isContainedInIdColumn:  containedInId,
        amountColumn:           ingredient.amount,
        unitColumn:             unitToString(ingredient.unit),
      });
    }
  }
  
  Future<void> _deleteIngredients({required int containedInId}) async {
    await _db!.delete(ingredientTable, where: '$isContainedInIdColumn = ?', whereArgs: [containedInId]);
  }
  
  // ----- Nutritional values -----
  
  @override
  Stream<List<NutritionalValue>> streamNutritionalValues() => _nutritionalValuesStreamController.stream;
  
  @override
  void reloadNutritionalValueStream() => isLoaded() ? _nutritionalValuesStreamController.add(_nutritionalValues) : null;
  
  @override
  Future<Iterable<NutritionalValue>> getAllNutritionalValues({bool cache = true}) async {
    if (!isLoaded()) throw DataNotLoadedException();
    if (cache && _nutritionalValues.isNotEmpty) return _nutritionalValues;
    
    var nutValRows = await _db!.query(nutritionalValueTable);
    _nutritionalValues = nutValRows.map((row) => mapToNutritionalValue(row)).toList();
    
    _nutritionalValuesStreamController.add(_nutritionalValues);
    
    return _nutritionalValues;
  }
  
  @override
  Future<NutritionalValue> getNutritionalValue(int id) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final results = await _db!.query(nutritionalValueTable, where: '$idColumn = ?', whereArgs: [id]);
    if (results.isEmpty) throw NotFoundException();
    if (results.length > 1) throw NotUniqueException();
    
    var nutritionalValue = mapToNutritionalValue(results.first);
    
    _nutritionalValuesStreamController.add(_nutritionalValues);
    
    return nutritionalValue;
  }
  
  @override
  Future<NutritionalValue> createNutritionalValue(NutritionalValue nutVal, {bool ignoreLoaded = false}) async {
    if (!isLoaded() && !ignoreLoaded) throw DataNotLoadedException();
    
    final results = await _db!.query(nutritionalValueTable, where: '$nameColumn = ?', whereArgs: [nutVal.name]);
    if (results.isNotEmpty) throw NotUniqueException();
    
    // find highest order id
    var orderId = 0;
    try {
      var orderResults = await _db!.query(nutritionalValueTable, columns: [orderIdColumn], orderBy: '$orderIdColumn DESC', limit: 1);
      orderId = (orderResults.first[orderIdColumn] as int) + 1;
    } catch (e) {
      // ignore
    }
    
    nutVal = nutVal.copyWith(newOrderId: orderId);
    var map = nutValueToMap(nutVal);
    map.remove(idColumn);
    
    final id = await _db!.insert(nutritionalValueTable, map);
    
    _addProductNutrientsForNutritionalValue(nutritionalValueId: id);
    
    var newNutVal = nutVal.copyWith(newId: id);
    _nutritionalValues.add(newNutVal);
    _nutritionalValuesStreamController.add(_nutritionalValues);
    
    return newNutVal;
  }
  
  @override
  Future<NutritionalValue> updateNutritionalValue(NutritionalValue nutVal) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    var map = nutValueToMap(nutVal);
    map.remove(idColumn);
    final updatedCount = await _db!.update(nutritionalValueTable, map, where: '$idColumn = ?', whereArgs: [nutVal.id]);
    if (updatedCount != 1) throw InvalidUpdateException();
    
    _nutritionalValues.removeWhere((p) => p.id == nutVal.id);
    _nutritionalValues.add(nutVal);
    _nutritionalValuesStreamController.add(_nutritionalValues);
     
    return nutVal;
  }
  
  @override
  Future<void> reorderNutritionalValues(Map<int, int> orderMap) async {
    if (!isLoaded()) throw DataNotLoadedException();

    final batch = _db!.batch();

    for (final entry in orderMap.entries) {
      batch.update(
        nutritionalValueTable,
        {orderIdColumn: entry.value},
        where: '$idColumn = ?',
        whereArgs: [entry.key],
      );
      _nutritionalValues.firstWhere((p) => p.id == entry.key).orderId = entry.value;
    }
    
    _nutritionalValuesStreamController.add(_nutritionalValues);

    await batch.commit(noResult: true);
  }
  
  @override
  Future<void> deleteNutritionalValue(int id) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final deletedCount = await _db!.delete(nutritionalValueTable, where: '$idColumn = ?', whereArgs: [id]);
    if (deletedCount != 1) throw InvalidDeletionException();
    
    _deleteProductNutrientsForNutritionalValue(nutritionalValueId: id);
    
    _nutritionalValues.removeWhere((p) => p.id == id);
    _nutritionalValuesStreamController.add(_nutritionalValues);
  }
  
  @override
  Future<void> deleteNutritionalValueWithName(String name) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final results = await _db!.query(nutritionalValueTable, where: '$nameColumn = ?', whereArgs: [name]);
    if (results.isEmpty) throw NotFoundException();
    if (results.length > 1) throw NotUniqueException();
    final id = results.first[idColumn] as int;
    
    return deleteNutritionalValue(id);
  }
  
  // ----- Product Nutrients -----
  
  Future<void> _addProductNutrientsForProduct({required Product product, required int productId}) async {
    for (final nutrient in product.nutrients) {
      await _db!.insert(productNutrientTable, {
        nutritionalValueIdColumn: nutrient.nutritionalValueId,
        productIdColumn:          productId,
        autoCalcColumn:           nutrient.autoCalc ? 1 : 0,
        valueColumn:              nutrient.value,
      });
    }
  }
  
  Future<void> _addProductNutrientsForNutritionalValue({required int nutritionalValueId}) async {
    for (final product in _products) {
      var nutrient = ProductNutrient(
        nutritionalValueId: nutritionalValueId,
        productId:          product.id,
        autoCalc:           true,
        value:              0,
      );
      await _db!.insert(productNutrientTable, {
        nutritionalValueIdColumn: nutrient.nutritionalValueId,
        productIdColumn:          nutrient.productId,
        autoCalcColumn:           nutrient.autoCalc ? 1 : 0,
        valueColumn:              nutrient.value,
      });
      product.nutrients.add(nutrient);
    }
  }
  
  Future<void> _deleteProductNutrientsForProduct({required int productId}) async {
    await _db!.delete(productNutrientTable, where: '$productIdColumn = ?', whereArgs: [productId]);
  }
  
  Future<void> _deleteProductNutrientsForNutritionalValue({required int nutritionalValueId}) async {
    await _db!.delete(productNutrientTable, where: '$nutritionalValueIdColumn = ?', whereArgs: [nutritionalValueId]);
  }
  
  // ----- Meals -----
  
  @override
  Stream<List<Meal>> streamMeals() => _mealsStreamController.stream;
  
  @override
  void reloadMealStream() => isLoaded() ? _mealsStreamController.add(_meals) : null;
  
  @override
  Future<Iterable<Meal>> getAllMeals({bool cache = true}) async {
    if (!isLoaded()) throw DataNotLoadedException();
    if (cache && _meals.isNotEmpty) return _meals;
    
    var mealRows = await _db!.query(mealTable);
    _meals = mealRows.map((row) => mapToMeal(row)).toList();
    // sort by datetime (ascending), secondary by creation date (ascending)
    _meals.sort((a, b) {
      var dateComp = a.dateTime.compareTo(b.dateTime);
      if (dateComp != 0 || a.creationDate == null || b.creationDate == null) return dateComp;
      return a.creationDate!.compareTo(b.creationDate!);
    });
    
    _mealsStreamController.add(_meals);
    
    return _meals;
  }
  
  @override
  Future<Meal> getMeal(int id) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final results = await _db!.query(mealTable, where: '$idColumn = ?', whereArgs: [id]);
    if (results.isEmpty) throw NotFoundException();
    if (results.length > 1) throw NotUniqueException();
    
    var meal = mapToMeal(results.first);
    
    _mealsStreamController.add(_meals);
    
    return meal;
  }
  
  @override
  Future<Meal> createMeal(Meal meal) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    meal = meal.copyWith(newCreationDate: DateTime.now(), newLastEditDate: DateTime.now());
    var map = mealToMap(meal);
    map.remove(idColumn);
    final id = await _db!.insert(mealTable, map);
    
    var newMeal = meal.copyWith(newId: id);
    _meals.insert(findInsertIndex(_meals, newMeal), newMeal);
    _mealsStreamController.add(_meals);
    Future.delayed(const Duration(milliseconds: relevancyUpdateDelay), () => AsyncProvider.updateRelevancyFor([newMeal.productQuantity.productId!]));
    
    return newMeal;
  }
  
  @override
  Future<Meal> updateMeal(Meal meal) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    meal = meal.copyWith(newLastEditDate: DateTime.now());
    var map = mealToMap(meal);
    map.remove(idColumn);
    
    final updatedCount = await _db!.update(mealTable, map, where: '$idColumn = ?', whereArgs: [meal.id]);
    if (updatedCount != 1) throw InvalidUpdateException();
    
    _meals.removeWhere((m) => m.id == meal.id);
    _meals.insert(findInsertIndex(_meals, meal), meal);
    _mealsStreamController.add(_meals);
    Future.delayed(const Duration(milliseconds: relevancyUpdateDelay), () => AsyncProvider.updateRelevancyFor([meal.productQuantity.productId!]));
    
    return meal;
  }
  
  @override
  Future<void> deleteMeal(int id) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    Meal meal = _meals.firstWhere((m) => m.id == id);
    
    final deletedCount = await _db!.delete(mealTable, where: '$idColumn = ?', whereArgs: [id]);
    if (deletedCount != 1) throw InvalidDeletionException();
    
    _meals.remove(meal);
    _mealsStreamController.add(_meals);
    Future.delayed(const Duration(milliseconds: relevancyUpdateDelay), () => AsyncProvider.updateRelevancyFor([meal.productQuantity.productId!]));
  }
  
  // ----- Target -----
  
  @override
  Stream<List<Target>> streamTargets() => _targetsStreamController.stream;
  
  @override
  void reloadTargetStream() => isLoaded() ? _targetsStreamController.add(_targets) : null;
  
  @override
  Future<Iterable<Target>> getAllTargets({bool cache = true}) async {
    if (!isLoaded()) throw DataNotLoadedException();
    if (cache && _targets.isNotEmpty) return _targets;
    
    var targetRows = await _db!.query(targetTable);
    _targets = targetRows.map((row) => mapToTarget(row)).toList();
    
    _targetsStreamController.add(_targets);
    
    return _targets;
  }
  
  @override
  Future<Target> getTarget(Type targetType, int targetId) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final results = await _db!.query(targetTable, where: '$typeColumn = ? AND $trackedIdColumn = ?', whereArgs: [targetType.toString(), targetId]);
    if (results.isEmpty) throw NotFoundException();
    if (results.length > 1) throw NotUniqueException();
    
    var target = mapToTarget(results.first);
    
    _targetsStreamController.add(_targets);
    
    return target;
  }
  
  @override
  Future<Target> createTarget(Target target, {int? orderId}) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final results = await _db!.query(targetTable, where: '$typeColumn = ? AND $trackedIdColumn = ?', whereArgs: [target.trackedType.toString(), target.trackedId]);
    if (results.isNotEmpty) throw NotUniqueException();
    
    target = target.copyWith(newOrderId: await _findInsertIndex(target, orderId: orderId));
    var map = targetToMap(target);
    map.remove(idColumn);
    
    await _db!.insert(targetTable, map);
    
    _targets.add(target);
    _targetsStreamController.add(_targets);
    
    return target;
  }
  
  @override
  Future<Target> updateTarget(Type origType, int origTrackedId, Target target) async {
    var origTarget = _targets.firstWhere((t) => t.trackedType == origType && t.trackedId == origTrackedId);
    // If the target switched from primary to secondary or vice versa, find the new order id
    var orderId = (origTarget.isPrimary != target.isPrimary) ? await _findInsertIndex(target) : origTarget.orderId;
    await deleteTarget(origType, origTrackedId);
    return createTarget(target, orderId: orderId);
  }
  
  Future<int> _findInsertIndex(Target target, {int? orderId}) async {
    // find highest order id for primary or secondary
    if (orderId == null) {
      orderId = 0;
      // if the target is primary, find the highest primary order id. If not, find the highest order id overall
      for (var t in _targets) {
        if ((t.isPrimary && target.isPrimary) && t.orderId >= orderId!) orderId = t.orderId + 1;
        if (!t.isPrimary && t.orderId >= orderId!) orderId = t.orderId + 1;
      }
    }
    if (target.isPrimary) {
      // increase all secondary order ids by 1
      for (var t in _targets) {
        if (!t.isPrimary) {
          t.orderId++;
          await _db!.update(targetTable, {orderIdColumn: t.orderId}, where: '$typeColumn = ? AND $trackedIdColumn = ?', whereArgs: [t.trackedType.toString(), t.trackedId]);
        }
      }
    }
    devtools.log("Order:${_targets.map((t) => " ${t.isPrimary ? "P" : "S"}${t.orderId}").join()}");
    devtools.log("New order id: $orderId");
    return orderId!;
  }
  
  @override
  Future<void> reorderTargets(Map<(Type, int), int> orderMap) async {
    if (!isLoaded()) throw DataNotLoadedException();

    final batch = _db!.batch();

    for (final entry in orderMap.entries) {
      batch.update(
        targetTable,
        {orderIdColumn: entry.value},
        where: '$typeColumn = ? AND $trackedIdColumn = ?',
        whereArgs: [entry.key.$1.toString(), entry.key.$2],
      );
      _targets.firstWhere((t) => t.trackedType == entry.key.$1 && t.trackedId == entry.key.$2).orderId = entry.value;
    }
    
    _targetsStreamController.add(_targets);

    await batch.commit(noResult: true);
  }
  
  @override
  Future<void> deleteTarget(Type trackedType, int trackedId) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final deletedCount = await _db!.delete(targetTable, where: '$typeColumn = ? AND $trackedIdColumn = ?', whereArgs: [trackedType.toString(), trackedId]);
    if (deletedCount != 1) throw InvalidDeletionException();
    
    _targets.removeWhere((t) => t.trackedType == trackedType && t.trackedId == trackedId);
    _targetsStreamController.add(_targets);
  }
}