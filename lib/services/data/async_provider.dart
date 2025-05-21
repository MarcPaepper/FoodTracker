// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:collection/collection.dart';
import 'package:food_tracker/services/data/data_objects.dart';
import 'package:food_tracker/utility/data_logic.dart';
import 'package:rxdart/rxdart.dart';

import 'data_service.dart';

import 'dart:developer' as devtools;

enum CacheMode {
  notCached,
  any,
  cached,
}

class AsyncProvider {
  static final DataService _dataService = DataService.current();
  static Map<int, double>? _relevancies;
  static Map<int, ProductQuantity>? _commonQuantities;
  static DateTime _compDT = DateTime.now();
  static final _relevancyStreamController = BehaviorSubject<Map<int, double>>();
  
  static Future? currentFuture;
  static bool restartFuture = false;
  
  static Stream<Map<int, double>> streamRelevancies() => _relevancyStreamController.stream;
  
  static Future<Map<int, double>> getRelevancies({CacheMode useCached = CacheMode.any}) async {
    if (!_dataService.isLoaded()) return {};
    if (useCached == CacheMode.cached && _relevancies == null) return {};
    if (useCached != CacheMode.notCached && _relevancies != null) {
      return _relevancies!;
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
  
  static Map<int, ProductQuantity>? getCommonAmounts() => _commonQuantities;
  
  static double? getCommonAmount(int productId) => _commonQuantities?[productId]?.amount;
  
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
      Map<int, ProductQuantity> newCommonAmounts = {};
      var products = await _dataService.getAllProducts();
      var meals = await _dataService.getAllMeals();
      if (restartFuture) continue;
      if (ids == null) {
        for (var product in products) {
          var (relevancy, commonQuantity) = calcProductRelevancy(meals.toList(), product, _compDT);
          newRelevancies[product.id] = relevancy;
          if (commonQuantity != null) newCommonAmounts[product.id] = commonQuantity;
          if (restartFuture) break;
        }
      } else if (_relevancies != null) {
        for (var id in ids) {
          var product = products.firstWhereOrNull((element) => element.id == id);
          if (product == null) {
            _relevancies?.remove(id);
            continue;
          }
          // _relevancies![id] = calcProductRelevancy(meals.toList(), product, _compDT);
          var (relevancy, commonQuantity) = calcProductRelevancy(meals.toList(), product, _compDT);
          _relevancies![id] = relevancy;
          if (_commonQuantities != null && commonQuantity != null) _commonQuantities![id] = commonQuantity;
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
      // for (var i = 0; i < newRelevancies.length && i < 10; i++) {
      //   var key = newRelevancies.keys.elementAt(i);
      //   var product = productsMap[key];
      //   devtools.log("${product?.name}: ${roundDouble(newRelevancies[key] ?? 0)}");
      // }
      // devtools.log("--- updated relevancies ${newRelevancies.length} / ${ids?.length} ---");
      
      
      if (ids == null) {
        _relevancies = newRelevancies;
        _commonQuantities = newCommonAmounts;
        devtools.log("!!! updated relevancies ");
        for (MapEntry<int, ProductQuantity> entry in newCommonAmounts.entries) {
          Product product = products.firstWhere((element) => element.id == entry.key);
          devtools.log("!!! ${product.name}: ${entry.value.amount} ${entry.value.unit}");
        }
      }
      _relevancyStreamController.add(_relevancies!);
    }
  }
  
  static void changeCompDT(DateTime newCompDT) {
    _compDT = newCompDT;
    // check if future is currently running and cancel it
    if (currentFuture == null) {
      // reload relevancies
      getRelevancies(useCached: CacheMode.notCached);
    } else {
      restartFuture = true;
    }
  }
}