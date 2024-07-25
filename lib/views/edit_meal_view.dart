import 'package:flutter/material.dart';

import '../constants/routes.dart';
import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../utility/modals.dart';
import '../widgets/datetime_selectors.dart';
import '../widgets/food_box.dart';
import '../widgets/loading_page.dart';
import '../widgets/products_list.dart';

// import 'dart:developer' as devtools show log;

class EditMealView extends StatefulWidget {
  final int mealId;

  const EditMealView({
    Key? key,
    required this.mealId,
  }) : super(key: key);

  @override
  State<EditMealView> createState() => _EditMealViewState();
}

class _EditMealViewState extends State<EditMealView> with AutomaticKeepAliveClientMixin {
  final DataService dataService = DataService.current();
  
  final ValueNotifier<List<ProductQuantity>> ingredientsNotifier = ValueNotifier([]);
  final ValueNotifier<DateTime> dateTimeNotifier = ValueNotifier(DateTime.now());
  List<TextEditingController> ingredientAmountControllers = [];
  //final List<FocusNode> ingredientDropdownFocusNodes = [];
  
  @override
  void initState() {
    if (widget.mealId < 0) {
      Future(() {
        showErrorbar(context, "Error: Product not found");
        Navigator.of(context).pop(null);
      });
    }
    
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Meal'),
      ),
      body: StreamBuilder(
        stream: dataService.streamProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          }
          if (snapshot.hasData) {
            var products = snapshot.data as List<Product>;
            return FutureBuilder(
              future: dataService.getMeal(widget.mealId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                if (snapshot.hasData) {
                  var meal = snapshot.data as Meal;
                  
                  dateTimeNotifier.value = meal.dateTime;
                  ingredientsNotifier.value = [meal.productQuantity];
                  ingredientAmountControllers = [TextEditingController(text: meal.productQuantity.amount.toString())];
                  
                  return _buildView(products, meal);
                }
                return const LoadingPage();
              },
            );
          }
          return const LoadingPage();
        },
      ),
    );
  }
  
  Widget _buildView(List<Product> products, Meal meal) {
    var product = products.firstWhere((element) => element.id == meal.productQuantity.productId);
    Map<int, Product> productsMap = { for (var e in products) e.id : e };
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Selector
        FoodBox(
          productsMap: productsMap,
          ingredientsNotifier: ingredientsNotifier,
          ingredientAmountControllers: ingredientAmountControllers,
          requestIngredientFocus: (i, j) => null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: DateAndTimeTable(
            dateTimeNotifier: dateTimeNotifier,
            updateDateTime:   _updateDateTime,
          ),
        ),
        Expanded(child: Container()),
        _buildUpdateButton(),
      ],
    );
  }
  
  Widget _buildProductList(List<Product> products, Product product) {
    return Column(
      // physics: const ClampingScrollPhysics(),
      children: getProductTiles(
        context: context,
        products: products,
        search: "",
        colorFromTop: true,
        onSelected: (name, id) => Navigator.pushNamed (
          context,
          editProductRoute,
          arguments: (name, false),
        ),
        onLongPress: (name, id) {
          Navigator.pushNamed (
            context,
            addProductRoute,
            arguments: (name, true),
          );
        },
      ),
    );
  }
  
  void _updateDateTime(DateTime newDateTime) => dateTimeNotifier.value = newDateTime;
  
  Widget _buildUpdateButton() => Padding(
    padding: const EdgeInsets.all(8.0),
    child: ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.teal.shade400),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        minimumSize: WidgetStateProperty.all(const Size(double.infinity, 50)),
        textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16)),
        shape: WidgetStateProperty.all(const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        )),
      ),
      onPressed: () {
        
      },
      child: const Text("Apply Changes"),
    ),
  );
  
  @override
  bool get wantKeepAlive => true;
}