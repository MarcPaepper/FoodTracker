import 'dart:async';

import 'package:food_tracker/constants/tables.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
  
import 'package:food_tracker/services/data/data_exceptions.dart';
import 'package:food_tracker/services/data/data_objects.dart';
import 'package:food_tracker/services/data/data_provider.dart';

import "dart:developer" as devtools show log;

const productTable = "product";
const mealTable = "meal";
const nutrionalValueTable = "nutritional_value";

const idColumn                    = "id";
const nameColumn                  = "name";
const dateColumn                  = "date";
const quantityNameColumn          = "quantity_name";
const densityConversionColumn     = "density_conversion";
const quantityConversionColumn    = "quantity_conversion";
const defaultUnitColumn           = "default_unit";
const autoCalcAmountColumn        = "auto_calc_amount";
const amountForIngredientsColumn  = "amount_for_ingredients";

const unitNameColumn = "unit";

const forceReset = false;

class SqfliteDataProvider implements DataProvider {
  Database? _db;
  
  // cached data
  List<Product> _products = [];
  List<NutrionalValue> _nutrionalValues = [];
  
  final _productsStreamController = StreamController<List<Product>>.broadcast();
  final _nutrionalValuesStreamController = StreamController<List<NutrionalValue>>.broadcast();

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
    };
    try {
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
      
      // cache products
      await _cacheProducts();
      await _cacheNutrionalValues();
      
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
  
  Future<void> _cacheProducts() async {
    _products = await getAllProducts() as List<Product>;
    _productsStreamController.add(_products);
  }
  
  @override
  Stream<List<Product>> streamProducts() => _productsStreamController.stream;
  
  @override
  void reloadProductStream() {
    if (isLoaded()) _productsStreamController.add(_products);
  }
  
  @override
  Future<Iterable<Product>> getAllProducts() async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    var rows = await _db!.query(productTable);
    // same as below but two lines
     var products = <Product>[];
     for (var row in rows) {
       products.add(_dbRowToProduct(row));
     }
     return products;
    //return rows.map((row) => _dbRowToProduct(row)).toList();
  }
  
  @override
  Future<Product> getProduct(int id) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final results = await _db!.query(productTable, where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) throw NotFoundException();
    if (results.length > 1) throw NotUniqueException();
    
    final row = results.first;
    final product = _dbRowToProduct(row);
    
    _productsStreamController.add(_products);
    
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
      autoCalcAmount:        row[autoCalcAmountColumn] == 1,
      amountForIngredients:  row[amountForIngredientsColumn] as double,
    );
  
  @override
  Future<Product> createProduct(Product product) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final results = await _db!.query(productTable, where: 'name = ?', whereArgs: [product.name]);
    if (results.isNotEmpty) throw NotUniqueException();
    
    final id = await _db!.insert(productTable, {
      nameColumn: product.name,
      defaultUnitColumn: unitToString(product.defaultUnit),
      densityConversionColumn: product.densityConversion.toString(),
      quantityConversionColumn: product.quantityConversion.toString(),
      quantityNameColumn: product.quantityName,
      autoCalcAmountColumn: product.autoCalcAmount ? 1 : 0,
      amountForIngredientsColumn: product.amountForIngredients,
    });
    
    var newProduct = Product.copyWithDifferentId(product, id);
    _products.add(newProduct);
    _productsStreamController.add(_products);
    
    return newProduct;
  }
  
  @override
  Future<Product> updateProduct(Product product) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final updatedCount = await _db!.update(productTable, {
      nameColumn: product.name,
      defaultUnitColumn: unitToString(product.defaultUnit),
      densityConversionColumn: product.densityConversion.toString(),
      quantityConversionColumn: product.quantityConversion.toString(),
      quantityNameColumn: product.quantityName,
      autoCalcAmountColumn: product.autoCalcAmount ? 1 : 0,
      amountForIngredientsColumn: product.amountForIngredients,
    }, where: 'id = ?', whereArgs: [product.id]);
    if (updatedCount != 1) throw InvalidUpdateException();
    
    _products.removeWhere((p) => p.id == product.id);
    _products.add(product);
    _productsStreamController.add(_products);
    
    return product;
  }
  
  @override
  Future<void> deleteProduct(int id) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final deletedCount = await _db!.delete(productTable, where: 'id = ?', whereArgs: [id]);
    if (deletedCount != 1) throw InvalidDeletionException();
    
    _products.removeWhere((p) => p.id == id);
    _productsStreamController.add(_products);
  }
  
  @override
  Future<void> deleteProductWithName(String name) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final deletedCount = await _db!.delete(productTable, where: 'name = ?', whereArgs: [name]);
    if (deletedCount != 1) throw InvalidDeletionException();
    
    _products.removeWhere((p) => p.name == name);
    _productsStreamController.add(_products);
  }
  
  // Nutrional values
  
  Future<void> _cacheNutrionalValues() async {
    _nutrionalValues = await getAllNutrionalValues() as List<NutrionalValue>;
    _nutrionalValuesStreamController.add(_nutrionalValues);
  }
  
  @override
  Stream<List<NutrionalValue>> streamNutrionalValues() => _nutrionalValuesStreamController.stream;
  
  @override
  void reloadNutrionalValueStream() {
    if (isLoaded()) _nutrionalValuesStreamController.add(_nutrionalValues);
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
    
    final results = await _db!.query(nutrionalValueTable, where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) throw NotFoundException();
    if (results.length > 1) throw NotUniqueException();
    
    final row = results.first;
    final name = row[nameColumn] as String;
    final unitName = row[unitNameColumn] as String;
    final nutrionalValue = NutrionalValue(id, name, unitName);
    
    _nutrionalValuesStreamController.add(_nutrionalValues);
    
    return nutrionalValue;
  }
  
  @override
  Future<NutrionalValue> createNutrionalValue(NutrionalValue nutVal) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final results = await _db!.query(nutrionalValueTable, where: 'name = ?', whereArgs: [nutVal.name]);
    if (results.isNotEmpty) throw NotUniqueException();
    
    final id = await _db!.insert(nutrionalValueTable, {
      nameColumn: nutVal.name,
      unitNameColumn: nutVal.unit,
    });
    
    _nutrionalValues.add(NutrionalValue(id, nutVal.name, nutVal.unit));
    _nutrionalValuesStreamController.add(_nutrionalValues);
    
    return NutrionalValue(id, nutVal.name, nutVal.unit);
  }
  
  @override
  Future<NutrionalValue> updateNutrionalValue(NutrionalValue nutVal) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final updatedCount = await _db!.update(nutrionalValueTable, {
      nameColumn: nutVal.name,
      unitNameColumn: nutVal.unit,
    }, where: 'id = ?', whereArgs: [nutVal.id]);
    if (updatedCount != 1) throw InvalidUpdateException();
    
    _nutrionalValues.removeWhere((p) => p.id == nutVal.id);
    _nutrionalValues.add(nutVal);
    _nutrionalValuesStreamController.add(_nutrionalValues);
    
    return nutVal;
  }
  
  @override
  Future<void> deleteNutrionalValue(int id) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final deletedCount = await _db!.delete(nutrionalValueTable, where: 'id = ?', whereArgs: [id]);
    if (deletedCount != 1) throw InvalidDeletionException();
    
    _nutrionalValues.removeWhere((p) => p.id == id);
    _nutrionalValuesStreamController.add(_nutrionalValues);
  }
  
  @override
  Future<void> deleteNutrionalValueWithName(String name) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final deletedCount = await _db!.delete(nutrionalValueTable, where: 'name = ?', whereArgs: [name]);
    if (deletedCount != 1) throw InvalidDeletionException();
    
    _nutrionalValues.removeWhere((p) => p.name == name);
    _nutrionalValuesStreamController.add(_nutrionalValues);
  }
}