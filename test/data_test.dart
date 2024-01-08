// import 'package:food_tracker/services/data/data_objects.dart';
// import 'package:food_tracker/services/data/data_provider.dart';
// import 'package:food_tracker/services/data/data_exceptions.dart';
// import 'package:test/test.dart';

// void main() {
//   group("Mock Data", () {
//     final provider = MockDataProvider();
    
//     test ("should not have loaded", () {
//       expect(provider.isLoaded(), false);
//     });
    
//     test("Cannot access data before loading", () {
//       expect(() => provider.products, throwsA(isA<DataNotLoadedException>()));
//     });
    
//     test("Should load data in less than 2s", () async {
//       expect(await provider.loadData(), "data loaded");
//     }, timeout: const Timeout(Duration(seconds: 2)));
//   });
// }

// class MockDataProvider implements DataProvider {
//   bool _loaded = false;
  
//   @override
//   Future<String> loadData() {
//     return Future.delayed(
//       const Duration(milliseconds: 500), () {
//         _loaded = true;
//         return "data loaded";
//       });
//   }
  
//   @override
//   bool isLoaded() => _loaded;

//   @override
//   List<Product> get products {
//     if (!_loaded) throw DataNotLoadedException();
//     return [
//       Product("Example Product 1"),
//       Product("Example Product 2"),
//       Product("Example Product 3"),
//     ];
//   }
// }