import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/ui.dart';

enum SortType {
  relevancy,
  alphabetical,
  creationDate,
  lastEditDate,
}

enum SortOrder {
  ascending,
  descending,
}

class SortField extends StatefulWidget {
  final SortType sortType;
  final SortOrder sortOrder;
  final Function(SortType, SortOrder) onChanged;

  const SortField({
    required this.sortType,
    required this.sortOrder,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<SortField> createState() => _SortFieldState();
}

class _SortFieldState extends State<SortField> {
  bool _expanded = false;
  
  final _dropdownDecoration = const InputDecoration(
    hintText: 'Search',
    fillColor: Colors.white,
    filled: true,
    contentPadding: kIsWeb ? EdgeInsets.fromLTRB(13, 11, 8, 11) : EdgeInsets.fromLTRB(13, 11, 8, 9),
  );
  
  final _dropdownTextStyle = const TextStyle(
    color: Colors.black,
    fontSize: 16 * gsf,
    fontWeight: FontWeight.normal,
  );

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal.shade50.withAlpha(230),
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10 * gsf)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: kIsWeb ? 12 : 8) * gsf,
      ),
      onPressed: () {
        setState(() {
          _expanded = !_expanded;
        });
      },
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.sort, size: 24 * gsf),
              const SizedBox(width: 26 * gsf, height: 32 * gsf),
              const Text(
                "Sorting",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16 * gsf,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const Spacer(),
              Icon(_expanded ? Icons.arrow_drop_up : Icons.arrow_drop_down, size: 24 * gsf),
            ],
          ),
          if (_expanded)
            // labels and dropdowns
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(5, 16, 0, 5) * gsf,
                        child: const Text('Sort by:', style: TextStyle(fontSize: 16 * gsf)),
                      ),
                      DropdownButtonFormField<SortType>(
                        decoration: _dropdownDecoration,
                        alignment: Alignment.bottomLeft,
                        value: widget.sortType,
                        style: const TextStyle(fontSize: (kIsWeb ? 28 : 20) * gsf),
                        icon: const Icon(Icons.arrow_drop_down),
                        iconSize: 22 * gsf,
                        isDense: true,
                        isExpanded: true,
                        onChanged: (SortType? value) {
                          if (value != null) {
                            widget.onChanged(value, widget.sortOrder);
                          }
                        },
                        items: [
                          DropdownMenuItem(
                            value: SortType.relevancy,
                            child: Text('Relevancy', style: _dropdownTextStyle),
                          ),
                          DropdownMenuItem(
                            value: SortType.alphabetical,
                            child: Text('Name', style: _dropdownTextStyle),
                          ),
                          DropdownMenuItem(
                            value: SortType.creationDate,
                            child: Text('Creation Date', style: _dropdownTextStyle),
                          ),
                          DropdownMenuItem(
                            value: SortType.lastEditDate,
                            child: Text('Last Edit Date', style: _dropdownTextStyle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8 * gsf),
                    ],
                  ),
                ),
                const SizedBox(width: 20 * gsf),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(5, 16, 0, 5) * gsf,
                        child: const Text('Direction:', style: TextStyle(fontSize: 16 * gsf)),
                      ),
                      DropdownButtonFormField<SortOrder>(
                        decoration: _dropdownDecoration,
                        value: widget.sortOrder,
                        style: const TextStyle(fontSize: (kIsWeb ? 28 : 20) * gsf),
                        icon: const Icon(Icons.arrow_drop_down),
                        iconSize: 24 * gsf,
                        isDense: true,
                        isExpanded: true,
                        onChanged: (SortOrder? value) {
                          if (value != null) {
                            widget.onChanged(widget.sortType, value);
                          }
                        },
                        items: [
                          DropdownMenuItem(
                            value: SortOrder.ascending,
                            child: Text('Ascending', style: _dropdownTextStyle),
                          ),
                          DropdownMenuItem(
                            value: SortOrder.descending,
                            child: Text('Descending', style: _dropdownTextStyle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8 * gsf),
                    ],
                  ),
                ),
              ]
            ),
        ],
      ),
    );
  }
}