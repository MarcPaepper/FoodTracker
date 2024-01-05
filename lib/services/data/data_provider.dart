
import 'data_objects.dart';

abstract class DataProvider {
  Future<String> loadData();
  bool isLoaded();
  List<Product> get products;
}