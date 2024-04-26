import 'dart:async';

import 'package:food_tracker/constants/tables.dart';
import 'package:food_tracker/services/data/data_exceptions.dart';

import '../../utility/data_logic.dart';
import 'data_provider.dart';
import 'data_objects.dart';

import 'package:rxdart/rxdart.dart';

// import "dart:developer" as devtools show log;

class DebugDataProvider implements DataProvider {
  List<Product> products = [];
  Map<int, Product> productsMap = {};
  List<NutritionalValue> nutValues = [];
  bool loaded = false;
  
  final _productsStreamController = BehaviorSubject<List<Product>>();
  final _nutritionalValuesStreamController = BehaviorSubject<List<NutritionalValue>>();
  
  @override
  Future<String> open(String dbName) async {
    if (loaded) return Future.value("data already loaded");
    return Future.delayed(
      const Duration(milliseconds: 100), () {
        // create the 7 default nutritional values
        nutValues = defaultNutritionalValues;
        
        // product nutritient values
        List<double> prodNutrientValues = [2000, 50, 360, 90, 70, 20, 6];
        
        products = [];
        List<ProductQuantity> firstProducts = [];
        for (int i = 1; i <= 20; i++) {
          var product = 
            Product(
              id: i,
              name:                 "Example $i",
              defaultUnit:          Unit.g,
              densityConversion:    Conversion.fromString("100 ml = 100 g disabled"),
              quantityConversion:   Conversion.fromString("1 x = 100 g disabled"),
              quantityName:         "x",
              autoCalc:             false,
              amountForIngredients: 100,
              ingredientsUnit:      Unit.g,
              amountForNutrients:   100,
              nutrientsUnit:        Unit.g,
              ingredients:          List.from(firstProducts),
              nutrients:            prodNutrientValues.map((v) => ProductNutrient(
                                      productId: i,
                                      autoCalc: i > 3,
                                      value: v,
                                      nutritionalValueId: prodNutrientValues.indexOf(v) + 1
                                    )).toList()
            );
          
          if (i <= 3) { 
            firstProducts.add(
              ProductQuantity(
                productId: product.id,
                amount: 100,
                unit: Unit.g,
              )
            );
          } else {
            // recalculate the nutrient values
            product = calcProductNutrients(product, productsMap);
          }
          products.add(product);
          productsMap[i] = product;
        }
        _productsStreamController.add(products);
        _nutritionalValuesStreamController.add(nutValues);
        
        loaded = true;
        return "data loaded";
      });
  }
  
  @override
  Future<void> close() {
    _productsStreamController.close();
    _nutritionalValuesStreamController.close();
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
    if (!productsMap.containsKey(id)) throw NotFoundException();
    return Future.value(productsMap[id]);
  }
  
  @override
  Future<Product> createProduct(Product product) {
    int highestId = 0;
    for (final product in products) {
      if (product.id > highestId) highestId = product.id;
    }
    final newProduct = Product.copyWithDifferentId(product, highestId + 1);
    
    products.add(newProduct);
    productsMap[newProduct.id] = newProduct;
    _productsStreamController.add(products);
    return Future.value(newProduct);
  }
  
  @override
  Future<Product> updateProduct(Product product, {bool recalc = true}) async {
    if (recalc) {
      var updatedProducts = recalcProductNutrients(product, products, productsMap);
      for (var updatedProduct in updatedProducts) {
        await updateProduct(updatedProduct, recalc: false);
      }
    }
    
    int lenPrev = products.length;
    products.removeWhere((element) => element.id == product.id);
    products.add(product);
    productsMap[product.id] = product;
    if (lenPrev - products.length != 0) {
      throw InvalidUpdateException();
    }
    _productsStreamController.add(products);
    return Future.value(product);
  }
  
  @override
  Future<void> deleteProduct(int id) {
    int lenPrev = products.length;
    products.removeWhere((element) => element.id == id);
    productsMap.remove(id);
    if (lenPrev - products.length != 1) {
      throw InvalidDeletionException();
    }
    _productsStreamController.add(products);
    return Future.value();
  }
  
  @override
  Future<void> deleteProductWithName(String name) {
    int lenPrev = products.length;
    products.removeWhere((element) => element.name == name);
    productsMap.removeWhere((key, value) => value.name == name);
    if (lenPrev - products.length != 1) {
      throw InvalidDeletionException();
    }
    _productsStreamController.add(products);
    return Future.value();
  }
  
  // ----- Nutritional Values -----
  
  @override
  Stream<List<NutritionalValue>> streamNutritionalValues() {
    if (loaded) _nutritionalValuesStreamController.add(nutValues);
    return _nutritionalValuesStreamController.stream;
  }
  
  @override
  void reloadNutritionalValueStream() => loaded ? _nutritionalValuesStreamController.add(nutValues) : {};
  
  @override
  Future<Iterable<NutritionalValue>> getAllNutritionalValues() {
    return Future.value(nutValues);
  }
  
  @override
  Future<NutritionalValue> getNutritionalValue(int id) {
    var list = nutValues.where((element) => element.id == id);
    if (list.isEmpty) throw NotFoundException();
    if (list.length > 1) throw NotUniqueException();
    return Future.value(list.first);
  }
  
  @override
  Future<NutritionalValue> createNutritionalValue(NutritionalValue nutVal) {
    int highestId = 0;
    for (final nutVal in nutValues) {
      if (nutVal.id > highestId) highestId = nutVal.id;
    }
    final newNutVal = NutritionalValue(highestId + 1, highestId + 1, nutVal.name, nutVal.unit, nutVal.showFullName);
    _addProductNutrientsForNutritionalValue(nutritionalValueId: newNutVal.id);
    nutValues.add(newNutVal);
    _nutritionalValuesStreamController.add(nutValues);
    return Future.value(newNutVal);
  }
  
  @override
  Future<NutritionalValue> updateNutritionalValue(NutritionalValue nutVal) {
    int lenPrev = nutValues.length;
    nutValues.removeWhere((element) => element.id == nutVal.id);
    nutValues.add(nutVal);
    if (lenPrev - nutValues.length != 0) {
      throw InvalidUpdateException();
    }
    _nutritionalValuesStreamController.add(nutValues);
    return Future.value(nutVal);
  }
  
  @override
  Future<void> deleteNutritionalValue(int id) {
    int lenPrev = nutValues.length;
    nutValues.removeWhere((element) => element.id == id);
    if (lenPrev - nutValues.length != 1) {
      throw InvalidDeletionException();
    }
    _deleteProductNutrientsForNutritionalValue(nutritionalValueId: id);
    _nutritionalValuesStreamController.add(nutValues);
    return Future.value();
  }
  
  @override
  Future<void> reorderNutritionalValues(Map<int, int> orderMap) {
    for (var entry in orderMap.entries) {
      var nutVal = nutValues.firstWhere((element) => element.id == entry.key);
      nutVal.orderId = entry.value;
    }
    _nutritionalValuesStreamController.add(nutValues);
    return Future.value();
  }
  
  @override
  Future<void> deleteNutritionalValueWithName(String name) {
    int id = nutValues.firstWhere((element) => element.name == name).id;
    return deleteNutritionalValue(id);
  }
  
  // ----- Product Nutrients -----
  
  _addProductNutrientsForNutritionalValue({required int nutritionalValueId}) {
    for (var product in products) {
      product.nutrients.add(
        ProductNutrient(
          productId: product.id,
          autoCalc: true,
          value: 0,
          nutritionalValueId: nutritionalValueId
        )
      );
    }
  }
  
  _deleteProductNutrientsForNutritionalValue({required int nutritionalValueId}) {
    for (var product in products) {
      product.nutrients.removeWhere((element) => element.nutritionalValueId == nutritionalValueId);
    }
  }
}