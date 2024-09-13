import 'package:flutter/material.dart';

import '../constants/data.dart';
import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../utility/modals.dart';
import '../widgets/loading_page.dart';

// import 'dart:developer' as devtools show log;

class EditTargetView extends StatefulWidget {
  final Type? type;
  final int? trackedId;
  final bool? isEdit;
  
  const EditTargetView({Key? key, this.isEdit, this.type, this.trackedId}) : super(key: key);

  @override
  State<EditTargetView> createState() => _EditTargetViewState();
}

class _EditTargetViewState extends State<EditTargetView> {
  final _dataService = DataService.current();
  final _formKey = GlobalKey<FormState>();
  final _typeNotifier = ValueNotifier<Type>(NutritionalValue);
  final _trackedIdNotifier = ValueNotifier<int>(-1);
  
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
                  final nutvalues = snapshotN.data as List<NutritionalValue>;
                  final targets = snapshotT.data as List<Target>;
                  
                  if (isEdit) {
                    _interimTarget = targets.firstWhere((element) => element.type == widget.type && element.trackedId == widget.trackedId);
                  }
                  
                  return Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        DropdownButton<Type>(
                          value: _typeNotifier.value,
                          onChanged: (value) {
                            _typeNotifier.value = value!;
                          },
                          items: [
                            for (var type in [Product, NutritionalValue])
                              DropdownMenuItem(
                                value: type,
                                child: Text(type == Product ? "Product" : "Nutritional Value"),
                              ),
                          ],
                        ),
                        if (_typeNotifier.value == Product)
                          DropdownButton<Product>(
                            value: products.firstWhere((element) => element.id == _trackedIdNotifier.value),
                            onChanged: (value) {
                              _trackedIdNotifier.value = value.id!;
                            },
                            items: [
                              for (var product in products)
                                DropdownMenuItem(
                                  value: product,
                                  child: Text(product.name),
                                ),
                            ],
                          ),
                        if (_typeNotifier.value == NutritionalValue)
                }
              )
            }
          )
        }
      )
    );
  }
}