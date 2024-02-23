import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:food_tracker/constants/data.dart';
import 'package:food_tracker/services/data/data_provider.dart';

import 'data_objects.dart';
import 'debug_data_provider.dart';
import 'sqflite_data_provider.dart';

import "dart:developer" as devtools show log;

const currentMode = kIsWeb ? DebugDataProvider : DebugDataProvider;

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
  
  // Products

  @override Stream<List<Product>> streamProducts()         => _provider.streamProducts();
  @override void reloadProductStream()                     => _provider.reloadProductStream();
  @override Future<Iterable<Product>> getAllProducts()     => _condLoad().then((_) => _provider.getAllProducts());
  @override Future<Product> getProduct(int id)             => _condLoad().then((_) => _provider.getProduct(id));
  @override Future<Product> createProduct(Product product) => _condLoad().then((_) => _provider.createProduct(product));
  @override Future<Product> updateProduct(Product product) => _condLoad().then((_) => _provider.updateProduct(product));
  @override Future<void> deleteProduct(int id)             => _condLoad().then((_) => _provider.deleteProduct(id));
  @override Future<void> deleteProductWithName(String name)=> _condLoad().then((_) => _provider.deleteProductWithName(name));
  
  // Nutrional Values
  
  @override Stream<List<NutrionalValue>> streamNutrionalValues()               => _provider.streamNutrionalValues();
  @override void reloadNutrionalValueStream()                                  => _provider.reloadNutrionalValueStream();
  @override Future<Iterable<NutrionalValue>> getAllNutrionalValues()           => _condLoad().then((_) => _provider.getAllNutrionalValues());
  @override Future<NutrionalValue> getNutrionalValue(int id)                   => _condLoad().then((_) => _provider.getNutrionalValue(id));
  @override Future<NutrionalValue> createNutrionalValue(NutrionalValue nutVal) => _condLoad().then((_) => _provider.createNutrionalValue(nutVal));
  @override Future<NutrionalValue> updateNutrionalValue(NutrionalValue nutVal) => _condLoad().then((_) => _provider.updateNutrionalValue(nutVal));
  @override Future<void> deleteNutrionalValue(int id)                          => _condLoad().then((_) => _provider.deleteNutrionalValue(id));
  @override Future<void> deleteNutrionalValueWithName(String name)             => _condLoad().then((_) => _provider.deleteNutrionalValueWithName(name));
  
  Future _condLoad() {
    if (_provider.isLoaded()) {
      return Future.value();
    } else {
      devtools.log("Loading data");
      return _provider.open(dbName);
    }
  }
}