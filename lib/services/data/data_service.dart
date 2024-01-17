import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:food_tracker/constants/data.dart';
import 'package:food_tracker/services/data/data_provider.dart';

import 'data_objects.dart';
import 'debug_data_provider.dart';
import 'sqflite_data_provider.dart';

const currentMode = kIsWeb ? DebugDataProvider : SqfliteDataProvider;

class DataService implements DataProvider {
  final DataProvider _provider;
  const DataService(this._provider);
  static final Map<String, DataService> _cache = {};
  
  factory DataService.current() {
    switch (currentMode) {
      case DebugDataProvider:
        return DataService.debug();
      case SqfliteDataProvider:
        return DataService.sqflite();
      default:
        throw Exception("Unknown data provider");
    }
  }
  
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
Stream<List<Product>> streamProducts() => _provider.streamProducts();

@override
Future<Iterable<Product>> getAllProducts() {
  if (!_provider.isLoaded()) {
    return _provider.open(dbName).then((value) => _provider.getAllProducts());
  }
  return _provider.getAllProducts();
}

@override
Future<Product> getProduct(int id) {
  if (!_provider.isLoaded()) {
    return _provider.open(dbName).then((value) => _provider.getProduct(id));
  }
  return _provider.getProduct(id);
}

@override
Future<Product> getProductByName(String name) {
  if (!_provider.isLoaded()) {
    return _provider.open(dbName).then((value) => _provider.getProductByName(name));
  }
  return _provider.getProductByName(name);
}

@override
Future<Product> createProduct(String name) {
  if (!_provider.isLoaded()) {
    return _provider.open(dbName).then((value) => _provider.createProduct(name));
  }
  return _provider.createProduct(name);
}

@override
Future<Product> updateProduct(Product product) {
  if (!_provider.isLoaded()) {
    return _provider.open(dbName).then((value) => _provider.updateProduct(product));
  }
  return _provider.updateProduct(product);
}

@override
Future<void> deleteProduct(int id) {
  if (!_provider.isLoaded()) {
    return _provider.open(dbName).then((value) => _provider.deleteProduct(id));
  }
  return _provider.deleteProduct(id);
}

@override
Future<void> deleteProductWithName(String name) {
  if (!_provider.isLoaded()) {
    return _provider.open(dbName).then((value) => _provider.deleteProductWithName(name));
  }
  return _provider.deleteProductWithName(name);
}
}