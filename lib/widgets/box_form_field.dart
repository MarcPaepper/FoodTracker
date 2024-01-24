import 'package:flutter/material.dart';

class BoxFormField extends FormField<String> {
  BoxFormField({
    super.key,
    super.onSaved,
    required FormFieldValidator<String> validator,
    String? initialValue,
    AutovalidateMode? autovalidateMode,
    bool? enabled,
  }) : super(
          validator: validator,
          initialValue: initialValue,
          enabled: enabled ?? true,
          builder: (FormFieldState<String> field) {
            // final InputDecoration effectiveDecoration = Theme.of(field.context).inputDecorationTheme; //not working
            //final InputDecoration effectiveDecoration = InputDecoration(
            //  border: OutlineInputBorder(),
            //  labelText: 'Unit',
            //);
            //return InputDecorator(
            //  decoration: effectiveDecoration.copyWith(
            //    errorText: field.errorText,
            //  ),
              //isEmpty: field.value == null || field.value == '',
              /*child:*/ return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    "Hallo" //effectiveDecoration.labelText,
                    //style: effectiveDecoration.labelStyle,
                  ),
                  const SizedBox(height: 8.0),
                  _buildBox(field),
                ],
              );
            //);
          },
        );

  static const double _kBoxSize = 48.0;

  static Widget _buildBox(FormFieldState<String> field) {
    return Container(
      width: _kBoxSize,
      height: _kBoxSize,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
      ),
      child: Center(
        child: Text(
          field.value ?? '',
          style: TextStyle(fontSize: 24.0),
        ),
      ),
    );
  }
}