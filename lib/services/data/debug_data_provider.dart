import 'dart:async';

import 'package:food_tracker/services/data/data_exceptions.dart';

import 'data_provider.dart';
import 'data_objects.dart';

import 'package:rxdart/rxdart.dart';

// import "dart:developer" as devtools show log;

class DebugDataProvider implements DataProvider {
  List<Product> products = [];
  List<NutrionalValue> nutValues = [];
  bool loaded = false;
  
  final _productsStreamController = BehaviorSubject<List<Product>>();
  final _nutrionalValuesStreamController = BehaviorSubject<List<NutrionalValue>>();
  
  @override
  Future<String> open(String dbName) async {
    if (loaded) return Future.value("data already loaded");
    return Future.delayed(
      const Duration(milliseconds: 100), () {
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
              ingredients:          List.from(firstProducts),
            );
          
          if (i <= 3) { 
            firstProducts.add(
              ProductQuantity(
                product: product,
                amount: 100,
                unit: Unit.g,
              )
            );
          }
          products.add(product);
        }
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
    final newProduct = Product(
      id:                  highestId + 1,
      name:                product.name,
      defaultUnit:         product.defaultUnit,
      densityConversion:   product.densityConversion,
      quantityConversion:  product.quantityConversion,
      quantityName:        product.quantityName,
      autoCalc:            product.autoCalc,
      amountForIngredients:product.amountForIngredients,
      ingredientsUnit:     product.ingredientsUnit,
      ingredients:         product.ingredients,
    );
    products.add(newProduct);
    _productsStreamController.add(products);
    return Future.value(newProduct);
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
  Future<void> deleteProductWithName(String name) {
    int lenPrev = products.length;
    products.removeWhere((element) => element.name == name);
    if (lenPrev - products.length != 1) {
      throw InvalidDeletionException();
    }
    _productsStreamController.add(products);
    return Future.value();
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
  Future<void> deleteNutrionalValueWithName(String name) {
    int lenPrev = nutValues.length;
    nutValues.removeWhere((element) => element.name == name);
    if (lenPrev - nutValues.length != 1) {
      throw InvalidDeletionException();
    }
    _nutrionalValuesStreamController.add(nutValues);
    return Future.value();
  }
}