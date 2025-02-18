
import 'data_objects.dart';

abstract class DataProvider {
  Future<String> open(String dbName);
  Future<void> close();
  bool isLoaded();
  Future<String> reload();
  Future<void> reset(String dbName);
  Future<void> cleanUp();
  
  Stream<List<Product>> streamProducts();
  Future<Iterable<Product>> getAllProducts({bool cache = true});
  void reloadProductStream();
  Future<Product> getProduct(int id);
  Future<Product> createProduct(Product product);
  Future<List<Product>> createProducts(List<Product> products);
  Future<Product> updateProduct(Product product);
  Future<List<Product>> updateProducts(List<Product> products);
  Future<void> deleteProduct(int id);
  Future<void> deleteProductWithName(String name);
  
  Stream<List<NutritionalValue>> streamNutritionalValues();
  Future<Iterable<NutritionalValue>> getAllNutritionalValues({bool cache = true});
  void reloadNutritionalValueStream();
  Future<NutritionalValue> getNutritionalValue(int id);
  Future<NutritionalValue> createNutritionalValue(NutritionalValue nutVal);
  Future<NutritionalValue> updateNutritionalValue(NutritionalValue nutVal);
  Future<void> reorderNutritionalValues(Map<int, int> orderMap);
  Future<void> deleteNutritionalValue(int id);
  Future<void> deleteNutritionalValueWithName(String name);
  
  Stream<List<Meal>> streamMeals();
  Future<Iterable<Meal>> getAllMeals({bool cache = true});
  void reloadMealStream();
  Future<Meal> getMeal(int id);
  Future<Meal> createMeal(Meal meal);
  Future<List<Meal>> createMeals(List<Meal> meals);
  Future<Meal> updateMeal(Meal meal);
  Future<void> deleteMeal(int id);
  
  Stream<List<Target>> streamTargets();
  Future<Iterable<Target>> getAllTargets({bool cache = true});
  void reloadTargetStream();
  Future<Target> getTarget(Type targetType, int targetId);
  Future<Target> createTarget(Target target);
  Future<Target> updateTarget(Type origType, int origTrackedId, Target target);
  Future<void> reorderTargets(Map<(Type, int), int> orderMap);
  Future<void> deleteTarget(Type targetType, int targetId);
}