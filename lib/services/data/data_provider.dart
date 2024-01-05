
import 'data_objects.dart';

abstract class DataProvider {
  Future<String> loadData();
  List<Product> getProducts();
}