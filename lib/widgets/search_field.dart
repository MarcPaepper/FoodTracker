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
        hintText: 'Search',
        suffixIcon: searchController.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.close, size: 24 * gsf),
              onPressed: () {
                searchController.clear();
                onChanged('');
              },
            )
          : const Icon(Icons.search),
      ),
      style: const TextStyle(fontSize: 16 * gsf),
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      onChanged: (value) => onChanged(value),
    );
  }
}