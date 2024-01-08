import 'package:food_tracker/services/data/data_provider.dart';

import 'data_objects.dart';
import 'debug_data_provider.dart';
import 'sqflite_data_provider.dart';

class DataService implements DataProvider {
  final DataProvider _provider;
  const DataService(this._provider);
  // cache data service
  static final Map<String, DataService> _cache = {};
  
  factory DataService.debug() {
    if (!_cache.containsKey("debug")) {
      _cache["debug"] = DataService(DebugDataProvider());
    }
    return _cache["debug"]!;
  }
  
  factory DataService.sqflite() {
    if (!_cache.containsKey("sqflite")) {
      _cache["sqflite"] = DataService(SqfliteDataProvider("test"));
    }
    return _cache["sqflite"]!;
  }

  @override
  Future<String> open(String dbName) => _provider.open(dbName);
  
  @override
  Future<void> close() => _provider.close();
  
  @override
  bool isLoaded() => _provider.isLoaded();
  
  @override
  Stream<List<Product>> get products => _provider.products;

  @override
  Future<Iterable<Product>> getAllProducts() => _provider.getAllProducts();
  
  @override
  Future<Product> getProduct(int id) => _provider.getProduct(id);
  
  @override
  Future<Product> getProductByName(String name) => _provider.getProductByName(name);
  
  @override
  Future<Product> createProduct(String name) => _provider.createProduct(name);
  
  @override
  Future<Product> updateProduct(Product product) => _provider.updateProduct(product);
  
  @override
  Future<void> deleteProduct(int id) => _provider.deleteProduct(id);
  
  @override
  Future<void> deleteProductWithName(String name) => _provider.deleteProductWithName(name);
}