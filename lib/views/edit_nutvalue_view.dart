import 'package:flutter/material.dart';
import 'package:food_tracker/widgets/multi_value_listenable_builder.dart';

import '../constants/data.dart';
import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../utility/modals.dart';
import '../widgets/amount_field.dart';
import '../widgets/loading_page.dart';

// import "dart:developer" as devtools show log;

class EditNutritionalValueView extends StatefulWidget {
  final int? nutvalueId;
  final bool? isEdit;
  
  const EditNutritionalValueView({Key? key, this.isEdit, this.nutvalueId}) : super(key: key);

  @override
  State<EditNutritionalValueView> createState() => _EditNutritionalValueViewState();
}

class _EditNutritionalValueViewState extends State<EditNutritionalValueView> {
  final _dataService = DataService.current();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _unit;
  final _showFullName = ValueNotifier(true);
  final _hasTarget = ValueNotifier(false);
  final _targetNotifier = ValueNotifier(0.0);
  late final TextEditingController _target;
  final _alwaysShowTarget = ValueNotifier(false);
  
  int? _orderId;
  
  late final bool isEdit;
  
  // late NutritionalValue _prevValue;
  NutritionalValue? _interimValue;
  
  @override
  void initState() {
    if (widget.isEdit == null || (widget.isEdit! && widget.nutvalueId == null)) {
      Future(() {
        showErrorbar(context, "Error: Value not found");
        Navigator.of(context).pop();
      });
    }
    
    isEdit = widget.isEdit ?? false;
    
    _name = TextEditingController();
    _unit = TextEditingController(text: "g");
    _target = TextEditingController();
    _dataService.open(dbName);
    super.initState();
  }
  
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Nutritional Value" : "Edit Nutritional Value"),
        // show the delete button if editing
        actions: isEdit ? [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Delete Nutritional Value"),
                  content: const Text("If you delete this Nutritional Value, all associated data will be lost."),
                  actions: [
                    TextButton(
                      onPressed: () {
                        _dataService.deleteNutritionalValue(widget.nutvalueId!);
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text("Delete"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Cancel"),
                    )
                  ],
                )
              );
            },
            icon: const Icon(Icons.delete),
          )
        ] : null
      ),
      body: FutureBuilder(
        future: _dataService.getAllNutritionalValues(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              final nutValues = snapshot.data as List<NutritionalValue>;
              if (isEdit) {
                if (_interimValue == null) {
                  try {
                    _interimValue = nutValues.firstWhere((nval) => nval.id == widget.nutvalueId);
                  } catch (e) {
                    return const Text("Error: Value not found");
                  }
                }
              } else {
                _interimValue = NutritionalValue(-1, -1, "", "g", true, false, 0, false);
              }
              if (_interimValue != null) {
                _orderId                = _interimValue!.orderId;
                _name.text              = _interimValue!.name;
                _unit.text              = _interimValue!.unit;
                _showFullName.value     = _interimValue!.showFullName;
                _hasTarget.value        = _interimValue!.hasTarget;
                _targetNotifier.value   = _interimValue!.target;
                _target.text            = _interimValue!.target.toString();
                _alwaysShowTarget.value = _interimValue!.alwaysShowTarget;
              }
              return Padding(
                padding: const EdgeInsets.all(7.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildNameField(nutValues),
                      _buildUnitField(),
                      _buildShowFullNameToggle(),
                      _buildTargetSwitch(),
                      _buildTargetField(),
                      _buildAlwaysShowTargetSwitch(),
                      _buildAddButton(),
                    ]
                  ),
                ),
              );
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
            default:
              return const LoadingPage();
          }
        }
      )
    );
  }
  
  Widget _buildNameField(List<NutritionalValue> nutValues) => Padding(
    padding: const EdgeInsets.all(8.0),
    child: TextFormField(
      controller: _name,
      decoration: const InputDecoration(
        labelText: "Name"
      ),
      validator: (String? value) {
        for (var prod in nutValues) {
          if (prod.name == value && prod.id != widget.nutvalueId) {
            return "Already taken";
          }
        }
        if (value == null || value.isEmpty) {
          return "Required Field";
        }
        return null;
      },
      onChanged: (value) {
        _interimValue = NutritionalValue.copyWith(_interimValue!, newName: value);
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    ),
  );
  
  Widget _buildUnitField() => Padding(
    padding: const EdgeInsets.all(8.0),
    child: TextFormField(
      controller: _unit,
      decoration: const InputDecoration(
        labelText: "Unit"
      ),
      validator: (String? value) {
        if (value == null || value.isEmpty) {
          return "Required Field";
        }
        return null;
      },
      onChanged: (value) {
        _interimValue = NutritionalValue.copyWith(_interimValue!, newUnit: value);
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    ),
  );
  
  Widget _buildShowFullNameToggle() => ValueListenableBuilder(
    valueListenable: _showFullName,
    builder: (context, value, child) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: SwitchListTile(
          visualDensity: VisualDensity.compact,
          title: const Text("Show Full Name"),
          value: value,
          onChanged: (newValue) {
            _showFullName.value = newValue;
            _interimValue = NutritionalValue.copyWith(_interimValue!, newShowFullName: newValue);
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      );
    }
  );
  
  Widget _buildAddButton() => Padding(
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
        final name = _name.text;
        final unit = _unit.text;
        final showFullName = _showFullName.value;
        final hasTarget = _hasTarget.value;
        final target = _targetNotifier.value;
        final alwaysShowTarget = _alwaysShowTarget.value;
        final isValid = _formKey.currentState!.validate();
        if (isValid) {
          if (isEdit) {
            if (_orderId == null) {
              showErrorbar(context, "Error: Order ID not found");
              return;
            }
            var nval = NutritionalValue(widget.nutvalueId!, _orderId!, name, unit, showFullName, hasTarget, target, alwaysShowTarget);
            _dataService.updateNutritionalValue(nval);
          } else {
            var nval = NutritionalValue(-1, -1, name, unit, showFullName, hasTarget, target, alwaysShowTarget);
            _dataService.createNutritionalValue(nval);
          }
          Navigator.of(context).pop();
        }
      },
      child: Text(isEdit ? "Update" : "Add"),
    ),
  );
  
  Widget _buildTargetSwitch() => ValueListenableBuilder(
    valueListenable: _hasTarget,
    builder: (context, value, child) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: SwitchListTile(
          value: value,
          controlAffinity: ListTileControlAffinity.leading,
          visualDensity: VisualDensity.compact,
          onChanged: (newValue) {
            _hasTarget.value = newValue;
            _interimValue = NutritionalValue.copyWith(_interimValue!, newHasTarget: newValue);
          },
          title: const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text("Daily target"),
          ),
        ),
      );
    }
  );
  
  Widget _buildTargetField() => MultiValueListenableBuilder(
    listenables: [
      _hasTarget,
      _target,
    ],
    builder: (context, values, child) {
      final hasTarget = values[0] as bool;
      // final target = values[1] as String;
      
      return AmountField(
        controller: _target,
        enabled: hasTarget,
        onChangedAndParsed: (value) {
          _targetNotifier.value = value;
        },
      );
    }
  );
  
  Widget _buildAlwaysShowTargetSwitch() => MultiValueListenableBuilder(
    listenables: [
      _hasTarget,
      _alwaysShowTarget,
    ],
    builder: (context, values, child) {
      final hasTarget = values[0] as bool;
      final alwaysShowTarget = values[1] as bool;
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: SwitchListTile(
          value: alwaysShowTarget,
          controlAffinity: ListTileControlAffinity.leading,
          visualDensity: VisualDensity.compact,
          onChanged: hasTarget ? (newValue) {
            _alwaysShowTarget.value = newValue;
            _interimValue = NutritionalValue.copyWith(_interimValue!, newAlwaysShowTarget: newValue);
          } : null,
          title: const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text("Always show target"),
          ),
        ),
      );
    }
  );
}