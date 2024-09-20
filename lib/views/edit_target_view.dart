import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:food_tracker/utility/theme.dart';
import 'package:food_tracker/widgets/multi_value_listenable_builder.dart';
import 'package:food_tracker/widgets/unit_dropdown.dart';

import '../constants/data.dart';
import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../utility/modals.dart';
import '../widgets/loading_page.dart';
import '../widgets/product_dropdown.dart';

// import 'dart:developer' as devtools show log;

class EditTargetView extends StatefulWidget {
  final Type? type;
  final int? trackedId;
  final bool? isEdit;
  
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
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Target" : "Add Target"),
        // show the delete button if editing
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete),
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
      body: StreamBuilder(
        stream: _dataService.streamProducts(),
        builder: (contextP, snapshotP) {
          return StreamBuilder(
            stream: _dataService.streamNutritionalValues(),
            builder: (contextN, snapshotN) {
              return FutureBuilder(
                future: _dataService.getAllTargets(),
                builder: (contextT, snapshotT) {
                  if (snapshotP.connectionState == ConnectionState.waiting || snapshotN.connectionState == ConnectionState.waiting || snapshotT.connectionState == ConnectionState.waiting) {
                    return const LoadingPage();
                  }
                  
                  if (snapshotP.hasError || snapshotN.hasError || snapshotT.hasError) {
                    showErrorbar(context, "Error: ${snapshotP.error ?? snapshotN.error ?? snapshotT.error}");
                    return const LoadingPage();
                  }
                  
                  final products = snapshotP.data as List<Product>;
                  final productsMap = Map<int, Product>.fromEntries(products.map((product) => MapEntry(product.id, product)));
                  final nutvalues = snapshotN.data as List<NutritionalValue>;
                  final targets = snapshotT.data as List<Target>;
                  
                  if (isEdit) {
                    if (_interimTarget == null) {
                      try {
                        _interimTarget = targets.firstWhere((target) => target.trackedType == widget.type && target.trackedId == widget.trackedId);
                      } catch (e) {
                        showErrorbar(context, "Error: Target not found");
                        Navigator.of(context).pop();
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
                    _unitNotifier.value      = _interimTarget!.unit;
                    _orderId                 = _interimTarget!.orderId;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.all(7.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildPrimaryToggle(),
                          const SizedBox(height: 6),
                          const Text("Type of target:"),
                          _buildTypeDropdown(),
                          const SizedBox(height: 6),
                          _buildSelectorDropdown(nutvalues, productsMap),
                          // _buildAmountField(),
                          _buildUnitDropdown(nutvalues, products),
                          // _buildAddButton(),
                        ]
                      ),
                    ),
                  );
                }
              );
            }
          );
        }
      )
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
          decoration: dropdownStyleEnabled,
          value: type,
          items: const [
            DropdownMenuItem(
              value: NutritionalValue,
              child: Text("Nutritional Value"),
            ),
            DropdownMenuItem(
              value: Product,
              child: Text("Product"),
            ),
          ],
          onChanged: (value) {
            _typeNotifier.value = value!;
            _trackedIdNotifier.value = null;
            if (value == Product) {
              _unitNotifier.value = Unit.g;
            } else {
              _unitNotifier.value = null;
            }
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
            onChanged: (product) {
              if (product != null) {
                _trackedIdNotifier.value = product.id;
              }
            },
          );
        } else if (type == NutritionalValue) {
          return DropdownButtonFormField<int>(
            decoration: dropdownStyleEnabled,
            value: trackedId,
            items: nutvalues.map((nutvalue) => DropdownMenuItem<int>(
              value: nutvalue.id,
              child: Text(nutvalue.name),
            )).toList(),
            onChanged: (value) {
              _trackedIdNotifier.value = value!;
            },
          );
        } else {
          return const SizedBox.shrink();
        }
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
          
          return UnitDropdown(
            items: buildUnitItems(units: product?.getAvailableUnits() ?? Unit.values, quantityName: product?.quantityName ?? "x"),
            current: unit ?? Unit.g,
            onChanged: (value) {
              if (value != null) {
                _unitNotifier.value = value;
              }
            },
            enabled: product != null,
          );
        } else if (type == NutritionalValue) {
          var nutvalue = nutvalues.firstWhereOrNull((element) => element.id == trackedId);
          
          if (nutvalue != null) {
            return Text(nutvalue.unit);
          } else {
            return const SizedBox.shrink();
          }
        } else {
          return const SizedBox.shrink();
        }
      }
    );
  }
}