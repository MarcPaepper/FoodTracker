import 'package:flutter/material.dart';

import '../constants/data.dart';
import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../utility/modals.dart';
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
    _dataService.open(dbName); // why?
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
                _interimValue = NutritionalValue(-1, -1, "", "g", true);
              }
              if (_interimValue != null) {
                _orderId                = _interimValue!.orderId;
                _name.text              = _interimValue!.name;
                _unit.text              = _interimValue!.unit;
                _showFullName.value     = _interimValue!.showFullName;
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
        _interimValue = _interimValue!.copyWith(newName: value);
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
        _interimValue = _interimValue!.copyWith(newUnit: value);
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
            _interimValue = _interimValue!.copyWith(newShowFullName: newValue);
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
        final isValid = _formKey.currentState!.validate();
        if (isValid) {
          if (isEdit) {
            if (_orderId == null) {
              showErrorbar(context, "Error: Order ID not found");
              return;
            }
            var nval = NutritionalValue(widget.nutvalueId!, _orderId!, name, unit, showFullName);
            _dataService.updateNutritionalValue(nval);
          } else {
            var nval = NutritionalValue(-1, -1, name, unit, showFullName);
            _dataService.createNutritionalValue(nval);
          }
          Navigator.of(context).pop();
        }
      },
      child: Text(isEdit ? "Update" : "Add"),
    ),
  );
}