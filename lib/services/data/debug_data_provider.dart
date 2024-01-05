import 'data_provider.dart';
import 'data_objects.dart';

class DebugDataProvider implements DataProvider {
  List<Product> products = [];
  List<NutrionalValue> nutValues = [];
  
  @override
  Future<String> loadData() {
    return Future.delayed(
      const Duration(milliseconds: 500), () {
        // create the 7 default nutrional values
        nutValues.add(NutrionalValue(""));
        return "data loaded";
      });
  }

  @override
  List<Product> getProducts() {
    return [
      Product("Example Product 1"),
      Product("Example Product 2"),
      Product("Example Product 3"),
    ];
  }
}