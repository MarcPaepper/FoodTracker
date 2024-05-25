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
  List<Meal> meals = [];
  bool loaded = false;
  
  final _productsStreamController = BehaviorSubject<List<Product>>();
  final _nutritionalValuesStreamController = BehaviorSubject<List<NutritionalValue>>();
  final _mealsStreamController = BehaviorSubject<List<Meal>>();
  
  @override
  Future<String> open(String dbName) async {
    if (loaded) return Future.value("data already loaded");
    return Future.delayed(
      const Duration(milliseconds: 100), () {
        // create the 7 default nutritional values
        nutValues = defaultNutritionalValues;
        
        // product nutritient values
        List<double> prodNutrientValues = [2000, 50, 360, 90, 70, 20, 6];
        // convert to map with indices as keys
        Map<int, double> prodNutrientValuesMap = {};
        for (int i = 0; i < prodNutrientValues.length; i++) {
          prodNutrientValuesMap[i] = prodNutrientValues[i];
        }
        
        products = [];
        
        // Brühe
        products.add(
          Product(
            id: 0,
            name: "Brühe",
            creationDate: DateTime.now().subtract(const Duration(days: 10)),
            lastEditDate: DateTime.now().subtract(const Duration(days: 0)),
            isTemporary: false,
            defaultUnit: Unit.ml,
            densityConversion: const Conversion(
              amount1: 100,
              unit1: Unit.ml,
              amount2: 95,
              unit2: Unit.g,
              enabled: true,
            ),
            quantityConversion: const Conversion(
              amount1: 1,
              unit1: Unit.quantity,
              amount2: 100,
              unit2: Unit.g,
              enabled: false,
            ),
            quantityName: "x",
            autoCalc: false,
            amountForIngredients: 100,
            ingredientsUnit: Unit.g,
            amountForNutrients: 100,
            nutrientsUnit: Unit.ml,
            ingredients: [],
            nutrients: [
              quickNutri(0, 0, 0), // kcal
              quickNutri(0, 1, 10), // fat
              quickNutri(0, 2, 0), // saturated fat
              quickNutri(0, 3, 0), // carbohydrates
              quickNutri(0, 4, 0), // sugar
              quickNutri(0, 5, 0), // protein
              quickNutri(0, 6, 5), // salt
            ],
          ));
        
        // Fleisch
        products.add(
          Product(
            id: 1,
            name: "Fleisch",
            creationDate: DateTime.now().subtract(const Duration(days: 9)),
            lastEditDate: DateTime.now().subtract(const Duration(days: 1)),
            isTemporary: false,
            defaultUnit: Unit.g,
            densityConversion: const Conversion(
              amount1: 100,
              unit1: Unit.ml,
              amount2: 100,
              unit2: Unit.g,
              enabled: false,
            ),
            quantityConversion: const Conversion(
              amount1: 1,
              unit1: Unit.quantity,
              amount2: 100,
              unit2: Unit.g,
              enabled: false,
            ),
            quantityName: "x",
            autoCalc: false,
            amountForIngredients: 100,
            ingredientsUnit: Unit.g,
            amountForNutrients: 100,
            nutrientsUnit: Unit.g,
            ingredients: [],
            nutrients: [
              quickNutri(1, 0, 0), // kcal
              quickNutri(1, 1, 0), // fat
              quickNutri(1, 2, 0), // saturated fat
              quickNutri(1, 3, 0), // carbohydrates
              quickNutri(1, 4, 0), // sugar
              quickNutri(1, 5, 20), // protein
              quickNutri(1, 6, 0), // salt
            ],
          ));
        
        // Apfel
        products.add(
          Product(
            id: 2,
            name: "Apfel",
            creationDate: DateTime.now().subtract(const Duration(days: 8)),
            lastEditDate: DateTime.now().subtract(const Duration(days: 2)),
            isTemporary: false,
            defaultUnit: Unit.quantity,
            densityConversion: const Conversion(
              amount1: 100,
              unit1: Unit.ml,
              amount2: 100,
              unit2: Unit.g,
              enabled: false,
            ),
            quantityConversion: const Conversion(
              amount1: 1,
              unit1: Unit.quantity,
              amount2: 150,
              unit2: Unit.g,
              enabled: true,
            ),
            quantityName: "x",
            autoCalc: false,
            amountForIngredients: 100,
            ingredientsUnit: Unit.g,
            amountForNutrients: 1,
            nutrientsUnit: Unit.kg,
            ingredients: [],
            nutrients: [
              quickNutri(2, 0, 0), // kcal
              quickNutri(2, 1, 0), // fat
              quickNutri(2, 2, 0), // saturated fat
              quickNutri(2, 3, 200), // carbohydrates
              quickNutri(2, 4, 100), // sugar
              quickNutri(2, 5, 0), // protein
              quickNutri(2, 6, 0), // salt
            ],
          ));
        
        // Ei
        products.add(
          Product(
            id: 3,
            name: "Ei",
            creationDate: DateTime.now().subtract(const Duration(days: 7)),
            lastEditDate: DateTime.now().subtract(const Duration(days: 3)),
            isTemporary: false,
            defaultUnit: Unit.g,
            densityConversion: const Conversion(
              amount1: 100,
              unit1: Unit.ml,
              amount2: 100,
              unit2: Unit.g,
              enabled: false,
            ),
            quantityConversion: const Conversion(
              amount1: 1,
              unit1: Unit.quantity,
              amount2: 50,
              unit2: Unit.g,
              enabled: true,
            ),
            quantityName: "x",
            autoCalc: false,
            amountForIngredients: 100,
            ingredientsUnit: Unit.g,
            amountForNutrients: 100,
            nutrientsUnit: Unit.g,
            ingredients: [],
            nutrients: [
              quickNutri(3, 0, 0), // kcal
              quickNutri(3, 1, 0), // fat
              quickNutri(3, 2, 0), // saturated fat
              quickNutri(3, 3, 0), // carbohydrates
              quickNutri(3, 4, 0), // sugar
              quickNutri(3, 5, 20), // protein
              quickNutri(3, 6, 0), // salt
            ],
          ));
        
        // update map
        for (var product in products) {
          productsMap[product.id] = product;
        }
        _productsStreamController.add(products);
        _nutritionalValuesStreamController.add(nutValues);
        
        loaded = true;
        return "data loaded";
      });
  }
  
  ProductNutrient quickNutri(int prodId, int nutId, double value) => ProductNutrient(
    productId: prodId,
    autoCalc: value == 0,
    value: value,
    nutritionalValueId: nutId
  );
  
  @override
  Future<void> close() {
    _productsStreamController.close();
    _nutritionalValuesStreamController.close();
    _mealsStreamController.close();
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
    final newProduct = Product.copyWith(product, newId: highestId + 1);
    
    newProduct.creationDate = DateTime.now();
    newProduct.lastEditDate = DateTime.now();
    
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
    
    product.lastEditDate = DateTime.now();
    
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
  
  // ----- Meals -----
  
  @override
  Stream<List<Meal>> streamMeals() {
    if (loaded) _mealsStreamController.add(meals);
    return _mealsStreamController.stream;
  }
  
  @override
  void reloadMealStream() => loaded ? _mealsStreamController.add(meals) : {};
  
  @override
  Future<Iterable<Meal>> getAllMeals() {
    return Future.value(meals);
  }
  
  @override
  Future<Meal> getMeal(int id) {
    var list = meals.where((element) => element.id == id);
    if (list.isEmpty) throw NotFoundException();
    if (list.length > 1) throw NotUniqueException();
    return Future.value(list.first);
  }
  
  @override
  Future<Meal> createMeal(Meal meal) {
    int highestId = 0;
    for (final meal in meals) {
      if (meal.id > highestId) highestId = meal.id;
    }
    final newMeal = Meal(
      id: highestId + 1,
      dateTime: meal.dateTime,
      productQuantity: meal.productQuantity,
    );
    meals.add(newMeal);
    _mealsStreamController.add(meals);
    return Future.value(newMeal);
  }
  
  @override
  Future<Meal> updateMeal(Meal meal) {
    int lenPrev = meals.length;
    meals.removeWhere((element) => element.id == meal.id);
    meals.add(meal);
    if (lenPrev - meals.length != 0) {
      throw InvalidUpdateException();
    }
    _mealsStreamController.add(meals);
    return Future.value(meal);
  }
  
  @override
  Future<void> deleteMeal(int id) {
    int lenPrev = meals.length;
    meals.removeWhere((element) => element.id == id);
    if (lenPrev - meals.length != 1) {
      throw InvalidDeletionException();
    }
    _mealsStreamController.add(meals);
    return Future.value();
  }
}