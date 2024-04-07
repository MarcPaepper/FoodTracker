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

const productTable = "product";
const mealTable = "meal";
const nutrionalValueTable = "nutritional_value";
const ingredientTable = "ingredient";

// product table

const idColumn                    = "id";
const nameColumn                  = "name";
const dateColumn                  = "date";
const quantityNameColumn          = "quantity_name";
const densityConversionColumn     = "density_conversion";
const quantityConversionColumn    = "quantity_conversion";
const defaultUnitColumn           = "default_unit";
const autoCalcAmountColumn        = "auto_calc_amount";
const amountForIngredientsColumn  = "amount_for_ingredients";
const ingredientsUnitColumn       = "ingredients_unit";

// nutrional value table

const unitNameColumn              = "unit";

// ingredient table

const ingredientIdColumn          = "ingredient_id";
const isContainedInIdColumn       = "is_contained_in_id";
const amountColumn                = "amount";
const unitColumn                  = "unit";

const forceReset = false;

class SqfliteDataProvider implements DataProvider {
  Database? _db;
  
  // cached data
  List<Product> _products = [];
  List<NutrionalValue> _nutritionalValues = [];
  
  final _productsStreamController = BehaviorSubject<List<Product>>();
  final _nutrionalValuesStreamController = BehaviorSubject<List<NutrionalValue>>();

  SqfliteDataProvider(String dbName);
  
  @override
  bool isLoaded() => _db != null;
  
  @override
  Future<String> open(String dbName) async {
    devtools.log("Opening sqflite database");
    if (isLoaded()) return Future.value("data already loaded");
    var tables = {
      productTable: createProductTable,
      nutrionalValueTable: createNutrionalValueTable,
      ingredientTable: createIngredientTable,
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
        // Check whether the table exists
        var result = await _db!.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='${entry.key}'");
        if (result.isEmpty) {
          devtools.log("Creating table ${entry.key}");
          await _db!.execute(entry.value);
          
          // If table is Nutrional Value, insert the default values
          if (entry.key == nutrionalValueTable) {
            for (var value in defaultNutrionalValues) {
              createNutrionalValue(value);
            }
          }
        }
      }
      
      getAllProducts();
      getAllNutrionalValues();
      
      return "data loaded";
    } on MissingPlatformDirectoryException {
       throw NoDocumentsDirectoryException();
    }
  }
  
  @override
  Future<void> close() async {
    _productsStreamController.close();
    _nutrionalValuesStreamController.close();
    await _db!.close();
    _db = null;
  }
  
  // Products
  
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
    for (var row in productRows) {
      _products.add(_dbRowToProduct(row));
    }
    // add ingredients to products
    var ingredientRows = await _db!.query(ingredientTable);
    for (var row in ingredientRows) {
      var containedInProduct = _products.firstWhere((p) => p.id == row[isContainedInIdColumn]);
      containedInProduct.ingredients.add(await _dbRowToProductQuantity(row));
    }
    
    _productsStreamController.add(_products);
    
    return _products;
  }
  
  @override
  Future<Product> getProduct(int id) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    // check whether cached already
    if (_products.isNotEmpty) return _products.firstWhere((p) => p.id == id, orElse: () => throw NotFoundException());
    
    final productResults = await _db!.query(productTable, where: '$idColumn = ?', whereArgs: [id]);
    if (productResults.isEmpty) throw NotFoundException();
    if (productResults.length > 1) throw NotUniqueException();
    
    final product = _dbRowToProduct(productResults.first);
    
    var ingredientRows = await _db!.query(ingredientTable, where: '$isContainedInIdColumn = ?', whereArgs: [id]);
    product.ingredients = await Future.wait(ingredientRows.map((row) => _dbRowToProductQuantity(row)));
    
    return product;
  }
  
  Product _dbRowToProduct(Map<String, Object?> row) =>
    Product(
      id:                    row[idColumn] as int,
      name:                  row[nameColumn] as String,
      defaultUnit:           unitFromString(row[defaultUnitColumn] as String),
      densityConversion:     Conversion.fromString(row[densityConversionColumn] as String),
      quantityConversion:    Conversion.fromString(row[quantityConversionColumn] as String),
      quantityName:          row[quantityNameColumn] as String,
      autoCalc:        row[autoCalcAmountColumn] == 1,
      amountForIngredients:  toDouble(row[amountForIngredientsColumn]),
      ingredientsUnit:       unitFromString(row[ingredientsUnitColumn] as String),
      ingredients:           [],
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
    });
    
    _addIngredients(product: product, containedInId: id);
    
    var newProduct = Product.copyWithDifferentId(product, id);
    _products.add(newProduct);
    _productsStreamController.add(_products);
    
    return newProduct;
  }
  
  @override
  Future<Product> updateProduct(Product product) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final updatedCount = await _db!.update(productTable, {
      nameColumn:                  product.name,
      defaultUnitColumn:           unitToString(product.defaultUnit),
      densityConversionColumn:     product.densityConversion.toString(),
      quantityConversionColumn:    product.quantityConversion.toString(),
      quantityNameColumn:          product.quantityName,
      autoCalcAmountColumn:        product.autoCalc ? 1 : 0,
      amountForIngredientsColumn:  product.amountForIngredients,
    }, where: '$idColumn = ?', whereArgs: [product.id]);
    if (updatedCount != 1) throw InvalidUpdateException();
    
    await _deleteIngredients(containedInId: product.id);
    await _addIngredients(product: product, containedInId: product.id);
    
    _products.removeWhere((p) => p.id == product.id);
    _products.add(product);
    _productsStreamController.add(_products);
    
    return product;
  }
  
  @override
  Future<void> deleteProduct(int id) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final deletedCount = await _db!.delete(productTable, where: '$idColumn = ?', whereArgs: [id]);
    if (deletedCount != 1) throw InvalidDeletionException();
    
    _deleteIngredients(containedInId: id);
    
    _products.removeWhere((p) => p.id == id);
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
  
  // Ingredients
  
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
  
  // Nutrional values
  
  @override
  Stream<List<NutrionalValue>> streamNutrionalValues() => _nutrionalValuesStreamController.stream;
  
  @override
  void reloadNutrionalValueStream() {
    if (isLoaded()) _nutrionalValuesStreamController.add(_nutritionalValues);
  }
  
  @override
  Future<Iterable<NutrionalValue>> getAllNutrionalValues() async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    var rows = await _db!.query(nutrionalValueTable);
    return rows.map((row) => 
      NutrionalValue(
        row[idColumn] as int,
        row[nameColumn] as String,
        row[unitNameColumn] as String,
      )
    ).toList();
  }
  
  @override
  Future<NutrionalValue> getNutrionalValue(int id) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final results = await _db!.query(nutrionalValueTable, where: '$idColumn = ?', whereArgs: [id]);
    if (results.isEmpty) throw NotFoundException();
    if (results.length > 1) throw NotUniqueException();
    
    final row = results.first;
    final name = row[nameColumn] as String;
    final unitName = row[unitNameColumn] as String;
    final nutrionalValue = NutrionalValue(id, name, unitName);
    
    _nutrionalValuesStreamController.add(_nutritionalValues);
    
    return nutrionalValue;
  }
  
  @override
  Future<NutrionalValue> createNutrionalValue(NutrionalValue nutVal) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final results = await _db!.query(nutrionalValueTable, where: '$nameColumn = ?', whereArgs: [nutVal.name]);
    if (results.isNotEmpty) throw NotUniqueException();
    
    final id = await _db!.insert(nutrionalValueTable, {
      nameColumn: nutVal.name,
      unitNameColumn: nutVal.unit,
    });
    
    _nutritionalValues.add(NutrionalValue(id, nutVal.name, nutVal.unit));
    _nutrionalValuesStreamController.add(_nutritionalValues);
    
    return NutrionalValue(id, nutVal.name, nutVal.unit);
  }
  
  @override
  Future<NutrionalValue> updateNutrionalValue(NutrionalValue nutVal) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final updatedCount = await _db!.update(nutrionalValueTable, {
      nameColumn: nutVal.name,
      unitNameColumn: nutVal.unit,
    }, where: '$idColumn = ?', whereArgs: [nutVal.id]);
    if (updatedCount != 1) throw InvalidUpdateException();
    
    _nutritionalValues.removeWhere((p) => p.id == nutVal.id);
    _nutritionalValues.add(nutVal);
    _nutrionalValuesStreamController.add(_nutritionalValues);
    
    return nutVal;
  }
  
  @override
  Future<void> deleteNutrionalValue(int id) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final deletedCount = await _db!.delete(nutrionalValueTable, where: '$idColumn = ?', whereArgs: [id]);
    if (deletedCount != 1) throw InvalidDeletionException();
    
    _nutritionalValues.removeWhere((p) => p.id == id);
    _nutrionalValuesStreamController.add(_nutritionalValues);
  }
  
  @override
  Future<void> deleteNutrionalValueWithName(String name) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final deletedCount = await _db!.delete(nutrionalValueTable, where: '$nameColumn = ?', whereArgs: [name]);
    if (deletedCount != 1) throw InvalidDeletionException();
    
    _nutritionalValues.removeWhere((p) => p.name == name);
    _nutrionalValuesStreamController.add(_nutritionalValues);
  }
}