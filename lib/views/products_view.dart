import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:food_tracker/utility/theme.dart';

import '../constants/routes.dart';
import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../widgets/loading_page.dart';
import '../widgets/sort_field.dart';
import '../widgets/search_field.dart';
import '../widgets/products_list.dart';

// import "dart:developer" as devtools show log;

class ProductsView extends StatefulWidget {
	const ProductsView({super.key});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  late final DataService _dataService;
  // final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  SortType _sortType = SortType.relevancy;
  SortOrder _sortOrder = SortOrder.ascending;
  
  @override
  void initState() {
    _dataService = DataService.current();
    // _dataService.streamProducts().listen((_) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     if (_scrollController.hasClients) {
    //       _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    //     }
    //   });
    // });
    super.initState();
  }
  
  @override
  void dispose() {
    // _scrollController.dispose();
    super.dispose();
  }
  
	@override
	Widget build(BuildContext context) {
		return StreamBuilder(
      stream: _dataService.streamProducts(),
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.white,
              child: Padding(
                padding: kIsWeb ? const EdgeInsets.fromLTRB(12, 18, 12, 0) : const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: SortField(
                  sortType: _sortType,
                  sortOrder: _sortOrder,
                  onChanged: (sortType, sortOrder) {
                    setState(() {
                      _sortType = sortType;
                      _sortOrder = sortOrder;
                    });
                  }
                ),
              ),
            ),
            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: kIsWeb ? 16.0 : 12.0),
                child: SearchField(
                  searchController: _searchController,
                  onChanged: (value) => setState(() {
                    _isSearching = value.isNotEmpty;
                  }),
                ),
              ),
            ),
            Expanded(
              child: _buildProductList(snapshot)
            ),
            _buildAddButton(snapshot.hasData ? snapshot.data as List<Product> : []),
          ]
        );
      }
		);
	}
  
  Widget _buildProductList(AsyncSnapshot snapshot) {
    if (snapshot.hasError) {
      return Text("Error: ${snapshot.error}");
    }
    if (snapshot.hasData) {
      var products = snapshot.data as List<Product>;
      return ListView(
        physics: const ClampingScrollPhysics(),
        // controller: _scrollController,
        children: getProductTiles(
          context: context,
          products: products,
          search: _searchController.text,
          sorting: (_sortType, _sortOrder),
          onSelected: (name, id) => Navigator.pushNamed (
            context,
            editProductRoute,
            arguments: (name, false),
          ),
          onLongPress: (name, id) {
            Navigator.pushNamed (
              context,
              addProductRoute,
              arguments: (name, true),
            );
          },
        ),
      );
    }
    return const LoadingPage();
  }
  
  Widget _buildAddButton(List<Product> products) {
    String? name;
    String? nameQuotation;
    // check if the search term matches one of the products
    if (_isSearching) {
      var index = products.indexWhere((product) => product.name == _searchController.text);
      name = index == -1 ? _searchController.text : null;
      nameQuotation = index == -1 ? "\"${_searchController.text}\"" : null;
    }
    
    return ElevatedButton.icon(
      style: addButtonStyle,
      icon: const Icon(Icons.add),
      label: Padding(
        padding: const EdgeInsets.only(left: 5.0),
        child: Text("Add ${nameQuotation ?? "Product"}"),
      ),
      onPressed: () {
        Navigator.pushNamed (
          context,
          addProductRoute,
          arguments: (name, false),
        );
      },
    );
  }
}