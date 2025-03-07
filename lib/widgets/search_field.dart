import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/ui.dart';
import 'multi_opacity.dart';

import 'dart:developer' as devtools show log;

class SearchField extends StatefulWidget {
  final TextEditingController textController;
  final Function(String) onChanged;
  final String hintText;
  final bool autofocus;
  final bool whiteMode;
  final bool isDense;
  final double? visibility;
  final List<int>? foundMeals; // If searching, contains the ids of the found meals
  final int? selectedMeal; // If searching, contains the id of the highlighted meal
  final Function(int)? onMealSelected;
  
  const SearchField({
    required this.textController,
    required this.onChanged,
    this.hintText = 'Search',
    this.autofocus = false,
    this.whiteMode = false,
    this.isDense = false,
    this.visibility,
    this.foundMeals,
    this.selectedMeal,
    this.onMealSelected,
    super.key
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    double vertPadding = 9;
    if (kIsWeb) vertPadding += 4;
    if (widget.isDense) vertPadding -= 5;
    
    double vis = _hasFocus ? 1 : widget.visibility ?? 1;
    
    double padVis = min(vis * 54 / 14, 1.0);
    double fldVis = max((vis * 54  - 14) / 40, 0.0);
    
    double height = 40 * fldVis * gsf;
    double iconOpacity   = fldVis == 1 ? 1 : max(fldVis * 3 - 2, 0) * 0.65;
    double textOpacity   = fldVis == 1 ? 1 : max(fldVis * 3 - 2, 0) * 0.5;
    double buttonOpacity = fldVis == 1 ? 1 : max(fldVis * 3 - 2, 0) * 0.75;
    double opacity       = fldVis == 1 ? 1 : sqrt(fldVis) * 0.95;
    
    Widget tf;
    
    if (fldVis == 0) {
      tf = const SizedBox.shrink();
    } else {
      var deco = InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: vertPadding, horizontal: 14) * gsf,
        hintText: widget.hintText,
        hintStyle: TextStyle(fontSize: 16 * gsf, color: Color.fromARGB((textOpacity * 255).round(), 95, 95, 95)),
        isDense: true,
        suffixIconConstraints: widget.isDense ? const BoxConstraints(minHeight: 40 * gsf, maxHeight: 40 * gsf) : null,
        constraints: widget.isDense ? BoxConstraints(maxHeight: height) : null,
        suffixIcon: iconOpacity > 0 ?
          Padding(
            padding: EdgeInsets.only(right: (widget.textController.text.isEmpty ? 10 : (widget.isDense ? 0 : 7)) * gsf),
            child: widget.textController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 24 * gsf),
                  onPressed: () {
                    widget.textController.clear();
                    widget.onChanged('');
                  },
                )
              : Icon(Icons.search, size: 24 * gsf, color: Color.fromARGB((iconOpacity * 255).round(), 72, 72, 72))
          ) : null
      );
      
      if (widget.whiteMode) {
        deco = deco.copyWith(
          fillColor: Colors.white.withAlpha((opacity * 230).round()),
          enabledBorder: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(10.0 * gsf),
            borderSide: const BorderSide(
              width: 2.0 * gsf,
              color: Color.fromARGB(255, 122, 122, 122)
            )
          ),
          disabledBorder: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(10.0 * gsf),
            borderSide: BorderSide(
              width: 2.0 * gsf,
              color: Color.fromARGB((iconOpacity * 255).round(), 122, 122, 122)
            )
          ),
          focusedBorder: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(10.0 * gsf),
            borderSide: BorderSide(
              width: 2.0 * gsf,
              color: Colors.teal.shade800,
            )
          ),
        );
      }
      
      tf = TextField(
        controller: widget.textController,
        enabled: fldVis == 1,
        textAlignVertical: TextAlignVertical.center,
        decoration: deco,
        style: const TextStyle(fontSize: 16 * gsf),
        autofocus: widget.autofocus,
        textInputAction: TextInputAction.search,
        onChanged: (value) => widget.onChanged(value),
      );
    }
    
    if (widget.visibility == null) return tf; // if the widget doesn't use visibility functionality
    
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 4 * padVis, 6, 10 * padVis) * gsf,
      child: Focus(
        onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
        child: Row(
          children: [
            Expanded(child: tf),
            const SizedBox(width: 6 * gsf),
            _buildSelectButton(height, true, buttonOpacity),
            _buildSelectButton(height, false, buttonOpacity),
          ],
        )
      ),
    );
  }
  
  Widget _buildSelectButton(double height, bool up, double opacity) {
    bool enabled = false;
    if (widget.foundMeals != null && widget.selectedMeal != null) {
      int index = widget.foundMeals!.indexOf(widget.selectedMeal!);
      if (up) {
        enabled = index > 0;
      } else {
        enabled = index < widget.foundMeals!.length - 1;
      }
    }
    
    Color color;
    if (enabled) {
      color = Colors.white;
    } else {
      color = const Color.fromARGB(210, 204, 204, 204).withOpacity(0.7 * opacity);
    }
    
    bool isVisible = widget.textController.text.isNotEmpty || _hasFocus;
    const int ms = 500;
    
    return MultiOpacity(
      depth: 2,
      opacity: isVisible ? 1 : 0,
      duration: const Duration(milliseconds: ms),
      child: SizedBox(
        height: height,
        child: AnimatedContainer(
          width: isVisible ? 42 * gsf : 0,
          alignment: Alignment.center,
          duration: const Duration(milliseconds: ms),
          curve: Curves.easeInOut,
          child: IconButton(
            onPressed: () {
              if (enabled) {
                int index = widget.foundMeals!.indexOf(widget.selectedMeal!);
                if (up) {
                  widget.onMealSelected!(widget.foundMeals![index - 1]);
                } else {
                  widget.onMealSelected!(widget.foundMeals![index + 1]);
                }
              }
            },  
            iconSize: 40 * gsf,
            padding: EdgeInsets.zero,
            alignment: Alignment.center,
            constraints: BoxConstraints(minWidth: 42 * gsf, maxWidth: 42 * gsf, minHeight: height, maxHeight: height),
            mouseCursor:    enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
            splashColor:    enabled ? null : Colors.transparent,
            hoverColor:     enabled ? null : Colors.transparent,
            focusColor:     enabled ? null : Colors.transparent,
            highlightColor: enabled ? null : Colors.transparent,
            style: ButtonStyle(
              shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12 * gsf))),
            ),
            icon: Transform.scale(
              scale: 1.2,
              child: Icon(
                up ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 30 * gsf / 1.2,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}