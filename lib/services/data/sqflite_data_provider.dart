import 'dart:async';

import 'package:food_tracker/constants/sqlite_tables.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
  
import 'package:food_tracker/services/data/data_exceptions.dart';
import 'package:food_tracker/services/data/data_objects.dart';
import 'package:food_tracker/services/data/data_provider.dart';

const productTable = "product";
const mealTable = "meal";
const nutrionalValueTable = "nutrional_value";

const idColumn = "id";
const nameColumn = "name";
const dateColumn = "date";

const unitNameColumn = "unit";

class SqfliteDataProvider implements DataProvider {
  Database? _db;
  // String _dbName;
  
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
    if (isLoaded()) return Future.value("data already loaded");
    var tables = [createProductTable, createNutrionalValueTable];
    try {
      String dbPath;
      if (kIsWeb) {
        dbPath = "/assets/db";
      } else {
        var docsPath = await getApplicationDocumentsDirectory();
        dbPath = join(docsPath.path, dbName);
      }
      _db = await openDatabase(dbPath);
      
      for (final table in tables) {
        await _db!.execute(table);
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
    return rows.map((row) => 
      Product(
        row[idColumn] as int,
        row[nameColumn] as String,
      )
    ).toList();
  }
  
  @override
  Future<Product> getProduct(int id) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final results = await _db!.query(productTable, where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) throw NotFoundException();
    if (results.length > 1) throw NotUniqueException();
    
    final row = results.first;
    final name = row[nameColumn] as String;
    final product = Product(id, name);
    
    _productsStreamController.add(_products);
    
    return product;
  }
  
  @override
  Future<Product> createProduct(String name) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final results = await _db!.query(productTable, where: 'name = ?', whereArgs: [name]);
    if (results.isNotEmpty) throw NotUniqueException();
    
    final id = await _db!.insert(productTable, {
      nameColumn: name,
    });
    
    _products.add(Product(id, name));
    _productsStreamController.add(_products);
    
    return Product(id, name);
  }
  
  @override
  Future<Product> updateProduct(Product product) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final updatedCount = await _db!.update(productTable, {
      nameColumn: product.name,
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
}