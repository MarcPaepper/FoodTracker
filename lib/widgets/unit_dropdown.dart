import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/data/data_objects.dart';

class UnitDropdown extends StatefulWidget {
  final Map<Unit, Widget> items;
  final Unit current;
  final bool? enabled;
  final Function(Unit? unit)? onChanged;
  
  const UnitDropdown({
    super.key,
    required this.items,
    required this.current,
    this.enabled,
    this.onChanged,
  });

  @override
  State<UnitDropdown> createState() => _UnitDropdownState();
}

class _UnitDropdownState extends State<UnitDropdown> {
  @override
  Widget build(BuildContext context) {
    var items = widget.items;
    bool enabled = widget.enabled ?? true;
    
    var decoration = enabled
      ? const InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      ) 
      : InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        // no enabled border
        enabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
            width: 3.5,
            color: Colors.grey.shade300
          )
        ),
      );
    
    if (!enabled) {
      // reduce opacity of items
      items = items.map((key, value) => MapEntry(key, Opacity(
        opacity: 0.4,
        child: value,
      )));
    }
    
    return DropdownButtonFormField<Unit>(
      decoration: decoration,
      isExpanded: true,
      value: widget.current,
      items: items.entries.map((entry) => DropdownMenuItem<Unit>(
        value: entry.key,
        child: entry.value,
      )).toList(),
      onChanged: enabled ? widget.onChanged : null,
    );
  }
}

Map<Unit, Widget> buildUnitItems({
  List<Unit>? units,
  bool verbose = true,
  int? maxWidth,
  required String quantityName
}) {
  var items = <Unit, Widget>{};
  units ??= Unit.values;
  
  for (var unit in units) {
    if (unit == Unit.quantity && verbose) {
      items[unit] = RichText(
        text: TextSpan(
          style: TextStyle(
            fontFamily: GoogleFonts.nunitoSans().fontFamily,
            fontSize: 16,
            color: Colors.black,
          ),
          text: quantityName,
          children: const [
            TextSpan(
              text: "  (quantity)",
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    } else {
      items[unit] = RichText(
        text: TextSpan(
          text: unit == Unit.quantity ? quantityName : unitToString(unit),
          style: TextStyle(
            fontFamily: GoogleFonts.nunitoSans().fontFamily,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      );
    }
    
    // limit width of items if maxWidth is set
    if (maxWidth != null) {
      items[unit] = SizedBox(
        width: maxWidth.toDouble(),
        child: items[unit],
      );
    }
  }
  
  return items;
}