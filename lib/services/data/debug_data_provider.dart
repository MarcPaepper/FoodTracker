import 'dart:async';

import 'package:food_tracker/services/data/data_exceptions.dart';

import 'data_provider.dart';
import 'data_objects.dart';

// import "dart:developer" as devtools show log;

class DebugDataProvider implements DataProvider {
  List<Product> productsInternal = [];
  // List<NutrionalValue> _nutValues = [];
  bool loaded = false;
  // StreamController
  final _productsStreamController = StreamController<List<Product>>.broadcast();
  
  @override
  Future<String> open(String dbName) async {
    if (loaded) return Future.value("data already loaded");
    return Future.delayed(
      const Duration(milliseconds: 900), () {
        // create the 7 default nutrional values
        // nutValues.add(NutrionalValue(""));
        productsInternal = [
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
        _productsStreamController.add(productsInternal);
        loaded = true;
        return "data loaded";
      });
  }
  
  @override
  Future<void> close() {
    _productsStreamController.close();
    return Future.value();
  }
  
  @override
  bool isLoaded() => loaded;
  
  @override
  Stream<List<Product>> streamProducts() => _productsStreamController.stream;
  
  @override
  Future<Iterable<Product>> getAllProducts() {
    return Future.value(productsInternal);
  }
  
  @override
  Future<Product> getProduct(int id) {
    var list = productsInternal.where((element) => element.id == id);
    if (list.isEmpty) throw NotFoundException();
    if (list.length > 1) throw NotUniqueException();
    return Future.value(list.first);
  }
  
  @override
  Future<Product> getProductByName(String name) {
    var list = productsInternal.where((element) => element.name == name);
    if (list.isEmpty) throw NotFoundException();
    if (list.length > 1) throw NotUniqueException();
    return Future.value(list.first);
  }
  
  @override
  Future<Product> createProduct(String name) {
    int highestId = 0;
    for (final product in productsInternal) {
      if (product.id > highestId) highestId = product.id;
    }
    final newProduct = Product(highestId + 1, name);
    productsInternal.add(newProduct);
    _productsStreamController.add(productsInternal);
    return Future.value(newProduct);
  }
  
  @override
  Future<void> deleteProduct(int id) {
    int lenPrev = productsInternal.length;
    productsInternal.removeWhere((element) => element.id == id);
    if (lenPrev - productsInternal.length != 1) {
      throw InvalidDeletionException();
    }
    _productsStreamController.add(productsInternal);
    return Future.value();
  }
  
  @override
  Future<void> deleteProductWithName(String name) {
    int lenPrev = productsInternal.length;
    productsInternal.removeWhere((element) => element.name == name);
    if (lenPrev - productsInternal.length != 1) {
      throw InvalidDeletionException();
    }
    _productsStreamController.add(productsInternal);
    return Future.value();
  }
  
  @override
  Future<Product> updateProduct(Product product) {
    int lenPrev = productsInternal.length;
    productsInternal.removeWhere((element) => element.id == product.id);
    productsInternal.add(product);
    if (lenPrev - productsInternal.length != 0) {
      throw InvalidUpdateException();
    }
    _productsStreamController.add(productsInternal);
    return Future.value(product);
  }
}