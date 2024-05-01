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
const dateColumn                  = "date";
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

const forceReset = false;

class SqfliteDataProvider implements DataProvider {
  Database? _db;
  
  // cached data
  List<Product> _products = [];
  Map<int, Product> _productsMap = {};
  final List<NutritionalValue> _nutritionalValues = [];
  
  final _productsStreamController = BehaviorSubject<List<Product>>();
  final _nutritionalValuesStreamController = BehaviorSubject<List<NutritionalValue>>();

  SqfliteDataProvider(String dbName);
  
  @override
  bool isLoaded() => _db != null;
  
  @override
  Future<String> open(String dbName) async {
    devtools.log("Opening sqflite database");
    if (isLoaded()) return Future.value("data already loaded");
    var tables = {
      productTable: (createProductTable, productColumns),
      nutritionalValueTable: (createNutritionalValueTable, nutritionalValueColumns),
      ingredientTable: (createIngredientTable, ingredientColumns),
      productNutrientTable: (createProductNutrientTable, productNutrientColumns),
    };
    try {
      // Find file
      String dbPath;
      if (kIsWeb) {
        dbPath = "/assets/db";
      } else {
        var docsPath = await getApplicationDocumentsDirectory();
        dbPath = join(docsPath.path, dbName);
        // delete file if forceReset
        if (forceReset) {
          try {
            await deleteDatabase(dbPath);
          } catch (e) {
            devtools.log("Error deleting database: $e");
          }
        }
      }
      _db = await openDatabase(dbPath);
      
      for (final entry in tables.entries) {
        var (createTable, columns) = entry.value;
        
        // Check whether the table exists
        var result = await _db!.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='${entry.key}'");
        if (result.isEmpty) {
          devtools.log("Creating table ${entry.key}");
          await _db!.execute(createTable);
          
          // If table is Nutritional Value, insert the default values
          if (entry.key == nutritionalValueTable) {
            for (var value in defaultNutritionalValues) {
              createNutritionalValue(value);
            }
          }
        } else {
          // Check whether the table has all columns
          var existingTableColumns = await _db!.query(entry.key);
          var existingColumnNames = existingTableColumns.first.keys;
          for (var column in columns) {
            // Extract column name from the string
            var columnName = column.split(" ")[0].replaceAll('"', '');
            
            if (!existingColumnNames.contains(columnName)) {
              devtools.log("Adding column $column to table ${entry.key}");
              await _db!.execute("ALTER TABLE ${entry.key} ADD COLUMN $column");
            }
          }
        }
      }
      
      getAllProducts();
      getAllNutritionalValues();
      
      return "data loaded";
    } on MissingPlatformDirectoryException {
       throw NoDocumentsDirectoryException();
    }
  }
  
  @override
  Future<void> close() async {
    _productsStreamController.close();
    _nutritionalValuesStreamController.close();
    await _db!.close();
    _db = null;
  }
  
  // ----- Products -----
  
  @override
  Stream<List<Product>> streamProducts() => _productsStreamController.stream;
  
  @override
  void reloadProductStream() {
    if (isLoaded()) _productsStreamController.add(_products);
  }
  
  @override
  Future<Iterable<Product>> getAllProducts() async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    var productRows = await _db!.query(productTable);
    _products = <Product>[];
    _productsMap = {};
    for (var row in productRows) {
      var product = _dbRowToProduct(row);
      _products.add(product);
      _productsMap[product.id] = product;
    }
    // add ingredients to products
    var ingredientRows = await _db!.query(ingredientTable);
    for (var row in ingredientRows) {
      var id = row[isContainedInIdColumn] as int;
      var containedInProduct = _productsMap[id]!;
      containedInProduct.ingredients.add(await _dbRowToProductQuantity(row));
    }
    // add nutrients to products
    var nutrientRows = await _db!.query(productNutrientTable);
    for (var row in nutrientRows) {
      var id = row[productIdColumn] as int;
      var product = _productsMap[id]!;
      product.nutrients.add(await _dbRowToProductNutrient(row));
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
  
  Product _dbRowToProduct(Map<String, Object?> row) =>
    Product(
      id:                    row[idColumn] as int,
      name:                  row[nameColumn] as String,
      defaultUnit:           unitFromString(row[defaultUnitColumn] as String),
      densityConversion:     Conversion.fromString(row[densityConversionColumn] as String),
      quantityConversion:    Conversion.fromString(row[quantityConversionColumn] as String),
      quantityName:          row[quantityNameColumn] as String,
      autoCalc:              row[autoCalcAmountColumn] == 1,
      amountForIngredients:  toDouble(row[amountForIngredientsColumn]),
      ingredientsUnit:       unitFromString(row[ingredientsUnitColumn] as String),
      amountForNutrients:    toDouble(row[amountForNutrientsColumn]),
      nutrientsUnit:         unitFromString(row[nutrientsUnitColumn] as String),
      ingredients:           [],
      nutrients:             [],
    );
  
  @override
  Future<Product> createProduct(Product product) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final results = await _db!.query(productTable, where: '$nameColumn = ?', whereArgs: [product.name]);
    if (results.isNotEmpty) throw NotUniqueException();
    
    final id = await _db!.insert(productTable, {
      nameColumn:                  product.name,
      defaultUnitColumn:           unitToString(product.defaultUnit),
      densityConversionColumn:     product.densityConversion.toString(),
      quantityConversionColumn:    product.quantityConversion.toString(),
      quantityNameColumn:          product.quantityName,
      autoCalcAmountColumn:        product.autoCalc ? 1 : 0,
      amountForIngredientsColumn:  product.amountForIngredients,
      ingredientsUnitColumn:       unitToString(product.ingredientsUnit),
      amountForNutrientsColumn:    product.amountForNutrients,
      nutrientsUnitColumn:         unitToString(product.nutrientsUnit),
    });
    
    _addIngredients(product: product, containedInId: id);
    _addProductNutrientsForProduct(product: product, productId: id);
    
    var newProduct = Product.copyWithDifferentId(product, id);
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
    
    final updatedCount = await _db!.update(productTable, {
      nameColumn:                  product.name,
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
  
  Future<ProductQuantity> _dbRowToProductQuantity(Map<String, Object?> row) async {
    return ProductQuantity(
      productId: row[ingredientIdColumn] as int,
      amount:    toDouble(row[amountColumn]),
      unit:      unitFromString(row[unitColumn] as String),
    );
  }
  
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
  void reloadNutritionalValueStream() {
    if (isLoaded()) _nutritionalValuesStreamController.add(_nutritionalValues);
  }
  
  @override
  Future<Iterable<NutritionalValue>> getAllNutritionalValues() async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    var rows = await _db!.query(nutritionalValueTable);
    return rows.map((row) => 
      NutritionalValue(
        row[idColumn] as int,
        row[orderIdColumn] as int,
        row[nameColumn] as String,
        row[unitNameColumn] as String,
        row[showFullNameColumn] == 1,
      )
    ).toList();
  }
  
  @override
  Future<NutritionalValue> getNutritionalValue(int id) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final results = await _db!.query(nutritionalValueTable, where: '$idColumn = ?', whereArgs: [id]);
    if (results.isEmpty) throw NotFoundException();
    if (results.length > 1) throw NotUniqueException();
    
    final row = results.first;
    final name = row[nameColumn] as String;
    final orderId = row[orderIdColumn] as int;
    final unitName = row[unitNameColumn] as String;
    final showFullName = row[showFullNameColumn] == 1;
    final nutritionalValue = NutritionalValue(id, orderId, name, unitName, showFullName);
    
    _nutritionalValuesStreamController.add(_nutritionalValues);
    
    return nutritionalValue;
  }
  
  @override
  Future<NutritionalValue> createNutritionalValue(NutritionalValue nutVal) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final results = await _db!.query(nutritionalValueTable, where: '$nameColumn = ?', whereArgs: [nutVal.name]);
    if (results.isNotEmpty) throw NotUniqueException();
    
    final id = await _db!.insert(nutritionalValueTable, {
      nameColumn: nutVal.name,
      unitNameColumn: nutVal.unit,
    });
    
    _addProductNutrientsForNutritionalValue(nutritionalValueId: id);
    
    _nutritionalValues.add(NutritionalValue(id, nutVal.orderId, nutVal.name, nutVal.unit, nutVal.showFullName));
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
  
  Future<ProductNutrient> _dbRowToProductNutrient(Map<String, Object?> row) async {
    return ProductNutrient(
      nutritionalValueId: row[nutritionalValueIdColumn] as int,
      productId:          row[productIdColumn] as int,
      autoCalc:           row[autoCalcColumn] == 1,
      value:              toDouble(row[valueColumn]),
    );
  }
  
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
}