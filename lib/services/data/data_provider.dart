
import 'data_objects.dart';
// ignore: unused_import
import 'sqflite_data_provider.dart';

abstract class DataProvider {
  Future<String> open(String dbName);
  Future<void> close();
  bool isLoaded();
  Stream<List<Product>> streamProducts();
  void reloadStream();
  Future<Iterable<Product>> getAllProducts();
  Future<Product> getProduct(int id);
  Future<Product> getProductByName(String name);
  Future<Product> createProduct(String name);
  Future<Product> updateProduct(Product product);
  Future<void> deleteProduct(int id);
  Future<void> deleteProductWithName(String name);
}