import 'package:flutter/material.dart';
import 'package:food_tracker/constants/data.dart';
import 'package:food_tracker/services/data/data_objects.dart';
// import "dart:developer" as devtools show log;

import 'package:food_tracker/services/data/data_service.dart';
import 'package:food_tracker/utility/modals.dart';
import 'package:food_tracker/widgets/loading_page.dart';

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
  var _showFullName = ValueNotifier(false);
  
  late final int _orderId;
  
  late final bool isEdit;
  
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
                try {
                  final value = nutValues.firstWhere((nval) => nval.id == widget.nutvalueId);
                  
                  _orderId            = value.orderId;
                  _name.text          = value.name;
                  _unit.text          = value.unit;
                  _showFullName.value = value.showFullName;
                } catch (e) {
                  return const Text("Error: Value not found");
                }
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
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  
  Widget _buildShowFullNameToggle() => ValueListenableBuilder(
      valueListenable: _showFullName,
      builder: (context, value, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SwitchListTile(
            title: const Text("Show Full Name"),
            value: value,
            onChanged: (newValue) => _showFullName.value = newValue,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        );
      }
    );
  
  Widget _buildAddButton() => Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.teal.shade400),
          foregroundColor: MaterialStateProperty.all(Colors.white),
          minimumSize: MaterialStateProperty.all(const Size(double.infinity, 60)),
          textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 16)),
          shape: MaterialStateProperty.all(const RoundedRectangleBorder(
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
              var nval = NutritionalValue(widget.nutvalueId!, _orderId, name, unit, showFullName);
              _dataService.updateNutritionalValue(nval);
            } else {
              var nval = NutritionalValue(-1, _orderId, name, unit, showFullName);
              _dataService.createNutritionalValue(nval);
            }
            Navigator.of(context).pop();
          }
        },
        child: Text(isEdit ? "Update" : "Add"),
      ),
    );
}