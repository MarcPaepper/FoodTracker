import 'package:flutter/material.dart';

import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../utility/modals.dart';
import '../widgets/datetime_selectors.dart';
import '../widgets/loading_page.dart';

import 'dart:developer' as devtools show log;

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
  final DataService _dataService = DataService.current();
  
  final ValueNotifier<DateTime> _dateTimeNotifier = ValueNotifier(DateTime.now());
  final ValueNotifier<ProductQuantity?> _productQuantityNotifier = ValueNotifier(null);
  
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
        stream: _dataService.streamProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          }
          if (snapshot.hasData) {
            var products = snapshot.data as List<Product>;
            return FutureBuilder(
              future: _dataService.getMeal(widget.mealId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                if (snapshot.hasData) {
                  var meal = snapshot.data as Meal;
                  
                  _dateTimeNotifier.value = meal.dateTime;
                  _productQuantityNotifier.value = meal.productQuantity;
                  
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DateAndTimeTable(
            dateTimeNotifier: _dateTimeNotifier,
            updateDateTime:   _updateDateTime,
          ),
        ),
        _buildUpdateButton(),
      ],
    );
  }
  
  void _updateDateTime(DateTime newDateTime) => _dateTimeNotifier.value = newDateTime;
  
  Widget _buildUpdateButton() => Padding(
    padding: const EdgeInsets.all(8.0),
    child: ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.teal.shade400),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        minimumSize: WidgetStateProperty.all(const Size(double.infinity, 60)),
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