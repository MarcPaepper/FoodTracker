
import 'data_objects.dart';

abstract class DataProvider {
  Future<String> open(String dbName);
  Future<void> close();
  bool isLoaded();
  
  Stream<List<Product>> streamProducts();
  Future<Iterable<Product>> getAllProducts();
  void reloadProductStream();
  Future<Product> getProduct(int id);
  Future<Product> createProduct(Product product);
  Future<Product> updateProduct(Product product);
  Future<void> deleteProduct(int id);
  Future<void> deleteProductWithName(String name);
  
  Stream<List<NutritionalValue>> streamNutritionalValues();
  Future<Iterable<NutritionalValue>> getAllNutritionalValues();
  void reloadNutritionalValueStream();
  Future<NutritionalValue> getNutritionalValue(int id);
  Future<NutritionalValue> createNutritionalValue(NutritionalValue nutVal);
  Future<NutritionalValue> updateNutritionalValue(NutritionalValue nutVal);
  Future<void> reorderNutritionalValues(Map<int, int> orderMap);
  Future<void> deleteNutritionalValue(int id);
  Future<void> deleteNutritionalValueWithName(String name);
  
  Stream<List<Meal>> streamMeals();
  Future<Iterable<Meal>> getAllMeals();
  void reloadMealStream();
  Future<Meal> getMeal(int id);
  Future<Meal> createMeal(Meal meal);
  Future<Meal> updateMeal(Meal meal);
  Future<void> deleteMeal(int id);
}