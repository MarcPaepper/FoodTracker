// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

import '../constants/routes.dart';
import '../constants/ui.dart';
import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../utility/data_logic.dart';
import '../widgets/loading_page.dart';
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12 * gsf, vertical: 8 * gsf - 4),
            title: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value.name,
                    style: DefaultTextStyle.of(context).style.copyWith(
                      color: Colors.black,
                      fontSize: 16.5 * gsf,
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
          List<(int, int)> IdsAndOrderIds = values.map((v) => (v.id, v.orderId)).toList();
          var orderMap = getReorderMap(IdsAndOrderIds, oldIndex, newIndex);
          if (orderMap != null) {
            // The map is of type Map<dynamic, int> but must be Map<int, int>
            var orderMapNew = orderMap.map((key, value) => MapEntry(key as int, value));
            _dataService.reorderNutritionalValues(orderMapNew);
          }
        },
      );
    }
    return const LoadingPage();
  }
  
  Widget _buildAddButton() => ElevatedButton.icon(
    style: addButtonStyle,
    icon: const Icon(Icons.add, size: 20 * gsf),
    label: const Padding(
      padding: EdgeInsets.only(left: 5.0 * gsf),
      child: Text("Add Nutritional Value"),
    ),
    onPressed: () {
      Navigator.of(context).pushNamed(addNutritionalValueRoute);
    },
  );
}