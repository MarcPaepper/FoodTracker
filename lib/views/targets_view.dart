import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/routes.dart';
import '../constants/ui.dart';
import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../utility/data_logic.dart';
import '../utility/modals.dart';
import '../utility/text_logic.dart';
import '../utility/theme.dart';
import '../widgets/loading_page.dart';

// import "dart:developer" as devtools show log;

class TargetsView extends StatefulWidget {
  const TargetsView({super.key});

  @override
  State<TargetsView> createState() => _TargetsViewState();
}

class _TargetsViewState extends State<TargetsView> {
  late final DataService _dataService;
  bool _isLoading = true;
  
  @override
  void initState() {
    _dataService = DataService.current();
    // reload stream after build complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isLoading) _dataService.reloadTargetStream();
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
      stream: _dataService.streamTargets(),
      builder: (contextT, snapshotT) {
        return StreamBuilder(
          stream: _dataService.streamNutritionalValues(),
          builder: (contextN, snapshotN) {
            return StreamBuilder(
              stream: _dataService.streamProducts(),
              builder: (contextP, snapshotP) {
                if (snapshotT.hasError || snapshotN.hasError || snapshotP.hasError) {
                  return Text("Error: ${snapshotT.error}");
                }
                if (snapshotT.hasData && snapshotN.hasData && snapshotP.hasData) {
                  _isLoading = false;
                  
                  var targets = snapshotT.data as List<Target>;
                  var nutvalues = snapshotN.data as List<NutritionalValue>;
                  var products = snapshotP.data as List<Product>;
                  
                  targets = sortTargets(targets);
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Expanded(
                        child: _buildListView(targets, nutvalues, products),
                      ),
                      _buildAddButton(),
                    ]
                  );
                } else {
                  return const LoadingPage();
                }
              }
            );
          }
        );
      }
    );
  }
  
  Widget _buildListView(List<Target> targets, List<NutritionalValue> nutvalues, List<Product> products) {
    var length = targets.length;
    return ReorderableListView.builder(
      itemCount: length,
      itemBuilder: (context, index) {
        var target = targets[index];
        
        var type = target.trackedType;
        var amount = "";
        var name = "";
        
        if (type == NutritionalValue) {
          var nutvalue = nutvalues.firstWhere((element) => element.id == target.trackedId);
          name = nutvalue.name;
          amount = "${truncateZeros(target.amount)} ${nutvalue.unit}";
        } else if (type == Product) {
          var product = products.firstWhere((element) => element.id == target.trackedId);
          amount = "${truncateZeros(target.amount)} ${unitToString(target.unit!)}";
          name = product.name;
        } else {
          name = "Unknown Target Type";
        }
        
        bool dark = (length - index) % 2 == 0;
        var color = dark ? const Color.fromARGB(255, 237, 246, 253) : Colors.white;
        
        return ListTile(
          key: Key("${target.trackedType} #${target.trackedId}"),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 16.5 * gsf)),
                    Text(amount, style: const TextStyle(fontSize: 14 * gsf)),
                  ],
                ),
              ),
              // dot indicator if target is primary
              if (target.isPrimary) 
                const Tooltip(
                  message: "Primary Target",
                  child: Icon(Icons.circle, size: 10 * gsf, color: Colors.teal),
                  // child: Text("P", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(width: (kIsWeb ? 30 : 10) * gsf),
            ],
          ),
          minVerticalPadding: 0,
          visualDensity: const VisualDensity(vertical: 1 * gsf, horizontal: 0),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10 * gsf),
          tileColor: color,
          onTap: () {
            Navigator.pushNamed(context, editTargetRoute, arguments: (target.trackedType, target.trackedId));
          },
        );
      },
      onReorder: (oldIndex, newIndex) {
        List<((Type, int, bool), int)> orderList = targets.map((t) => ((t.trackedType, t.trackedId, t.isPrimary), t.orderId)).toList();
        var orderMap = getReorderMap(orderList, oldIndex, newIndex);
        
        if (orderMap != null) {
          // cast dynamic to tuple
          var orderMapNew = orderMap.map((key, value) => MapEntry(key as (Type, int, bool), value));
          
          // check if any primary target is below any non-primary target
          int? highestSecondary, lowestPrimary;
          for (var entry in orderMapNew.entries) {
            if (entry.key.$3) {
              if (lowestPrimary == null || entry.value < lowestPrimary) lowestPrimary = entry.value;
            } else {
              if (highestSecondary == null || entry.value > highestSecondary) highestSecondary = entry.value;
            }
          }
          if (highestSecondary != null && lowestPrimary != null && highestSecondary < lowestPrimary) {
            showErrorbar(context, "Primary Targets must be on top");
            return;
          }
          var orderMapReduced = orderMapNew.map((key, value) => MapEntry((key.$1, key.$2), value));
          _dataService.reorderTargets(orderMapReduced);
        }
      },
    );
  }
  
  Widget _buildAddButton() => ElevatedButton.icon(
    style: addButtonStyle,
    icon: const Icon(Icons.add),
    label: const Padding(
      padding: EdgeInsets.only(left: 5.0 * gsf),
      child: Text("Add Daily Target"),
    ),
    onPressed: () {
      Navigator.of(context).pushNamed(addTargetRoute);
    },
  );
}