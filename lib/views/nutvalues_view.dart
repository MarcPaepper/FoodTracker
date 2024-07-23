import 'package:flutter/material.dart';
import 'package:food_tracker/constants/routes.dart';
import 'package:food_tracker/services/data/data_objects.dart';
import 'package:food_tracker/services/data/data_service.dart';
import 'package:food_tracker/utility/data_logic.dart';
import 'package:food_tracker/widgets/loading_page.dart';

import '../utility/theme.dart';

// import "dart:developer" as devtools show log;

class NutritionalValueView extends StatefulWidget {
	const NutritionalValueView({super.key});

  @override
  State<NutritionalValueView> createState() => _NutritionalValueViewState();
}

class _NutritionalValueViewState extends State<NutritionalValueView> {
  late final DataService _dataService;
  bool _isLoading = true;
  
  @override
  void initState() {
    _dataService = DataService.current();
    // reload stream after build complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isLoading) _dataService.reloadNutritionalValueStream();
    });
    super.initState();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
	@override
	Widget build(BuildContext context) {
		return StreamBuilder(
      stream: _dataService.streamNutritionalValues(),
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildListView(snapshot)
            ),
            _buildAddButton(),
          ]
        );
      }
		);
	}
  
  Widget _buildListView(AsyncSnapshot snapshot) {
    if (snapshot.hasError) {
      return Text("Error: ${snapshot.error}");
    }
    if (snapshot.hasData) {
      _isLoading = false;
      
      var values = snapshot.data as List<NutritionalValue>;
      
      values = sortNutValues(values);
      
      var length = values.length;
      return ReorderableListView.builder(
        itemCount: length,
        itemBuilder: (context, index) {
          var value = values[index];
          bool dark = (length - index) % 2 == 0;
          var color = dark ? const Color.fromARGB(255, 237, 246, 253) : Colors.white;
          
          return ListTile(
            key: Key(value.id.toString()),
            title: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value.name,
                    style: DefaultTextStyle.of(context).style.copyWith(
                      color: Colors.black,
                      fontSize: 16.5,
                    ),
                  ),
                ],
              ),
            ),
            tileColor: color,
            onTap: () {
              Navigator.pushNamed (
                context,
                editNutritionalValueRoute,
                arguments: value.id,
              );
            },
          );
        },
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          if (oldIndex == newIndex) return;
          
          var orderMap = <int, int>{};
          orderMap[values[oldIndex].id] = values[newIndex].orderId;
          
          if (newIndex > oldIndex) {
            // reduce all other order ids by 1
            for (var i = oldIndex + 1; i <= newIndex; i++) {
              orderMap[values[i].id] = values[i].orderId - 1;
            }
          } else {
            // increase all other order ids by 1
            for (var i = newIndex; i < oldIndex; i++) {
              orderMap[values[i].id] = values[i].orderId + 1;
            }
          }
          
          _dataService.reorderNutritionalValues(orderMap);
        },
      );
    }
    return const LoadingPage();
  }
  
  Widget _buildAddButton() => ElevatedButton.icon(
    style: addButtonStyle,
    icon: const Icon(Icons.add),
    label: const Padding(
      padding: EdgeInsets.only(left: 5.0),
      child: Text("Add Nutritional Value"),
    ),
    onPressed: () {
      Navigator.of(context).pushNamed(addNutritionalValueRoute);
    },
  );
}