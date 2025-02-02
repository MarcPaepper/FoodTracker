import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/ui.dart';

class SearchField extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onChanged;
  final bool autofocus;
  
  const SearchField({
    required this.searchController,
    required this.onChanged,
    this.autofocus = false,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: searchController,
      textAlignVertical: TextAlignVertical.center,
      
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: kIsWeb ? 13 : 9, horizontal: 14) * gsf,
        hintText: 'Search',
        suffixIcon: Padding(
          padding: EdgeInsets.only(right: (searchController.text.isNotEmpty ? 7 : 10) * gsf),
          child: searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 24 * gsf),
                onPressed: () {
                  searchController.clear();
                  onChanged('');
                },
              )
            : const Icon(Icons.search, size: 24 * gsf),
        ),
      ),
      style: const TextStyle(fontSize: 16 * gsf),
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      onChanged: (value) => onChanged(value),
    );
  }
}