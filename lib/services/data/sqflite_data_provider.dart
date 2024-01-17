import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:path_provider/path_provider.dart';
  
import 'package:food_tracker/services/data/data_exceptions.dart';
import 'package:food_tracker/services/data/data_objects.dart';
import 'package:food_tracker/services/data/data_provider.dart';

const productTable = "product";
const mealTable = "meal";

const idColumn = "id";
const nameColumn = "name";
const dateColumn = "date";
const productIdColumn = "product_id";

const createProductTable = '''
CREATE TABLE IF NOT EXISTS "product" (
	"id"	INTEGER NOT NULL UNIQUE,
	"name"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id" AUTOINCREMENT)
);
''';

class SqfliteDataProvider implements DataProvider {
  Database? _db;
  String _dbName;
  
  // cached data
  List<Product> _products = [];
  
  final _productsStreamController = StreamController<List<Product>>.broadcast();

  SqfliteDataProvider(this._dbName);
  
  Future<void> _cacheProducts() async {
    _products = await getAllProducts() as List<Product>;
    _productsStreamController.add(_products);
  }
  
  @override
  bool isLoaded() => _db != null;
  
  @override
  Future<String> open(String dbName) async {
    _dbName = dbName;
    if (isLoaded()) throw DbAlreadyOpenException();
    var tables = [createProductTable];
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      _db = await openDatabase(dbPath);
      
      for (final table in tables) {
        await _db!.execute(table);
      }
      
      // cache products
      await _cacheProducts();
      
      return "data loaded";
    } on MissingPlatformDirectoryException {
       throw NoDocumentsDirectoryException();
    }
  }
  
  @override
  Future<void> close() async {
    await _db!.close();
    _db = null;
  }
  
  @override
  Stream<List<Product>> streamProducts() => _productsStreamController.stream;
  
  @override
  Future<Iterable<Product>> getAllProducts() async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    var rows = await _db!.query(productTable);

    return rows.map((row) => 
      Product(
        row[idColumn] as int,
        row[nameColumn] as String,
      )
    );
  }
  
  @override
  Future<Product> getProduct(int id) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    // retrieve
    final results = await _db!.query(productTable, where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) throw NotFoundException();
    if (results.length > 1) throw NotUniqueException();
    
    // extract
    final row = results.first;
    final name = row[nameColumn] as String;
    final product = Product(id, name);
    
    // update stream
    _products.removeWhere((p) => p.id == id);
    _products.add(product);
    _productsStreamController.add(_products);
    
    return product;
  }
  
  @override
  Future<Product> getProductByName(String name) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    final results = await _db!.query(productTable, where: 'name = ?', whereArgs: [name]);
    if (results.isEmpty) throw NotFoundException();
    if (results.length > 1) throw NotUniqueException();
    
    final row = results.first;
    final id = row[idColumn] as int;
    
    return Product(id, name);
  }
  
  @override
  Future<Product> createProduct(String name) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    // check if product already exists
    final results = await _db!.query(productTable, where: 'name = ?', whereArgs: [name]);
    if (results.isNotEmpty) throw NotUniqueException();
    
    // insert
    final id = await _db!.insert(productTable, {
      nameColumn: name,
    });
    
    // update stream
    _products.add(Product(id, name));
    _productsStreamController.add(_products);
    
    return Product(id, name);
  }
  
  @override
  Future<Product> updateProduct(Product product) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    // update product
    final updatedCount = await _db!.update(productTable, {
      nameColumn: product.name,
    }, where: 'id = ?', whereArgs: [product.id]);
    
    // check if update was successful
    if (updatedCount != 1) {
      throw InvalidUpdateException();
    }
    
    // update stream
    _products.removeWhere((p) => p.id == product.id);
    _products.add(product);
    _productsStreamController.add(_products);
    
    return product;
  }
  
  @override
  Future<void> deleteProduct(int id) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    // delete product
    final deletedCount = await _db!.delete(productTable, where: 'id = ?', whereArgs: [id]);
    
    // check if deletion was successful
    if (deletedCount != 1) {
      throw InvalidDeletionException();
    }
    
    // update stream
    _products.removeWhere((p) => p.id == id);
    _productsStreamController.add(_products);
  }
  
  @override
  Future<void> deleteProductWithName(String name) async {
    if (!isLoaded()) throw DataNotLoadedException();
    
    // delete product
    final deletedCount = await _db!.delete(productTable, where: 'name = ?', whereArgs: [name]);
    
    // check if deletion was successful
    if (deletedCount != 1) {
      throw InvalidDeletionException();
    }
    
    // update stream
    _products.removeWhere((p) => p.name == name);
    _productsStreamController.add(_products);
  }
}


// class DatabaseProduct {
//   final int id;
//   final String name;

//   const DatabaseProduct({
//     required this.id,
//     required this.name,
//   });

//   DatabaseProduct.fromRow(Map<String, Object?> map)
//       : id = map[idColumn] as int,
//         name = map[nameColumn] as String;

//   @override
//   String toString() => "Product, ID $id, name $name";

//   @override
//   bool operator ==(covariant DatabaseProduct other) => id == other.id;

//   @override
//   int get hashCode => id.hashCode;
// }

// class DatabaseMeal {
//   final int id;
//   final String date;
//   final int productId;

//   const DatabaseMeal({
//     required this.id,
//     required this.date,
//     required this.productId,
//   });
  
//   DatabaseMeal.fromRow(Map<String, Object?> map)
//       : id = map[idColumn] as int,
//         date = map[dateColumn] as String,
//         productId = map[productIdColumn] as int;
  
//   @override
//   String toString() => "Meal, ID $id, date $date, product ID $productId";
  
//   @override
//   bool operator ==(covariant DatabaseMeal other) => id == other.id;
  
//   @override
//   int get hashCode => id.hashCode;
// }