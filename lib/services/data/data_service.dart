import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:food_tracker/constants/data.dart';
import 'package:food_tracker/services/data/data_provider.dart';

import 'data_objects.dart';
import 'debug_data_provider.dart';
import 'sqflite_data_provider.dart';

import "dart:developer" as devtools show log;

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
  
  // General
  
  @override Future<String> open(String dbName) => _provider.open(dbName);
  @override Future<void> close()               => _provider.close();
  @override bool isLoaded()                    => _provider.isLoaded();
  @override Future<void> reset(String dbName)  => _provider.reset(dbName);
  @override Future<void> cleanUp()             => _provider.cleanUp();
  
  // Products

  @override Stream<List<Product>> streamProducts()          => _provider.streamProducts();
  @override void reloadProductStream()                      => _provider.reloadProductStream();
  @override Future<Iterable<Product>> getAllProducts()      => _condLoad().then((_) => _provider.getAllProducts());
  @override Future<Product> getProduct(int id)              => _condLoad().then((_) => _provider.getProduct(id));
  @override Future<Product> createProduct(Product product)  => _condLoad().then((_) => _provider.createProduct(product));
  @override Future<Product> updateProduct(Product product)  => _condLoad().then((_) => _provider.updateProduct(product));
  @override Future<void> deleteProduct(int id)              => _condLoad().then((_) => _provider.deleteProduct(id));
  @override Future<void> deleteProductWithName(String name) => _condLoad().then((_) => _provider.deleteProductWithName(name));
  
  // Nutritional Values
  
  @override Stream<List<NutritionalValue>> streamNutritionalValues()                 => _provider.streamNutritionalValues();
  @override void reloadNutritionalValueStream()                                      => _provider.reloadNutritionalValueStream();
  @override Future<Iterable<NutritionalValue>> getAllNutritionalValues()             => _condLoad().then((_) => _provider.getAllNutritionalValues());
  @override Future<NutritionalValue> getNutritionalValue(int id)                     => _condLoad().then((_) => _provider.getNutritionalValue(id));
  @override Future<NutritionalValue> createNutritionalValue(NutritionalValue nutVal) => _condLoad().then((_) => _provider.createNutritionalValue(nutVal));
  @override Future<NutritionalValue> updateNutritionalValue(NutritionalValue nutVal) => _condLoad().then((_) => _provider.updateNutritionalValue(nutVal));
  @override Future<void> reorderNutritionalValues(Map<int, int> orderMap)            => _condLoad().then((_) => _provider.reorderNutritionalValues(orderMap));
  @override Future<void> deleteNutritionalValue(int id)                              => _condLoad().then((_) => _provider.deleteNutritionalValue(id));
  @override Future<void> deleteNutritionalValueWithName(String name)                 => _condLoad().then((_) => _provider.deleteNutritionalValueWithName(name));
  
  // Meals
  
  @override Stream<List<Meal>> streamMeals()     => _provider.streamMeals();
  @override void reloadMealStream()              => _provider.reloadMealStream();
  @override Future<Iterable<Meal>> getAllMeals() => _condLoad().then((_) => _provider.getAllMeals());
  @override Future<Meal> getMeal(int id)         => _condLoad().then((_) => _provider.getMeal(id));
  @override Future<Meal> createMeal(Meal meal)   => _condLoad().then((_) => _provider.createMeal(meal));
  @override Future<Meal> updateMeal(Meal meal)   => _condLoad().then((_) => _provider.updateMeal(meal));
  @override Future<void> deleteMeal(int id)      => _condLoad().then((_) => _provider.deleteMeal(id));
  
  // Targets
  
  @override Stream<List<Target>> streamTargets()                     => _provider.streamTargets();
  @override void reloadTargetStream()                                => _provider.reloadTargetStream();
  @override Future<Iterable<Target>> getAllTargets()                 => _condLoad().then((_) => _provider.getAllTargets());
  @override Future<Target> getTarget(Type targetType, int targetId)  => _condLoad().then((_) => _provider.getTarget(targetType, targetId));
  @override Future<Target> createTarget(Target target)               => _condLoad().then((_) => _provider.createTarget(target));
  @override Future<Target> updateTarget(Target target)               => _condLoad().then((_) => _provider.updateTarget(target));
  @override Future<void> deleteTarget(Type targetType, int targetId) => _condLoad().then((_) => _provider.deleteTarget(targetType, targetId));
  
  Future _condLoad() {
    if (_provider.isLoaded()) {
      return Future.value();
    } else {
      devtools.log("Loading data");
      return _provider.open(dbName);
    }
  }
}