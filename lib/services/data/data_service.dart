import 'package:food_tracker/services/data/data_provider.dart';

import 'data_objects.dart';
import 'debug_data_provider.dart';

class DataService implements DataProvider {
  final DataProvider _provider;
  const DataService(this._provider);
  
  factory DataService.debug() => DataService(DebugDataProvider());

  @override
  Future<String> loadData() => _provider.loadData();

  @override
  List<Product> getProducts() => _provider.getProducts();
}