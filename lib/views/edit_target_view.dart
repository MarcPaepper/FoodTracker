// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:food_tracker/utility/theme.dart';
import 'package:food_tracker/widgets/multi_value_listenable_builder.dart';
import 'package:food_tracker/widgets/unit_dropdown.dart';

import '../constants/data.dart';
import '../constants/ui.dart';
import '../services/data/data_exceptions.dart';
import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../utility/modals.dart';
import '../utility/text_logic.dart';
import '../widgets/amount_field.dart';
import '../widgets/loading_page.dart';
import '../widgets/multi_stream_builder.dart';
import '../widgets/product_dropdown.dart';

// import 'dart:developer' as devtools show log;

class EditTargetView extends StatefulWidget {
  final bool? isEdit;
  final Type? type;
  final int? trackedId;
  
  const EditTargetView({Key? key, this.isEdit, this.type, this.trackedId}) : super(key: key);

  @override
  State<EditTargetView> createState() => _EditTargetViewState();
}

class _EditTargetViewState extends State<EditTargetView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  final _dataService = DataService.current();
  final _formKey = GlobalKey<FormState>();
  
  final _isPrimaryNotifier = ValueNotifier<bool>(true);
  final _typeNotifier      = ValueNotifier<Type>(NutritionalValue);
  final _trackedIdNotifier = ValueNotifier<int?>(null);
  final _amountNotifier    = ValueNotifier<double>(0);
  final _unitNotifier      = ValueNotifier<Unit?>(null);
  
  final _amountController  = TextEditingController();
  
  int? _orderId;
  
  late final bool isEdit;
  
  Target? _interimTarget;
  
  @override
  void initState() {
    if (widget.isEdit == null || (widget.isEdit! && widget.trackedId == null)) {
      Future(() {
        showErrorbar(context, "Error: Target not found");
        Navigator.of(context).pop();
      });
    }
    isEdit = widget.isEdit ?? false;
    
    _dataService.open(dbName);
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MultiStreamBuilder(
      streams: [
        _dataService.streamProducts(),
        _dataService.streamNutritionalValues(),
        _dataService.streamTargets(),
      ],
      builder: (context, snapshots) {
        Widget? msg;
        
        if (snapshots.any((snap) => snap.connectionState == ConnectionState.waiting)) {
          msg = const LoadingPage();
        }
        
        if (snapshots.any((snap) => snap.hasError)) {
          msg = Text("Error: ${snapshots.firstWhere((snap) => snap.hasError).error}");
        }
        
        if (msg != null) {
          return Scaffold(
            appBar: AppBar(title: Text(isEdit ? "Edit Target" : "Add Target")),
            body: msg,
          );
        }
        
        final products = snapshots[0].data as List<Product>;
        final productsMap = Map<int, Product>.fromEntries(products.map((product) => MapEntry(product.id, product)));
        final nutvalues = snapshots[1].data as List<NutritionalValue>;
        final targets = snapshots[2].data as List<Target>;
        
        if (isEdit) {
          if (_interimTarget == null) {
            try {
              _interimTarget = targets.firstWhere((target) => target.trackedType == widget.type && target.trackedId == widget.trackedId);
            } catch (e) {
              Future(() {
                showErrorbar(context, "Error: Target not found");
                try {
                  Navigator.of(context).pop(null);
                } catch (e) {
                  // ignore
                }
              });
            }
          }
        } else {
          _interimTarget = Target(
            orderId: -1,
            isPrimary: true,
            trackedType: NutritionalValue,
            trackedId: -1,
            unit: null,
            amount: 0,
          );
        }
        
        if (_interimTarget != null) {
          _isPrimaryNotifier.value = _interimTarget!.isPrimary;
          _typeNotifier.value      = _interimTarget!.trackedType;
          _trackedIdNotifier.value = _interimTarget!.trackedId == -1 ? null : _interimTarget!.trackedId;
          _amountNotifier.value    = _interimTarget!.amount;
          _amountController.text   = truncateZeros(_interimTarget!.amount);
          _unitNotifier.value      = _interimTarget!.unit;
          _orderId                 = _interimTarget!.orderId;
        }
        
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: appBarHeight,
            title: Text(isEdit ? "Edit Target" : "Add Target", style: const TextStyle(fontSize: 16 * gsf)),
            // show the delete button if editing
            actions: [
              if (isEdit)
                IconButton(
                  padding: kIsWeb ? 
                    const EdgeInsets.fromLTRB(5, 5, 5, 5) * gsf : 
                    EdgeInsets.zero,
                  icon: const Icon(Icons.delete, size: 21 * gsf),
                  // onPressed: () {}
                  onPressed: () async {
                    if (widget.trackedId == null || widget.type == null) {
                      showErrorbar(context, "Error: Target not found");
                      Navigator.of(context).pop();
                    }
                    await _dataService.deleteTarget(widget.type!, widget.trackedId!);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12.0) * gsf,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPrimaryToggle(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 2, 0, 8) * gsf,
                      child: const Text("Type of target:", style: TextStyle(fontSize: 16 * gsf)),
                    ),
                    _buildTypeDropdown(),
                    const SizedBox(height: 10 * gsf),
                    _buildSelectorDropdown(nutvalues, productsMap),
                    ValueListenableBuilder(
                      valueListenable: _trackedIdNotifier,
                      builder: (context, trackedId, child) {
                        if (trackedId == null) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(6, 12, 0, 8) * gsf,
                              child: const Text("Daily Target:", style: TextStyle(fontSize: 16 * gsf)),
                            ),
                            Row(
                              children: [
                                Expanded(child: _buildAmountField()),
                                const SizedBox(width: 10 * gsf),
                                _buildUnitDropdown(nutvalues, products),
                              ],
                            ),
                            const SizedBox(height: 20 * gsf),
                            _buildAddButton(nutvalues, products),
                          ],
                        );
                      },
                    ),
                  ]
                ),
              ),
            ),
          )
        );
      }
    );
  }
  
  Widget _buildPrimaryToggle() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isPrimaryNotifier,
      builder: (context, isPrimary, child) {
        return SwitchListTile(
          value: isPrimary,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (isPrimary) {
            _isPrimaryNotifier.value = isPrimary;
            _interimTarget = _interimTarget?.copyWith(newIsPrimary: isPrimary);
          },
          title: const Text("Primary Target"),
        );
      }
    );
  }
  
  Widget _buildTypeDropdown() {
    return ValueListenableBuilder<Type>(
      valueListenable: _typeNotifier,
      builder: (context, type, child) {
        return DropdownButtonFormField<Type>(
          style: const TextStyle(fontSize: 43 * gsf),
          icon: const Icon(Icons.arrow_drop_down),
          iconSize: 24 * gsf,
          isDense: true,
          isExpanded: true,
          decoration: dropdownStyleEnabled,
          value: type,
          items: const [
            DropdownMenuItem(
              value: NutritionalValue,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 25 * gsf - 25),
                child: Text("Nutritional Value", style: TextStyle(fontSize: 16 * gsf)),
              ),
              
            ),
            DropdownMenuItem(
              value: Product,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 25 * gsf - 25),
                child: Text("Product", style: TextStyle(fontSize: 16 * gsf)),
              ),
            ),
          ],
          onChanged: (type) {
            _typeNotifier.value = type!;
            _trackedIdNotifier.value = null;
            _unitNotifier.value = type == Product ? Unit.g : null;
            _interimTarget = _interimTarget?.copyWith(
              newTrackedType: type,
              newTrackedId: -1,
              changeUnit: true,
              newUnit: type == Product ? Unit.g : null,
            );
          },
        );
      }
    );
  }
  
  Widget _buildSelectorDropdown(List<NutritionalValue> nutvalues, Map<int, Product> productsMap) {
    return MultiValueListenableBuilder(
      listenables: [_typeNotifier, _trackedIdNotifier],
      builder: (context, values, child) {
        Type type = values[0];
        int? trackedId = values[1];
        
        if (type == Product) {
          var product = productsMap[trackedId];
          
          return ProductDropdown(
            productsMap: productsMap,
            selectedProduct: product,
            allowNew: false,
            onChanged: (product) {
              if (product != null && product.id != trackedId && product.id != -1) {
                _trackedIdNotifier.value = product.id;
                _unitNotifier.value = product.defaultUnit;
                _interimTarget = _interimTarget?.copyWith(
                  newTrackedId: product.id,
                  changeUnit: true,
                  newUnit: product.defaultUnit,
                );
              }
            },
          );
        } else if (type == NutritionalValue) {
          return DropdownButtonFormField<int>(
            decoration: dropdownStyleEnabled,
            style: const TextStyle(fontSize: 43 * gsf),
            icon: const Icon(Icons.arrow_drop_down),
            iconSize: 24 * gsf,
            isDense: true,
            isExpanded: true,
            value: trackedId,
            hint: Text("Choose a Nutritional Value",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium!.color ?? Colors.black,
                fontSize: 16 * gsf,
                fontWeight: FontWeight.normal,
                fontStyle: FontStyle.italic,
              ),
            ),
            items: nutvalues.map((nutvalue) => DropdownMenuItem<int>(
              value: nutvalue.id,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 25 * gsf - 25),
                child: Text(nutvalue.name, style: const TextStyle(fontSize: 16 * gsf)),
              ),
            )).toList(),
            onChanged: (value) {
              _trackedIdNotifier.value = value!;
              _interimTarget = _interimTarget?.copyWith(newTrackedId: value);
            },
          );
        } else {
          return const SizedBox.shrink();
        }
      }
    );
  }
  
  Widget _buildAmountField() {
    return ValueListenableBuilder<double>(
      valueListenable: _amountNotifier,
      builder: (context, amount, child) {
        return AmountField(
          padding: 0,
          controller: _amountController,
          onChangedAndParsed: (value) {
            _amountNotifier.value = value;
            _interimTarget = _interimTarget?.copyWith(newAmount: value);
          },
        );
      }
    );
  }
  
  Widget _buildUnitDropdown(List<NutritionalValue> nutvalues, List<Product> products) {
    return MultiValueListenableBuilder(
      listenables: [_unitNotifier, _typeNotifier, _trackedIdNotifier],
      builder: (context, values, child) {
        Unit? unit = values[0];
        Type type = values[1];
        int? trackedId = values[2];
        
        if (type == Product) {
          var product = products.firstWhereOrNull((element) => element.id == trackedId);
          
          return Expanded(
            child: UnitDropdown(
              items: buildUnitItems(units: product?.getAvailableUnits() ?? Unit.values, quantityName: product?.quantityName ?? "x"),
              current: unit ?? product?.defaultUnit ?? Unit.g,
              onChanged: (value) {
                if (value != null) {
                  _unitNotifier.value = value;
                  _interimTarget = _interimTarget?.copyWith(newUnit: value, changeUnit: true);
                }
              },
              enabled: product != null,
            ),
          );
        } else if (type == NutritionalValue) {
          var nutvalue = nutvalues.firstWhereOrNull((element) => element.id == trackedId);
          
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 8, 0) * gsf,
            child: Text(nutvalue?.unit ?? "g",
              style: const TextStyle(
                fontSize: 16 * gsf,
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      }
    );
  }
  
  Widget _buildAddButton(List<NutritionalValue> nutValues, List<Product> products) => ElevatedButton(
    style: importantButtonStyle,
    onPressed: () async {
      final isPrimary = _isPrimaryNotifier.value;
      final type = _typeNotifier.value;
      final trackedId = _trackedIdNotifier.value;
      final amount = _amountNotifier.value;
      final unit = _unitNotifier.value;
      
      String? errorMsg;
      if (_orderId == null && isEdit)
        errorMsg = "Error: Order ID not found";
      if (amount == 0)
        errorMsg = "Error: Amount must be greater than 0";
      if (type == Product && unit == null)
        errorMsg = "Error: Unit not found";
      if (trackedId == null)
        errorMsg = "Error: Please select a target";
      
      if (errorMsg != null) {
        showErrorbar(context, errorMsg);
        return;
      }
      
      final isValid = _formKey.currentState!.validate();
      if (isValid) {
        if (isEdit) {
          var target = Target(
            isPrimary: isPrimary,
            trackedType: type,
            trackedId: trackedId!,
            amount: amount,
            unit: unit,
            orderId: _orderId!,
          );
          _dataService.updateTarget(widget.type!, widget.trackedId!, target);
        } else {
          var target = Target(
            isPrimary: isPrimary,
            trackedType: type,
            trackedId: trackedId!,
            amount: amount,
            unit: unit,
            orderId: -1,
          );
          // try to create the target if unique
          try {
            await _dataService.createTarget(target);
          } on NotUniqueException {
            var isProduct = type == Product;
            var name = isProduct ?
              products.firstWhere((element) => element.id == target.trackedId).name :
              nutValues.firstWhere((element) => element.id == target.trackedId).name;
            if(mounted) {showErrorbar(context, "Duplicate target for '$name'");}
            return;
          }
        }
        if (mounted) Navigator.of(context).pop();
      }
    },
    child: Text(isEdit ? "Update" : "Add"),
  );
}