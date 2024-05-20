import 'package:flutter/material.dart';

class SearchField extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onChanged;
  
  const SearchField({
    required this.searchController,
    required this.onChanged,
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
              icon: const Icon(Icons.close),
              onPressed: () {
                searchController.clear();
                onChanged('');
              },
            )
          : const Icon(Icons.search),
      ),
      textInputAction: TextInputAction.search,
      onChanged: (value) => onChanged(value),
    );
  }
}