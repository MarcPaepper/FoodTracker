import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:food_tracker/constants/routes.dart';
import 'package:food_tracker/utility/data_logic.dart';

import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../utility/theme.dart';
import '../widgets/loading_page.dart';

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
          amount = "${target.amount} ${nutvalue.unit}";
        } else if (type == Product) {
          var product = products.firstWhere((element) => element.id == target.trackedId);
          amount = "${target.amount} ${unitToString(target.unit!)}";
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
                    Text(name, style: const TextStyle(fontSize: 16.5)),
                    Text(amount, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              // dot indicator if target is primary
              if (target.isPrimary) 
                const Tooltip(
                  message: "Primary Target",
                  child: Icon(Icons.circle, size: 10, color: Colors.teal),
                ),
              const SizedBox(width: kIsWeb ? 30 : 10),
            ],
          ),
          minVerticalPadding: 0,
          visualDensity: const VisualDensity(vertical: 1, horizontal: 0),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
          tileColor: color,
        );
      },
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        // _dataService.reorderTargets({oldIndex: newIndex});
      },
    );
  }
  
  Widget _buildAddButton() => ElevatedButton.icon(
    style: addButtonStyle,
    icon: const Icon(Icons.add),
    label: const Padding(
      padding: EdgeInsets.only(left: 5.0),
      child: Text("Add Daily Target"),
    ),
    onPressed: () {
      Navigator.of(context).pushNamed(addTargetRoute);
    },
  );
}