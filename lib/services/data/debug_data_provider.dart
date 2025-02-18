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
  List<Target> targets = [];
  bool loaded = false;
  
  final _productsStreamController = BehaviorSubject<List<Product>>();
  final _nutritionalValuesStreamController = BehaviorSubject<List<NutritionalValue>>();
  final _mealsStreamController = BehaviorSubject<List<Meal>>();
  final _targetsStreamController = BehaviorSubject<List<Target>>();
  
  @override
  bool isLoaded() => loaded;
  
  @override
  Future<String> open(String dbName) async {
    if (loaded) return Future.value("data already loaded");
    return Future.delayed(
      const Duration(milliseconds: 100), () {
        // create the 7 default nutritional values
        nutValues = defaultNutritionalValues;
        
        // product nutritient values
        List<double> targetValues = [2000, 50, 20, 260, 90, 50, 6];
        for (var i = 0; i < targetValues.length; i++) {
          targets.add(
            Target(
              isPrimary: true,
              trackedType: NutritionalValue,
              trackedId: i,
              amount: targetValues[i],
              unit: null,
              orderId: i,
            )
          );
        }
        
        products = getDebugProducts();
        
        // update map
        for (var product in products) {
          productsMap[product.id] = product;
        }
        
        // update all products
        for (var product in products) {
          updateProduct(product, recalc: true);
        }
        
        // add meals
        
        const diffDur = Duration();//days: 1);
        
        meals = getDebugMeals(diffDur);
        
        // duplicate meals with rising datetime differences
        List<Meal> origMeals = List.from(meals);
        for (int i = 1; i < origMeals.length; i++) {
          for (var meal in origMeals) {
            meals.add(
              meal.copyWith(
                newId: meals.length,
                newDateTime: meal.dateTime.subtract((diffDur * origMeals.length + const Duration(days: 1)) * i),
              )
            );
          }
        }
        // sort by date
        meals.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        
        _mealsStreamController.add(meals);
        _productsStreamController.add(products);
        _nutritionalValuesStreamController.add(nutValues);
        _targetsStreamController.add(targets);
        
        loaded = true;
        return "data loaded";
      });
  }
  
  ProductNutrient quickNutri(int prodId, int nutId, double value) => ProductNutrient(
    productId: prodId,
    autoCalc: value == 0,
    value: value < 0.001 ? 0 : value,
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
  Future<String> reload() async {
    if (!loaded) return Future.value("data not loaded");
    products = List.from(products);
    nutValues = List.from(nutValues);
    meals = List.from(meals);
    targets = List.from(targets);
    _productsStreamController.add(products);
    _nutritionalValuesStreamController.add(nutValues);
    _mealsStreamController.add(meals);
    _targetsStreamController.add(targets);
    return Future.value("data reloaded");
  }
  
  @override
  Future<void> reset(String dbName) async {
    loaded = false;
    products = [];
    productsMap = {};
    nutValues = [];
    meals = [];
    _productsStreamController.add(products);
    _nutritionalValuesStreamController.add(nutValues);
    _mealsStreamController.add(meals);
  }
  
  @override
  Future<void> cleanUp() async {
    // remove all meals with invalid product ids
    int invalidProductCount = 0;
    for (var meal in meals) {
      var productId = meal.productQuantity.productId;
      if (!productsMap.containsKey(productId)) {
        meals.removeWhere((m) => m.id == meal.id);
        invalidProductCount++;
      }
    }
    if (invalidProductCount > 0) _mealsStreamController.add(meals);
  }
  
  // ----- Products -----
  
  @override
  Stream<List<Product>> streamProducts() {
    return _productsStreamController.stream;
  }
  
  @override
  void reloadProductStream() => loaded ? _productsStreamController.add(products) : {};
  
  @override
  Future<Iterable<Product>> getAllProducts({bool cache = true}) {
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
    final newProduct = product.copyWith(newId: highestId + 1);
    
    newProduct.creationDate = DateTime.now();
    newProduct.lastEditDate = DateTime.now();
    
    products.add(newProduct);
    productsMap[newProduct.id] = newProduct;
    _productsStreamController.add(products);
    return Future.value(newProduct);
  }
  
  @override
  Future<List<Product>> createProducts(List<Product> products) async {
    List<Product> newProducts = [];
    for (var product in products) {
      newProducts.add(await createProduct(product));
    }
    return Future.value(newProducts);
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
  Future<List<Product>> updateProducts(List<Product> products) async {
    List<Product> updatedProducts = [];
    for (var product in products) {
      updatedProducts.add(await updateProduct(product, recalc: false));
    }
    return Future.value(updatedProducts);
  }
  
  @override
  Future<void> deleteProduct(int id) {
    int lenPrev = products.length;
    products.removeWhere((element) => element.id == id);
    productsMap.remove(id);
    meals.removeWhere((element) => element.productQuantity.productId == id);
    if (lenPrev - products.length != 1) {
      throw InvalidDeletionException();
    }
    _mealsStreamController.add(meals);
    _productsStreamController.add(products);
    return Future.value();
  }
  
  @override
  Future<void> deleteProductWithName(String name) {
    int id = products.firstWhere((element) => element.name == name).id;
    return deleteProduct(id);
  }
  
  // ----- Nutritional Values -----
  
  @override
  Stream<List<NutritionalValue>> streamNutritionalValues() {
    return _nutritionalValuesStreamController.stream;
  }
  
  @override
  void reloadNutritionalValueStream() => loaded ? _nutritionalValuesStreamController.add(nutValues) : {};
  
  @override
  Future<Iterable<NutritionalValue>> getAllNutritionalValues({bool cache = true}) {
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
    final newNutVal = nutVal.copyWith(newId: highestId + 1, newOrderId: highestId + 1);
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
    return _mealsStreamController.stream;
  }
  
  @override
  void reloadMealStream() => loaded ? _mealsStreamController.add(meals) : {};
  
  @override
  Future<Iterable<Meal>> getAllMeals({bool cache = true}) {
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
    final newMeal = meal.copyWith(newId: highestId + 1);
    meals.insert(findInsertIndex(meals, newMeal), newMeal);
    _mealsStreamController.add(meals);
    return Future.value(newMeal);
  }
  
  @override
  Future<List<Meal>> createMeals(List<Meal> meals) async {
    List<Meal> newMeals = [];
    for (var meal in meals) {
      newMeals.add(await createMeal(meal));
    }
    return Future.value(newMeals);
  }
  
  @override
  Future<Meal> updateMeal(Meal meal) {
    int lenPrev = meals.length;
    meals.removeWhere((element) => element.id == meal.id);
    meals.insert(findInsertIndex(meals, meal), meal);
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
  
  // ----- Targets -----
  
  @override
  Stream<List<Target>> streamTargets() {
    return _targetsStreamController.stream;
  }
  
  @override
  void reloadTargetStream() => loaded ? _targetsStreamController.add(targets) : {};
  
  @override
  Future<Iterable<Target>> getAllTargets({bool cache = true}) {
    return Future.value(targets);
  }
  
  @override
  Future<Target> getTarget(Type targetType, int targetId) {
    var list = targets.where((element) => element.trackedType == targetType && element.trackedId == targetId);
    if (list.isEmpty) throw NotFoundException();
    if (list.length > 1) throw NotUniqueException();
    return Future.value(list.first);
  }
  
  @override
  Future<Target> createTarget(Target target) {
    int highestOrderId = 0;
    for (final target in targets) {
      if (target.orderId > highestOrderId) highestOrderId = target.orderId;
    }
    final newTarget = target.copyWith(newOrderId: highestOrderId + 1);
    targets.add(newTarget);
    _targetsStreamController.add(targets);
    return Future.value(newTarget);
  }
  
  @override
  Future<Target> updateTarget(Type origType, int origTrackedId, Target target) {
    int lenPrev = targets.length;
    targets.removeWhere((element) => element.trackedType == origType && element.trackedId == origTrackedId);
    targets.add(target);
    if (lenPrev - targets.length != 0) {
      throw InvalidUpdateException();
    }
    _targetsStreamController.add(targets);
    return Future.value(target);
  }
  
  @override
  Future<void> reorderTargets(Map<(Type, int), int> orderMap) {
    for (var entry in orderMap.entries) {
      var target = targets.firstWhere((element) => element.trackedType == entry.key.$1 && element.trackedId == entry.key.$2);
      target.orderId = entry.value;
    }
    _targetsStreamController.add(targets);
    return Future.value();
  }
  
  @override
  Future<void> deleteTarget(Type targetType, int targetId) {
    int lenPrev = targets.length;
    targets.removeWhere((element) => element.trackedType == targetType && element.trackedId == targetId);
    if (lenPrev - targets.length != 1) {
      throw InvalidDeletionException();
    }
    _targetsStreamController.add(targets);
    return Future.value();
  }
  
  // ----- Debug Data -----
  
  
  List<Product> getDebugProducts() {
    List<Product> debugProducts = [];
    
    // Brühe 0
    debugProducts.add(
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
    
    // Fleisch 2
    debugProducts.add(
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
          quickNutri(1, 0, 100), // kcal
          quickNutri(1, 1, 10), // fat
          quickNutri(1, 2, 3), // saturated fat
          quickNutri(1, 3, 0), // carbohydrates
          quickNutri(1, 4, 0), // sugar
          quickNutri(1, 5, 20), // protein
          quickNutri(1, 6, 0), // salt
        ],
      ));
    
    // Apfel 2
    debugProducts.add(
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
    
    // Ei 3
    debugProducts.add(
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

    // Milch 4
    debugProducts.add(
      Product(
        id: 4,
        name: "Milch",
        creationDate: DateTime.now().subtract(const Duration(days: 10)),
        lastEditDate: DateTime.now().subtract(const Duration(days: 2)),
        isTemporary: true,
        temporaryBeginning: DateTime.now().subtract(const Duration(days: 1)),
        temporaryEnd: DateTime.now().subtract(const Duration(days: 5)),
        defaultUnit: Unit.ml,
        densityConversion: const Conversion(
          amount1: 100,
          unit1: Unit.ml,
          amount2: 103,
          unit2: Unit.g,
          enabled: true,
        ),
        quantityConversion: const Conversion(
          amount1: 1,
          unit1: Unit.quantity,
          amount2: 100,
          unit2: Unit.ml,
          enabled: false,
        ),
        quantityName: "x",
        autoCalc: false,
        amountForIngredients: 100,
        ingredientsUnit: Unit.ml,
        amountForNutrients: 100,
        nutrientsUnit: Unit.ml,
        ingredients: [],
        nutrients: [
          quickNutri(4, 0, 64), // kcal
          quickNutri(4, 1, 3.5), // fat
          quickNutri(4, 2, 2.3), // saturated fat
          quickNutri(4, 3, 5), // carbohydrates
          quickNutri(4, 4, 5), // sugar
          quickNutri(4, 5, 3.5), // protein
          quickNutri(4, 6, 0.1), // salt
        ],
      ));

    // Käse 5
    debugProducts.add(
      Product(
        id: 5,
        name: "Käse",
        creationDate: DateTime.now().subtract(const Duration(days: 10)),
        lastEditDate: DateTime.now().subtract(const Duration(days: 2)),
        isTemporary: true,
        temporaryBeginning: DateTime.now().subtract(const Duration(days: 1)),
        temporaryEnd: DateTime.now().add(const Duration(days: 5)),
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
          enabled: true,
        ),
        quantityName: "x",
        autoCalc: false,
        amountForIngredients: 1,
        ingredientsUnit: Unit.kg,
        amountForNutrients: 100,
        nutrientsUnit: Unit.g,
        ingredients: [
          ProductQuantity(
            productId: 4,
            amount: 14.285,
            unit: Unit.ml,
          )
        ],
        nutrients: [
          quickNutri(4, 0, 330), // kcal
          quickNutri(4, 1, 25), // fat
          quickNutri(4, 2, 17.3), // saturated fat
          quickNutri(4, 3, 0.0001), // carbohydrates
          quickNutri(4, 4, 0.0001), // sugar
          quickNutri(4, 5, 25), // protein
          quickNutri(4, 6, 1.8), // salt
        ],
      ));
    
    // Mehl 6
    debugProducts.add(
      Product(
        id: 6,
        name: "Mehl",
        creationDate: DateTime.now().subtract(const Duration(days: 10)),
        lastEditDate: DateTime.now().subtract(const Duration(days: 2)),
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
          quickNutri(6, 0, 0), // kcal
          quickNutri(6, 1, 0), // fat
          quickNutri(6, 2, 0), // saturated fat
          quickNutri(6, 3, 70), // carbohydrates
          quickNutri(6, 4, 0), // sugar
          quickNutri(6, 5, 10), // protein
          quickNutri(6, 6, 0), // salt
        ],
      ));
    
    // Zucker 7
    debugProducts.add(
      Product(
        id: 7,
        name: "Zucker",
        creationDate: DateTime.now().subtract(const Duration(days: 10)),
        lastEditDate: DateTime.now().subtract(const Duration(days: 2)),
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
          quickNutri(7, 0, 400), // kcal
          quickNutri(7, 1, 0), // fat
          quickNutri(7, 2, 0), // saturated fat
          quickNutri(7, 3, 100), // carbohydrates
          quickNutri(7, 4, 100), // sugar
          quickNutri(7, 5, 0), // protein
          quickNutri(7, 6, 0), // salt
        ],
      ));
    
    // Apfelkuchen 8 
    debugProducts.add(
      Product(
        id: 8,
        name: "Apfelkuchen",
        creationDate: DateTime.now().subtract(const Duration(days: 10)),
        lastEditDate: DateTime.now().subtract(const Duration(days: 2)),
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
        autoCalc: true,
        amountForIngredients: 450,
        ingredientsUnit: Unit.g,
        amountForNutrients: 100,
        nutrientsUnit: Unit.g,
        ingredients: [
          ProductQuantity(
            productId: 2,
            amount: 100,
            unit: Unit.g,
          ),
          ProductQuantity(
            productId: 3,
            amount: 1,
            unit: Unit.quantity,
          ),
          ProductQuantity(
            productId: 4,
            amount: 100,
            unit: Unit.ml
          ),
          ProductQuantity(
            productId: 6,
            amount: 100,
            unit: Unit.g,
          ),
          ProductQuantity(
            productId: 7,
            amount: 100,
            unit: Unit.g,
          ),
        ],
        nutrients: [
          quickNutri(8, 0, 0), // kcal
          quickNutri(8, 1, 0), // fat
          quickNutri(8, 2, 0), // saturated fat
          quickNutri(8, 3, 0), // carbohydrates
          quickNutri(8, 4, 0), // sugar
          quickNutri(8, 5, 0), // protein
          quickNutri(8, 6, 0.5), // salt
        ],
      ));
    
    // Brot 9
    debugProducts.add(
      Product(
        id: 9,
        name: "Brot",
        creationDate: DateTime.now().subtract(const Duration(days: 6)),
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
          amount2: 500,
          unit2: Unit.g,
          enabled: true,
        ),
        quantityName: "x",
        autoCalc: false,
        amountForIngredients: 100,
        ingredientsUnit: Unit.g,
        amountForNutrients: 100,
        nutrientsUnit: Unit.g,
        ingredients: [
          ProductQuantity(
            productId: 6,
            amount: 100,
            unit: Unit.g,
          ),
          ProductQuantity(
            productId: 7,
            amount: 100,
            unit: Unit.g,
          ),
        ],
        nutrients: [
          quickNutri(9, 0, 250), // kcal
          quickNutri(9, 1, 3.5), // fat
          quickNutri(9, 2, 0.5), // saturated fat
          quickNutri(9, 3, 50), // carbohydrates
          quickNutri(9, 4, 2), // sugar
          quickNutri(9, 5, 8), // protein
          quickNutri(9, 6, 1.2), // salt
        ],
      ));
    
    // Banane 10
    debugProducts.add(
      Product(
        id: 10,
        name: "Banane",
        creationDate: DateTime.now().subtract(const Duration(days: 5)),
        lastEditDate: DateTime.now().subtract(const Duration(days: 1)),
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
          amount2: 120,
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
          quickNutri(10, 0, 89), // kcal
          quickNutri(10, 1, 0.3), // fat
          quickNutri(10, 2, 0.1), // saturated fat
          quickNutri(10, 3, 23), // carbohydrates
          quickNutri(10, 4, 12), // sugar
          quickNutri(10, 5, 1.1), // protein
          quickNutri(10, 6, 0), // salt
        ],
      ));
    
    // Kartoffel 11
    debugProducts.add(
      Product(
        id: 11,
        name: "Kartoffel",
        creationDate: DateTime.now().subtract(const Duration(days: 4)),
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
          quickNutri(11, 0, 77), // kcal
          quickNutri(11, 1, 0.1), // fat
          quickNutri(11, 2, 0), // saturated fat
          quickNutri(11, 3, 17), // carbohydrates
          quickNutri(11, 4, 0.8), // sugar
          quickNutri(11, 5, 2), // protein
          quickNutri(11, 6, 0), // salt
        ],
      ));
    
    // Suppe 12
    debugProducts.add(
      Product(
        id: 12,
        name: "Lecker Suppe",
        creationDate: DateTime.now().subtract(const Duration(days: 3)),
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
          amount2: 300,
          unit2: Unit.g,
          enabled: true,
        ),
        quantityName: "Teller",
        autoCalc: true,
        amountForIngredients: 550,
        ingredientsUnit: Unit.g,
        amountForNutrients: 100,
        nutrientsUnit: Unit.g,
        ingredients: [
          ProductQuantity(
            productId: 0,
            amount: 300,
            unit: Unit.ml,
          ),
          ProductQuantity(
            productId: 1,
            amount: 100,
            unit: Unit.g,
          ),
          ProductQuantity(
            productId: 11,
            amount: 100,
            unit: Unit.g,
          ),
          ProductQuantity(
            productId: 3,
            amount: 1,
            unit: Unit.quantity,
          ),
        ],
        nutrients: [
          quickNutri(12, 0, 0), // kcal
          quickNutri(12, 1, 0), // fat
          quickNutri(12, 2, 0), // saturated fat
          quickNutri(12, 3, 0), // carbohydrates
          quickNutri(12, 4, 0), // sugar
          quickNutri(12, 5, 0), // protein
          quickNutri(12, 6, 0), // salt
        ],
      ));
    
    // Mozarella Sticks 13
    debugProducts.add(
      Product(
        id: 13,
        name: "Mozarella Sticks",
        creationDate: DateTime.now().subtract(const Duration(days: 2)),
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
          quickNutri(13, 0, 300), // kcal
          quickNutri(13, 1, 20), // fat
          quickNutri(13, 2, 10), // saturated fat
          quickNutri(13, 3, 20), // carbohydrates
          quickNutri(13, 4, 3), // sugar
          quickNutri(13, 5, 15), // protein
          quickNutri(13, 6, 1), // salt
        ],
      ));
    
    // - end of products -
    
    return debugProducts;
  }
  
  List<Meal> getDebugMeals(Duration diffDur) => [
    Meal(
      id: 0,
      productQuantity: ProductQuantity(
        productId: 0,
        amount: 20,
        unit: Unit.ml,
      ),
      dateTime: DateTime.now().subtract(diffDur * 6),
    ),
    Meal(
      id: 1,
      productQuantity: ProductQuantity(
        productId: 1,
        amount: 100,
        unit: Unit.g,
      ),
      dateTime: DateTime.now().subtract(diffDur * 2),
    ),
    Meal(
      id: 2,
      productQuantity: ProductQuantity(
        productId: 2,
        amount: 1,
        unit: Unit.quantity,
      ),
      dateTime: DateTime.now().subtract(diffDur * 3),
    ),
    Meal(
      id: 3,
      productQuantity: ProductQuantity(
        productId: 3,
        amount: 1,
        unit: Unit.quantity,
      ),
      dateTime: DateTime.now().subtract(diffDur * 4),
    ),
    Meal(
      id: 4,
      productQuantity: ProductQuantity(
        productId: 4,
        amount: 100,
        unit: Unit.ml,
      ),
      dateTime: DateTime.now().subtract(diffDur * 5),
    ),
    Meal(
      id: 5,
      productQuantity: ProductQuantity(
        productId: 5,
        amount: 50,
        unit: Unit.g,
      ),
      dateTime: DateTime.now().subtract(diffDur * 1),
    ),
    Meal(
      id: 6,
      productQuantity: ProductQuantity(
        productId: 6,
        amount: 100,
        unit: Unit.g,
      ),
      dateTime: DateTime.now().subtract(diffDur * 7),
    ),
    Meal(
      id: 7,
      productQuantity: ProductQuantity(
        productId: 7,
        amount: 50,
        unit: Unit.g,
      ),
      dateTime: DateTime.now().subtract(diffDur * 8),
    ),
    Meal(
      id: 8,
      productQuantity: ProductQuantity(
        productId: 8,
        amount: 500,
        unit: Unit.g,
      ),
      dateTime: DateTime.now().subtract(diffDur * 9),
    ),
    Meal(
      id: 9,
      productQuantity: ProductQuantity(
        productId: 9,
        amount: 250,
        unit: Unit.g,
      ),
      dateTime: DateTime.now().subtract(diffDur * 10),
    ),
    Meal(
      id: 10,
      productQuantity: ProductQuantity(
        productId: 10,
        amount: 1,
        unit: Unit.quantity,
      ),
      dateTime: DateTime.now().subtract(diffDur * 11),
    ),
    Meal(
      id: 11,
      productQuantity: ProductQuantity(
        productId: 11,
        amount: 100,
        unit: Unit.g,
      ),
      dateTime: DateTime.now().subtract(diffDur * 12),
    ),
    Meal(
      id: 12,
      productQuantity: ProductQuantity(
        productId: 12,
        amount: 1,
        unit: Unit.quantity,
      ),
      dateTime: DateTime.now().subtract(diffDur * 13),
    ),
    Meal(
      id: 13,
      productQuantity: ProductQuantity(
        productId: 13,
        amount: 300,
        unit: Unit.g,
      ),
      dateTime: DateTime.now().subtract(diffDur * 14),
    ),
  ].reversed.toList();
}