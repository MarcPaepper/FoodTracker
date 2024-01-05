import 'package:food_tracker/services/data/data_provider.dart';

import 'data_objects.dart';
import 'debug_data_provider.dart';

class DataService implements DataProvider {
  final DataProvider _provider;
  const DataService(this._provider);
  // cache data service
  static final Map<String, DataService> _cache = {};
  
  factory DataService.debug() {
    if (!_cache.containsKey("debug")) {
      _cache["debug"] = DataService(DebugDataProvider());
    }
    return _cache["debug"]!;
  }

  @override
  Future<String> loadData() => _provider.loadData();
  
  @override
  bool isLoaded() => _provider.isLoaded();

  @override
  List<Product> get products => _provider.products;
}