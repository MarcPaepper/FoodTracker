
import 'data_objects.dart';
// ignore: unused_import
import 'sqflite_data_provider.dart';

abstract class DataProvider {
  Future<String> open(String dbName);
  Future<void> close();
  bool isLoaded();
  
  Stream<List<Product>> streamProducts();
  void reloadProductStream();
  Future<Iterable<Product>> getAllProducts();
  Future<Product> getProduct(int id);
  Future<Product> createProduct(Product product);
  Future<Product> updateProduct(Product product);
  Future<void> deleteProduct(int id);
  Future<void> deleteProductWithName(String name);
  
  Stream<List<NutrionalValue>> streamNutrionalValues();
  Future<Iterable<NutrionalValue>> getAllNutrionalValues();
  void reloadNutrionalValueStream();
  Future<NutrionalValue> getNutrionalValue(int id);
  Future<NutrionalValue> createNutrionalValue(NutrionalValue nutVal);
  Future<NutrionalValue> updateNutrionalValue(NutrionalValue nutVal);
  Future<void> deleteNutrionalValue(int id);
  Future<void> deleteNutrionalValueWithName(String name);
}