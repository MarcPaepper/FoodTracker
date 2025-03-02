import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:food_tracker/utility/theme.dart';

import '../constants/ui.dart';
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
          toolbarHeight: appBarHeight,
          title: const Text('Edit Meal', style: TextStyle(fontSize: 16 * gsf)),
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
                    
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(6.0) * gsf,
                        child: Form(
                          key: _formKey,
                          child: _buildView(products, meal),
                        ),
                      ),
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
    
    return ValueListenableBuilder(
      valueListenable: dateTimeNotifier,
      builder: (context, dateTime, child) {
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
              refDate: dateTime,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12) * gsf,
              child: DateAndTimeTable(
                dateTimeNotifier: dateTimeNotifier,
                updateDateTime:   _updateDateTime,
              ),
            ),
            // Expanded(child: Container()),
            _buildUpdateButton(meal, products),
          ],
        );
      }
    );
  }
  
  void _updateDateTime(DateTime newDateTime) => dateTimeNotifier.value = newDateTime;
  
  Widget _buildUpdateButton(Meal meal, List<Product> products) => Padding(
    padding: const EdgeInsets.all(8.0) * gsf,
    child: ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.teal.shade400),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        minimumSize: WidgetStateProperty.all(const Size(double.infinity, 50 * gsf)),
        textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16 * gsf)),
        shape: WidgetStateProperty.all(const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14 * gsf)),
        )),
      ),
      onPressed: () {
        var valid = _formKey.currentState?.validate() ?? false;
        if (!valid) return;
        
        // check if the product is temporary and if the datetime is inside the products temporary interval
        var id = ingredientsNotifier.value[0].$1.productId;
        var product = products.firstWhereOrNull((element) => element.id == id);
        if (product == null) {
          showErrorbar(context, "Error: Product not found");
          return;
        } else {
          if (product.isTemporary) {
            // If product.temporaryBeginning is eg 2020-01-10:08:00:00 and then start should be 2020-01-09:23:59:59
            var start = product.temporaryBeginning!.subtract(const Duration(days: 1));
            var end = product.temporaryEnd!.add(const Duration(days: 1));
            
            start = DateTime(start.year, start.month, start.day, 23, 59, 59);
            end = DateTime(end.year, end.month, end.day, 0, 0, 0);
            if (dateTimeNotifier.value.isBefore(start) || dateTimeNotifier.value.isAfter(end) || dateTimeNotifier.value.isAtSameMomentAs(end)) {
              // show dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Error"),
                  content: const Text("The selected product is temporary and the selected date is outside the temporary interval."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
              return;
            }
          }
        }
        
        
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
    
    //var valid = _formKey.currentState?.validate() ?? false;
    
    //if (valid) {
    //  dataService.cleanUp();
    //  Future(() => navigator.pop());
    //}
    //devtools.log("Pop invoked");
    Future(() => navigator.pop());
  }
  
  @override
  bool get wantKeepAlive => true;
}