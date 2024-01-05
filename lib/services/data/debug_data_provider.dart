import 'package:food_tracker/services/data/data_exceptions.dart';

import 'data_provider.dart';
import 'data_objects.dart';

class DebugDataProvider implements DataProvider {
  List<Product> _products = [];
  // List<NutrionalValue> _nutValues = [];
  bool _loaded = false;
  
  @override
  Future<String> loadData() {
    if (_loaded) return Future.value("data already loaded");
    return Future.delayed(
      const Duration(milliseconds: 900), () {
        // create the 7 default nutrional values
        // nutValues.add(NutrionalValue(""));
        _products = [
          Product("Example Product 1"),
          Product("Example Product 2"),
          Product("Example Product 3"),
        ];
        
        _loaded = true;
        return "data loaded";
      });
  }
  
  @override
  bool isLoaded() => _loaded;

  @override
  List<Product> get products {
    if (_loaded) {
      return _products;
    } else {
      throw DataNotLoadedException();
    }
  }
}