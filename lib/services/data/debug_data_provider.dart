import 'dart:async';

import 'package:food_tracker/services/data/data_exceptions.dart';

import 'data_provider.dart';
import 'data_objects.dart';

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
  Stream<List<Product>> get products => _productsStreamController.stream;
  
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
    return Future.value(newProduct);
  }
  
  @override
  Future<void> deleteProduct(int id) {
    int lenPrev = productsInternal.length;
    productsInternal.removeWhere((element) => element.id == id);
    if (lenPrev - productsInternal.length != 1) {
      throw InvalidDeletionException();
    }
    return Future.value();
  }
  
  @override
  Future<void> deleteProductWithName(String name) {
    int lenPrev = productsInternal.length;
    productsInternal.removeWhere((element) => element.name == name);
    if (lenPrev - productsInternal.length != 1) {
      throw InvalidDeletionException();
    }
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
    return Future.value(product);
  }
}