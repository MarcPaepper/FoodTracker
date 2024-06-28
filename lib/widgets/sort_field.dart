import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    contentPadding: kIsWeb ? EdgeInsets.fromLTRB(13, 11, 8, 11) : EdgeInsets.fromLTRB(13, 110, 8, 9),
  );
  
  final _dropdownTextStyle = const TextStyle(
    color: Colors.black,
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  @override
  Widget build(BuildContext context) {
    // The widget consists of a button saysing "Sorting"
    // If the button is pressed, two dropdowns appear below
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal.shade50.withAlpha(230),
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: kIsWeb ? 12 : 8),
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
              const Icon(Icons.sort),
              const SizedBox(width: 26, height: 32),
              const Text(
                'Sorting',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const Spacer(),
              Icon(_expanded ? Icons.arrow_drop_up : Icons.arrow_drop_down),
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
                      const Padding(
                        padding: EdgeInsets.fromLTRB(5, 16, 0, 5),
                        child: Text('Sort by:'),
                      ),
                      DropdownButtonFormField<SortType>(
                        decoration: _dropdownDecoration,
                        alignment: Alignment.bottomLeft,
                        value: widget.sortType,
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
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(5, 16, 0, 5),
                        child: Text('Direction:'),
                      ),
                      DropdownButtonFormField<SortOrder>(
                        decoration: _dropdownDecoration,
                        value: widget.sortOrder,
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
                      const SizedBox(height: 8),
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