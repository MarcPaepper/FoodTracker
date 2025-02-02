import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:food_tracker/utility/theme.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/ui.dart';
import '../services/data/data_objects.dart';

// import 'dart:developer' as devtools show log;

class UnitDropdown extends StatefulWidget {
  final Map<Unit, Widget> items;
  final Unit current;
  final bool? enabled;
  final void Function()? intermediateSave;
  final Function(Unit? unit)? onChanged;
  final bool skipTraversal;
  
  const UnitDropdown({
    super.key,
    required this.items,
    required this.current,
    this.enabled,
    this.intermediateSave,
    this.onChanged,
    this.skipTraversal = !kIsWeb,
  });

  @override
  State<UnitDropdown> createState() => _UnitDropdownState();
}

class _UnitDropdownState extends State<UnitDropdown> {
  @override
  Widget build(BuildContext context) {
    var items = widget.items;
    bool enabled = widget.enabled ?? true;
    
    if (!enabled) {
      // reduce opacity of items
      items = items.map((key, value) => MapEntry(key, Opacity(
        opacity: 0.4,
        child: value,
      )));
    }
    
    return ExcludeFocusTraversal(
      excluding: widget.skipTraversal,
      child: DropdownButtonFormField(
        decoration: enabled ? dropdownStyleEnabled : dropdownStyleDisabled,
        isExpanded: true,
        value: widget.current,
        style: const TextStyle(fontSize: 50 * gsf),
        iconSize: 20 * gsf,
        items: items.entries.map((entry) => DropdownMenuItem<Unit>(
          value: entry.key,
          child: entry.value,
        )).toList(),
        onTap: () => widget.intermediateSave?.call(),
        onChanged: enabled ? widget.onChanged : null,
      ),
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
            fontSize: 16 * gsf,
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
            fontSize: 16 * gsf,
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
    
    items[unit] = Padding(
      padding: const EdgeInsets.symmetric(vertical: 35 * gsf - 35),
      child: items[unit],
    );
  }
  
  return items;
}