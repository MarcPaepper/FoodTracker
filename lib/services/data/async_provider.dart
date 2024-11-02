// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:collection/collection.dart';
import 'package:food_tracker/services/data/data_exceptions.dart';
import 'package:food_tracker/utility/data_logic.dart';
import 'package:rxdart/rxdart.dart';

import 'data_service.dart';

// import 'dart:developer' as devtools;

class AsyncProvider {
  static final DataService _dataService = DataService.current();
  static Map<int, double>? _relevancies;
  static DateTime _compDT = DateTime.now();
  static final _relevancyStreamController = BehaviorSubject<Map<int, double>>();
  
  static Future? currentFuture;
  static bool restartFuture = false;
  
  static Stream<Map<int, double>> streamRelevancies() => _relevancyStreamController.stream;
  
  static Future<Map<int, double>> getRelevancies({bool useCached = true}) async {
    if (!_dataService.isLoaded()) return {};
    if (useCached) {
      if (_relevancies != null) {
        return _relevancies!;
      } else {
        throw DataNotLoadedException();
      }
    }
    
    // if there is already a future running wait for it
    if (currentFuture != null) {
      await currentFuture;
      return _relevancies ?? {};
    }
    
    currentFuture = _updateRelevancies(null);
    await currentFuture;
    currentFuture = null;
    return _relevancies ?? {};
  }
  
  static Future<void> updateRelevancyFor(List<int> productIds) async {
    // if the future is running cancel it
    if (currentFuture != null) {
      restartFuture = true;
      await currentFuture;
    } else {
      currentFuture = _updateRelevancies(productIds);
      await currentFuture;
      currentFuture = null;
    }
  }
  
  static Future<void> _updateRelevancies(List<int>? ids) async {
    restartFuture = false;
    var complete = false;
    var firstTry = true;
    while (!complete) {
      if (!firstTry) ids = null;
      firstTry = false;
      restartFuture = false;
      Map<int, double> newRelevancies = {};
      var products = await _dataService.getAllProducts();
      var meals = await _dataService.getAllMeals();
      if (restartFuture) continue;
      
      if (ids == null) {
        for (var product in products) {
          newRelevancies[product.id] = calcProductRelevancy(meals.toList(), product, _compDT);
          if (restartFuture) break;
        }
      } else if (_relevancies != null) {
        for (var id in ids) {
          var product = products.firstWhereOrNull((element) => element.id == id);
          if (product == null) {
            _relevancies?.remove(id);
            continue;
          }
          _relevancies![id] = calcProductRelevancy(meals.toList(), product, _compDT);
          // newRelevancies[id] = _relevancies![id]!;
          if (restartFuture) break;
        }
      }
      if (restartFuture) continue;
      
      complete = true;
      
      
      // Map<int, Product>  productsMap = { for (var e in products) e.id : e };
      // devtools.log("!!! finished:");
      // // sort relevancies for value
      // newRelevancies = Map.fromEntries(newRelevancies.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
      // // only log first 10 products
      // for (var i = 0; i < newRelevancies.length && i < 100; i++) {
      //   var key = newRelevancies.keys.elementAt(i);
      //   var product = productsMap[key];
      //   devtools.log("${product?.name}: ${roundDouble(newRelevancies[key] ?? 0)}");
      // }
      
      if (ids == null || _relevancies == null) {
        _relevancies = newRelevancies;
      } else {
        _relevancies?.addAll(newRelevancies);
      }
      _relevancyStreamController.add(_relevancies!);
    }
  }
  
  static void changeCompDT(DateTime newCompDT) {
    _compDT = newCompDT;
    // check if future is currently running and cancel it
    if (currentFuture == null) {
      // reload relevancies
      getRelevancies(useCached: false);
    } else {
      restartFuture = true;
    }
  }
}