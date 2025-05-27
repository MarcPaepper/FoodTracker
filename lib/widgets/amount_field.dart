// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import "dart:developer" as devtools show log;

import '../constants/ui.dart';
import '../utility/merge_input_decoration.dart';
import '../utility/text_logic.dart';
import '../utility/theme.dart';

class AmountField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final bool canBeEmpty;
  final bool autofocus;
  final bool allowMath;
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
    this.allowMath = true,
    this.borderColor,
    this.fillColor,
    this.hintColor,
    this.textInputAction = TextInputAction.next,
    super.key
  });

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  String? _labelText;
  
  @override
  Widget build(BuildContext context) {
    var inputTheme = getTheme().inputDecorationTheme;
    
    var inputDec = InputDecoration(
      contentPadding: const EdgeInsets.symmetric(vertical: kIsWeb ? 13 : 9, horizontal: 14) * gsf,
      hintText: widget.hintText,
      hintStyle: TextStyle(color: widget.hintColor ?? inputTheme.hintStyle?.color, fontSize: 16 * gsf),
      labelText: _labelText,
      fillColor: widget.fillColor ?? inputTheme.fillColor,
      errorStyle: TextStyle(
        color: Colors.blue,
        fontSize: 14 * gsf,
      ),
    );
    if (_labelText != null) {
      inputDec = MergeInputDecoration.merge(inputDec, InputDecoration(
        contentPadding: const EdgeInsets.fromLTRB(12, 6, 12, 2) * gsf,
      ));
    }
    
    if (widget.borderColor != null) {
      var borderTheme = inputTheme.enabledBorder as UnderlineInputBorder;
      inputDec = MergeInputDecoration.merge(inputDec, InputDecoration(
        enabledBorder: UnderlineInputBorder(
          borderRadius: borderTheme.borderRadius,
          borderSide: BorderSide(
            width: borderTheme.borderSide.width,
            color: widget.borderColor!,
          )
        ),
      ));
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.padding ?? 12 * gsf),
      child: Focus(
        skipTraversal: true,
        onFocusChange: (bool hasFocus) {
          if (hasFocus) {
            widget.controller.selection = TextSelection(baseOffset: 0, extentOffset: widget.controller.value.text.length);
          }
        },
        child: TextFormField(
          enabled: widget.enabled,
          decoration: inputDec,
          controller: widget.controller,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
          textInputAction: widget.textInputAction,
          validator: (String? value) => widget.enabled ? numberValidator(value, canBeEmpty: widget.canBeEmpty, allowMath: widget.allowMath) : null,
          autovalidateMode: AutovalidateMode.always,
          onChanged: (String? value) {
            if (value == null) return;
            else if (value.isEmpty && widget.onEmptied != null) {
              widget.onEmptied!();
            }
            else if (value.isNotEmpty) {
              try {
                value = value.replaceAll(",", ".");
                var cursorPos = widget.controller.selection.baseOffset;
                widget.controller.text = value;
                widget.controller.selection = TextSelection.fromPosition(TextPosition(offset: cursorPos));
                
                double? input;
                String? newText;
                if (widget.allowMath && value.contains(RegExp(r'[\*\+\-\/]'))) {
                  try {
                    input = evaluateNumberString(value);
                    newText = "= $input";
                  } catch (e) {
                    newText = "= ???";
                  }
                } else {
                  input = double.parse(value);
                }
                
                if (_labelText != newText) {
                  setState(() {
                    _labelText = newText;
                  });
                }
                if (input != null && input.isFinite && widget.onChangedAndParsed != null) {
                  widget.onChangedAndParsed!(input);
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