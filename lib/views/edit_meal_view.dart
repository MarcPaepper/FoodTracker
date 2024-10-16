import 'package:flutter/material.dart';

import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../utility/modals.dart';
import '../widgets/datetime_selectors.dart';
import '../widgets/food_box.dart';
import '../widgets/loading_page.dart';

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
  
  late final GlobalKey<FormState> _formKey;
  final ValueNotifier<List<(ProductQuantity, Color)>> ingredientsNotifier = ValueNotifier([]);
  final ValueNotifier<DateTime> dateTimeNotifier = ValueNotifier(DateTime.now().add(const Duration(hours: 1)));
  List<TextEditingController> ingredientAmountControllers = [];
  //final List<FocusNode> ingredientDropdownFocusNodes = [];
  bool loaded = false;
  
  @override
  void initState() {
    if (widget.mealId < 0) {
      Future(() {
        showErrorbar(context, "Error: Product not found");
        Navigator.of(context).pop(null);
      });
    }
    
    _formKey = GlobalKey<FormState>();
    
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
     return PopScope(
      canPop: false,
      onPopInvoked: _onPopInvoked,
      child: Scaffold(
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
                    
                    if (!loaded) {
                      dateTimeNotifier.value = meal.dateTime;
                      ingredientsNotifier.value = [(meal.productQuantity, Colors.teal.shade400)];
                      ingredientAmountControllers = [TextEditingController(text: meal.productQuantity.amount.toString())];
                      loaded = true;
                    }
                    
                    return Form(
                      key: _formKey,
                      child: _buildView(products, meal),
                    );
                  }
                  return const LoadingPage();
                },
              );
            }
            return const LoadingPage();
          },
        ),
      )
    );
  }
  
  Widget _buildView(List<Product> products, Meal meal) {
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
          canChangeProducts: false,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: DateAndTimeTable(
            dateTimeNotifier: dateTimeNotifier,
            updateDateTime:   _updateDateTime,
          ),
        ),
        Expanded(child: Container()),
        _buildUpdateButton(meal),
      ],
    );
  }
  
  void _updateDateTime(DateTime newDateTime) => dateTimeNotifier.value = newDateTime;
  
  Widget _buildUpdateButton(Meal meal) => Padding(
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
        var newMeal = meal.copyWith(
          newDateTime: dateTimeNotifier.value,
          newProductQuantity: ingredientsNotifier.value[0].$1,
        );
        dataService.updateMeal(newMeal);
        Navigator.of(context).pop();
      },
      child: const Text("Apply Changes"),
    ),
  );
  
  Future _onPopInvoked(bool didPop) async {
    if (didPop) return;
    
    final NavigatorState navigator = Navigator.of(context);
    
    var valid = _formKey.currentState?.validate() ?? false;
    
    if (valid) {
      dataService.cleanUp();
      Future(() => navigator.pop());
    }
  }
  
  @override
  bool get wantKeepAlive => true;
}