// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import "dart:developer" as devtools show log;

import '../constants/ui.dart';
import '../utility/merge_input_decoration.dart';
import '../utility/text_logic.dart';
import '../utility/theme.dart';

class AmountField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final bool canBeEmpty;
  final bool autofocus;
  final Function(double)? onChangedAndParsed;
  final Function()? onEmptied;
  final double? padding;
  final String? hintText;
  final Color? borderColor;
  final Color? fillColor;
  final Color? hintColor;
  final TextInputAction textInputAction;
  
  const AmountField({
    required this.controller,
    this.focusNode,
    this.enabled = true,
    this.onChangedAndParsed,
    this.onEmptied,
    this.padding,
    this.hintText,
    this.canBeEmpty = false,
    this.autofocus = false,
    this.borderColor,
    this.fillColor,
    this.hintColor,
    this.textInputAction = TextInputAction.next,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    var inputTheme = getTheme().inputDecorationTheme;
    
    var inputDec = InputDecoration(
      contentPadding: const EdgeInsets.symmetric(vertical: kIsWeb ? 13 : 9, horizontal: 14) * gsf,
      hintText: hintText,
      hintStyle: TextStyle(color: hintColor ?? inputTheme.hintStyle?.color, fontSize: 16 * gsf),
      fillColor: fillColor ?? inputTheme.fillColor,
    );
    
    if (borderColor != null) {
      var borderTheme = inputTheme.enabledBorder as UnderlineInputBorder;
      inputDec = MergeInputDecoration.merge(inputDec, InputDecoration(
        enabledBorder: UnderlineInputBorder(
          borderRadius: borderTheme.borderRadius,
          borderSide: BorderSide(
            width: borderTheme.borderSide.width,
            color: borderColor!,
          )
        ),
      ));
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding ?? 12 * gsf),
      child: Focus(
        skipTraversal: true,
        onFocusChange: (bool hasFocus) {
          if (hasFocus) {
            controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.value.text.length);
          }
        },
        child: TextFormField(
          enabled: enabled,
          decoration: inputDec,
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
          textInputAction: textInputAction,
          validator: (String? value) => enabled ? numberValidator(value, canBeEmpty: canBeEmpty) : null,
          autovalidateMode: AutovalidateMode.always,
          onChanged: (String? value) {
            if (value == null) return;
            else if (value.isEmpty && onEmptied != null) {
              onEmptied!();
            }
            else if (value.isNotEmpty) {
              try {
                value = value.replaceAll(",", ".");
                var cursorPos = controller.selection.baseOffset;
                controller.text = value;
                controller.selection = TextSelection.fromPosition(TextPosition(offset: cursorPos));
                
                var input = double.parse(value);
                if (input.isFinite && onChangedAndParsed != null) {
                  onChangedAndParsed!(input);
                }
              } catch (e) {
                devtools.log("Error: Invalid number in amount field");
              }
            }
          },
        ),
      ),
    );
  }
}