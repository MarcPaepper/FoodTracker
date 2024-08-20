// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';

import 'package:food_tracker/constants/tables.dart';
import 'package:food_tracker/utility/text_logic.dart';
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

const productTable = "product";
const mealTable = "meal";
const nutritionalValueTable = "nutritional_value";
const ingredientTable = "ingredient";
const productNutrientTable = "product_nutrient";

// multiple tables

const idColumn                    = "id";

// product table

const nameColumn                  = "name";
const creationDateColumn          = "creation_date";
const lastEditDateColumn          = "last_edit_date";
const temporaryBeginningColumn    = "temporary_beginning";
const temporaryEndColumn          = "temporary_end";
const isTemporaryColumn           = "is_temporary";
const quantityNameColumn          = "quantity_name";
const densityConversionColumn     = "density_conversion";
const quantityConversionColumn    = "quantity_conversion";
const defaultUnitColumn           = "default_unit";
const autoCalcAmountColumn        = "auto_calc_amount";
const amountForIngredientsColumn  = "amount_for_ingredients";
const ingredientsUnitColumn       = "ingredients_unit";
const amountForNutrientsColumn    = "amount_for_nutrients";
const nutrientsUnitColumn         = "nutrients_unit";

// nutritional value table

const unitNameColumn              = "unit";
const orderIdColumn               = "order_id";
const showFullNameColumn          = "show_full_name";

// ingredient table

const ingredientIdColumn          = "ingredient_id";
const isContainedInIdColumn       = "is_contained_in_id";
const amountColumn                = "amount";
const unitColumn                  = "unit";

// product nutrient table

const nutritionalValueIdColumn    = "nutritional_value_id";
const productIdColumn             = "product_id";
const autoCalcColumn              = "auto_calc";
const valueColumn                 = "value";

// meal table

const dateTimeColumn               = "date_time";
const mealAmountColumn             = "amount";
const mealUnitColumn               = "unit";

const forceReset = false;

class SqfliteDataProvider implements DataProvider {
  Database? _db;
  
  // cached data
  List<Product> _products = [];
  Map<int, Product> _productsMap = {};
  List<NutritionalValue> _nutritionalValues = [];
  List<Meal> _meals = [];
  
  final _productsStreamController = BehaviorSubject<List<Product>>();
  final _nutritionalValuesStreamController = BehaviorSubject<List<NutritionalValue>>();
  final _mealsStreamController = BehaviorSubject<List<Meal>>();

  SqfliteDataProvider(String dbName);
  
  @override
  bool isLoaded() => _db != null;
  
  @override
  Future<String> open(String dbName) async {
    if (isLoaded()) return Future.value("data already loaded");
    devtools.log("Opening sqflite database");
    
    var tables = {
      productTable: (createProductTable, productColumns, missingProductColumns),
      nutritionalValueTable: (createNutritionalValueTable, nutritionalValueColumns, missingNutritionalValueColumns),
      ingredientTable: (createIngredientTable, ingredientColumns, missingIngredientColumns),
      productNutrientTable: (createProductNutrientTable, productNutrientColumns, missingProductNutrientColumns),
      mealTable: (createMealTable, mealColumns, missingMealColumns),
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
          if (entry.key == nutritionalValueTable) {
            for (var value in defaultNutritionalValues) {
              await createNutritionalValue(value);
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
              // check whether there are any missing columns
              if (missingColumns.containsKey(columnName)) {
                await _db!.execute(missingColumns[columnName]!());
              }
            }
          }
        }
      }
      
      await getAllProducts();
      await getAllNutritionalValues();
      await getAllMeals();
      await cleanUp();
      
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
    _db = null;
    open(dbName);
  }
  
  @override
  Future<void> close() async {
    _productsStreamController.close();
    _nutritionalValuesStreamController.close();
    _mealsStreamController.close();
    await _db!.close();
    _db = null;
  }
  
  @override
  Future<void> cleanUp() async {
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
  Future<Iterable<Product>> getAllProducts() async {
    if (!isLoaded()) throw DataNotLoadedException();
    
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
      containedInProduct.ingredients.add(await mapToProductQuantity(row));
    }
    // add nutrients to products
    var nutrientRows = await _db!.query(productNutrientTable);
    for (var row in nutrientRows) {
      var id = row[productIdColumn] as int;
      var product = _productsMap[id]!;
      product.nutrients.add(await mapToProductNutrient(row));
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
    
    final id = await _db!.insert(productTable, {
      nameColumn:                  product.name,
      defaultUnitColumn:           unitToString(product.defaultUnit),
      creationDateColumn:          DateTime.now().toIso8601String(),
      lastEditDateColumn:          DateTime.now().toIso8601String(),
      temporaryBeginningColumn:    product.temporaryBeginning?.toIso8601String().split("T")[0], // YYYY-MM-DD format
      temporaryEndColumn:          product.temporaryEnd?.toIso8601String().split("T")[0], // YYYY-MM-DD format
      isTemporaryColumn:           product.isTemporary ? 1 : 0,
      quantityNameColumn:          product.quantityName,
      densityConversionColumn:     product.densityConversion.toString(),
      quantityConversionColumn:    product.quantityConversion.toString(),
      autoCalcAmountColumn:        product.autoCalc ? 1 : 0,
      amountForIngredientsColumn:  product.amountForIngredients,
      ingredientsUnitColumn:       unitToString(product.ingredientsUnit),
      amountForNutrientsColumn:    product.amountForNutrients,
      nutrientsUnitColumn:         unitToString(product.nutrientsUnit),
    });
    
    _addIngredients(product: product, containedInId: id);
    _addProductNutrientsForProduct(product: product, productId: id);
    
    var newProduct = Product.copyWith(product, newId: id, newCreationDate: DateTime.now(), newLastEditDate: DateTime.now());
    _products.add(newProduct);
    _productsMap[id] = newProduct;
    _productsStreamController.add(_products);
    
    return newProduct;
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
    
    final updatedCount = await _db!.update(productTable, {
      nameColumn:                  product.name,
      creationDateColumn:          product.creationDate!.toIso8601String(),
      lastEditDateColumn:          product.lastEditDate!.toIso8601String(),
      temporaryBeginningColumn:    product.temporaryBeginning?.toIso8601String().split("T")[0], // YYYY-MM-DD format
      temporaryEndColumn:          product.temporaryEnd?.toIso8601String().split("T")[0], // YYYY-MM-DD format
      isTemporaryColumn:           product.isTemporary ? 1 : 0,
      defaultUnitColumn:           unitToString(product.defaultUnit),
      densityConversionColumn:     product.densityConversion.toString(),
      quantityConversionColumn:    product.quantityConversion.toString(),
      quantityNameColumn:          product.quantityName,
      autoCalcAmountColumn:        product.autoCalc ? 1 : 0,
      amountForIngredientsColumn:  product.amountForIngredients,
      ingredientsUnitColumn:       unitToString(product.ingredientsUnit),
      amountForNutrientsColumn:    product.amountForNutrients,
    }, where: '$idColumn = ?', whereArgs: [product.id]);
    if (updatedCount != 1) throw InvalidUpdateException();
    
    await _deleteIngredients(containedInId: product.id);
    await _addIngredients(product: product, containedInId: product.id);
    
    await _deleteProductNutrientsForProduct(productId: product.id);
    await _addProductNutrientsForProduct(product: product, productId: product.id);
    
    _products.removeWhere((p) => p.id == product.id);
    _products.add(product);
    _productsMap[product.id] = product;
    _productsStreamController.add(_products);
    
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
        ingredientIdColumn:     ingredient.productId!,
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
  Future<Iterable<NutritionalValue>> getAllNutritionalValues() async {
    if (!isLoaded()) throw DataNotLoadedException();
    
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
  Future<NutritionalValue> createNutritionalValue(NutritionalValue nutVal) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
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
    
    final id = await _db!.insert(nutritionalValueTable, {
      nameColumn:         nutVal.name,
      orderIdColumn:      orderId,
      unitNameColumn:     nutVal.unit,
      showFullNameColumn: nutVal.showFullName ? 1 : 0,
    });
    
    _addProductNutrientsForNutritionalValue(nutritionalValueId: id);
    
    _nutritionalValues.add(NutritionalValue.copyWith(nutVal, newId: id, newOrderId: orderId));
    _nutritionalValuesStreamController.add(_nutritionalValues);
    
    return NutritionalValue(id, nutVal.orderId, nutVal.name, nutVal.unit, nutVal.showFullName);
  }
  
  @override
  Future<NutritionalValue> updateNutritionalValue(NutritionalValue nutVal) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final updatedCount = await _db!.update(nutritionalValueTable, {
      nameColumn:         nutVal.name,
      orderIdColumn:      nutVal.orderId,
      unitNameColumn:     nutVal.unit,
      showFullNameColumn: nutVal.showFullName ? 1 : 0,
    }, where: '$idColumn = ?', whereArgs: [nutVal.id]);
    if (updatedCount != 1) throw InvalidUpdateException();
    
    _nutritionalValues.removeWhere((p) => p.id == nutVal.id);
    _nutritionalValues.add(nutVal);
    _nutritionalValuesStreamController.add(_nutritionalValues);
     
    return nutVal;
  }
  
  @override
  Future<void> reorderNutritionalValues(Map<int, int> orderMap) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    for (final entry in orderMap.entries) {
      final updatedCount = await _db!.update(nutritionalValueTable, {
        orderIdColumn: entry.value,
      }, where: '$idColumn = ?', whereArgs: [entry.key]);
      _nutritionalValues.firstWhere((p) => p.id == entry.key).orderId = entry.value;
      if (updatedCount != 1) throw InvalidUpdateException();
    }
    
    _nutritionalValuesStreamController.add(_nutritionalValues);
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
      product.nutrients.add(
        ProductNutrient(
          nutritionalValueId: nutritionalValueId,
          productId:          product.id,
          autoCalc:           true,
          value:              0,
        )
      );
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
  Future<Iterable<Meal>> getAllMeals() async {
    if (!isLoaded()) throw DataNotLoadedException();
    
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
    
    final id = await _db!.insert(mealTable, {
      dateTimeColumn:     meal.dateTime.toIso8601String(),
      productIdColumn:    meal.productQuantity.productId,
      mealAmountColumn:   meal.productQuantity.amount,
      mealUnitColumn:     unitToString(meal.productQuantity.unit),
      creationDateColumn: DateTime.now().toIso8601String(),
      lastEditDateColumn: DateTime.now().toIso8601String(),
    });
    
    var newMeal = Meal.copyWith(meal, newId: id, newCreationDate: DateTime.now(), newLastEditDate: DateTime.now());
    _meals.insert(findInsertIndex(_meals, newMeal), newMeal);
    _mealsStreamController.add(_meals);
    
    return newMeal;
  }
  
  @override
  Future<Meal> updateMeal(Meal meal) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final updatedCount = await _db!.update(mealTable, {
      dateTimeColumn:     meal.dateTime.toIso8601String(),
      productIdColumn:    meal.productQuantity.productId,
      mealAmountColumn:   meal.productQuantity.amount,
      mealUnitColumn:     unitToString(meal.productQuantity.unit),
      creationDateColumn: meal.creationDate?.toIso8601String(),
      lastEditDateColumn: DateTime.now().toIso8601String(),
    }, where: '$idColumn = ?', whereArgs: [meal.id]);
    if (updatedCount != 1) throw InvalidUpdateException();
    
    _meals.removeWhere((m) => m.id == meal.id);
    _meals.insert(findInsertIndex(_meals, meal), meal);
    _mealsStreamController.add(_meals);
    
    return meal;
  }
  
  @override
  Future<void> deleteMeal(int id) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final deletedCount = await _db!.delete(mealTable, where: '$idColumn = ?', whereArgs: [id]);
    if (deletedCount != 1) throw InvalidDeletionException();
    
    _meals.removeWhere((m) => m.id == id);
    _mealsStreamController.add(_meals);
  }
}

Product mapToProduct(Map<String, dynamic> row) =>
  Product(
    id:                    row[idColumn] as int,
    name:                  row[nameColumn] as String,
    creationDate:          DateTime.parse(row[creationDateColumn] as String),
    lastEditDate:          DateTime.parse(row[lastEditDateColumn] as String),
    temporaryBeginning:    condParse(row[temporaryBeginningColumn] as String?),
    temporaryEnd:          condParse(row[temporaryEndColumn] as String?),
    isTemporary:           row[isTemporaryColumn] == 1,
    defaultUnit:           unitFromString(row[defaultUnitColumn] as String),
    densityConversion:     Conversion.fromString(row[densityConversionColumn] as String),
    quantityConversion:    Conversion.fromString(row[quantityConversionColumn] as String),
    quantityName:          row[quantityNameColumn] as String,
    autoCalc:              row[autoCalcAmountColumn] == 1,
    amountForIngredients:  toDouble(row[amountForIngredientsColumn] ?? 100),
    ingredientsUnit:       unitFromString((row[ingredientsUnitColumn] ?? row[defaultUnitColumn]) as String),
    amountForNutrients:    toDouble(row[amountForNutrientsColumn] ?? 100),
    nutrientsUnit:         unitFromString((row[nutrientsUnitColumn] ?? row[defaultUnitColumn]) as String),
    ingredients:           [],
    nutrients:             [],
  );
  
  Future<ProductQuantity> mapToProductQuantity(Map<String, Object?> row) async {
    return ProductQuantity(
      productId: row[ingredientIdColumn] as int,
      amount:    toDouble(row[amountColumn]),
      unit:      unitFromString(row[unitColumn] as String),
    );
  }
  
  NutritionalValue mapToNutritionalValue(Map<String, Object?> row) =>
    NutritionalValue(
      row[idColumn] as int,
      (row[orderIdColumn] ?? row[idColumn]) as int,
      row[nameColumn] as String,
      row[unitNameColumn] as String,
      row[showFullNameColumn] == 1,
    );


  
  Future<ProductNutrient> mapToProductNutrient(Map<String, Object?> row) async {
    return ProductNutrient(
      nutritionalValueId: row[nutritionalValueIdColumn] as int,
      productId:          row[productIdColumn] as int,
      autoCalc:           row[autoCalcColumn] == 1,
      value:              toDouble(row[valueColumn]),
    );
  }
  
  Meal mapToMeal(Map<String, Object?> row) =>
    Meal(
      id:           row[idColumn] as int,
      dateTime:     DateTime.parse(row[dateTimeColumn] as String),
      creationDate: DateTime.parse(row[creationDateColumn] as String),
      lastEditDate: DateTime.parse(row[lastEditDateColumn] as String),
      productQuantity: ProductQuantity(
        productId: row[productIdColumn] as int,
        amount:    toDouble(row[mealAmountColumn]),
        unit:      unitFromString(row[mealUnitColumn] as String),
      ),
    );