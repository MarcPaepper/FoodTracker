import 'dart:async';

import 'package:food_tracker/services/data/data_exceptions.dart';

import 'data_provider.dart';
import 'data_objects.dart';

// import "dart:developer" as devtools show log;

class DebugDataProvider implements DataProvider {
  List<Product> products = [];
  List<NutrionalValue> nutValues = [];
  bool loaded = false;
  // StreamController
  final _productsStreamController = StreamController<List<Product>>.broadcast();
  final _nutrionalValuesStreamController = StreamController<List<NutrionalValue>>.broadcast();
  
  @override
  Future<String> open(String dbName) async {
    if (loaded) return Future.value("data already loaded");
    return Future.delayed(
      const Duration(milliseconds: 1000), () {
        products = [
          Product(1, "Example Product 1"),
          Product(2, "Example Product 2"),
          Product(3, "Example Product 3"),
          Product(4, "Example Product 4"),
          Product(5, "Example Product 5"),
          Product(6, "Example Product 6"),
          Product(7, "Example Product 7"),
          Product(8, "Example Product 8"),
          Product(9, "Example Product 9"),
          Product(10, "Example Product 10"),
          Product(11, "Example Product 11"),
          Product(12, "Example Product 12"),
          Product(13, "Example Product 13"),
          Product(14, "Example Product 14"),
          Product(15, "Example Product 15"),
          Product(16, "Example Product 16"),
          Product(17, "Example Product 17"),
          Product(18, "Example Product 18"),
          Product(19, "Example Product 19"),
          Product(20, "Example Product 20"),
        ];
        // create the 7 default nutrional values
        nutValues = [
          NutrionalValue(1, "Calories", "kcal"),
          NutrionalValue(2, "Protein", "g"),
          NutrionalValue(3, "Carbohydrates", "g"),
          NutrionalValue(4, "Fat", "g"),
          NutrionalValue(5, "Saturated Fat", "g"),
          NutrionalValue(6, "Sugar", "g"),
          NutrionalValue(7, "Salt", "g"),
        ];
        _productsStreamController.add(products);
        _nutrionalValuesStreamController.add(nutValues);
        
        loaded = true;
        return "data loaded";
      });
  }
  
  @override
  Future<void> close() {
    _productsStreamController.close();
    _nutrionalValuesStreamController.close();
    return Future.value();
  }
  
  @override
  bool isLoaded() => loaded;
  
  // Products
  
  @override
  Stream<List<Product>> streamProducts() {
    if (loaded) _productsStreamController.add(products);
    return _productsStreamController.stream;
  }
  
  @override
  void reloadProductStream() => loaded ? _productsStreamController.add(products) : {};
  
  @override
  Future<Iterable<Product>> getAllProducts() {
    return Future.value(products);
  }
  
  @override
  Future<Product> getProduct(int id) {
    var list = products.where((element) => element.id == id);
    if (list.isEmpty) throw NotFoundException();
    if (list.length > 1) throw NotUniqueException();
    return Future.value(list.first);
  }
  
  @override
  Future<Product> createProduct(Product product) {
    int highestId = 0;
    for (final product in products) {
      if (product.id > highestId) highestId = product.id;
    }
    final newProduct = Product(highestId + 1, product.name);
    products.add(newProduct);
    _productsStreamController.add(products);
    return Future.value(newProduct);
  }
  
  @override
  Future<void> deleteProduct(int id) {
    int lenPrev = products.length;
    products.removeWhere((element) => element.id == id);
    if (lenPrev - products.length != 1) {
      throw InvalidDeletionException();
    }
    _productsStreamController.add(products);
    return Future.value();
  }
  
  @override
  Future<Product> updateProduct(Product product) {
    int lenPrev = products.length;
    products.removeWhere((element) => element.id == product.id);
    products.add(product);
    if (lenPrev - products.length != 0) {
      throw InvalidUpdateException();
    }
    _productsStreamController.add(products);
    return Future.value(product);
  }
  
  // Nutrional Values
  
  @override
  Stream<List<NutrionalValue>> streamNutrionalValues() {
    if (loaded) _nutrionalValuesStreamController.add(nutValues);
    return _nutrionalValuesStreamController.stream;
  }
  
  @override
  void reloadNutrionalValueStream() => loaded ? _nutrionalValuesStreamController.add(nutValues) : {};
  
  @override
  Future<Iterable<NutrionalValue>> getAllNutrionalValues() {
    return Future.value(nutValues);
  }
  
  @override
  Future<NutrionalValue> getNutrionalValue(int id) {
    var list = nutValues.where((element) => element.id == id);
    if (list.isEmpty) throw NotFoundException();
    if (list.length > 1) throw NotUniqueException();
    return Future.value(list.first);
  }
  
  @override
  Future<NutrionalValue> createNutrionalValue(NutrionalValue nutVal) {
    int highestId = 0;
    for (final nutVal in nutValues) {
      if (nutVal.id > highestId) highestId = nutVal.id;
    }
    final newNutVal = NutrionalValue(highestId + 1, nutVal.name, nutVal.unit);
    nutValues.add(newNutVal);
    _nutrionalValuesStreamController.add(nutValues);
    return Future.value(newNutVal);
  }
  
  @override
  Future<void> deleteNutrionalValue(int id) {
    int lenPrev = nutValues.length;
    nutValues.removeWhere((element) => element.id == id);
    if (lenPrev - nutValues.length != 1) {
      throw InvalidDeletionException();
    }
    _nutrionalValuesStreamController.add(nutValues);
    return Future.value();
  }
  
  @override
  Future<NutrionalValue> updateNutrionalValue(NutrionalValue nutVal) {
    int lenPrev = nutValues.length;
    nutValues.removeWhere((element) => element.id == nutVal.id);
    nutValues.add(nutVal);
    if (lenPrev - nutValues.length != 0) {
      throw InvalidUpdateException();
    }
    _nutrionalValuesStreamController.add(nutValues);
    return Future.value(nutVal);
  }
}