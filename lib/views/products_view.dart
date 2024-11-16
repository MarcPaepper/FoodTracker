import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:food_tracker/services/data/async_provider.dart';
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
  SortOrder _sortOrder = SortOrder.descending;
  
  @override
  void initState() {
    _dataService = DataService.current();
    super.initState();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
	@override
	Widget build(BuildContext context) {
		return StreamBuilder(
      stream: _dataService.streamProducts(),
      builder: (contextP, snapshotP) {
        return StreamBuilder(
          stream: AsyncProvider.streamRelevancies(),
          builder: (contextR, snapshotR) {
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
                  child: _buildProductList(snapshotP, snapshotR)
                ),
                _buildAddButton(snapshotP.hasData ? snapshotP.data as List<Product> : []),
              ]
            );
          }
        );
      }
		);
	}
  
  Widget _buildProductList(AsyncSnapshot snapshotP, AsyncSnapshot snapshotR) {
    if (snapshotP.hasError) return Text("Error: ${snapshotP.error}");
    if (snapshotR.hasError) return Text("Error: ${snapshotR.error}");
    if (snapshotP.hasData) {
      var products = snapshotP.data as List<Product>;
      var relevancies = snapshotR.hasData ? snapshotR.data as Map<int, double> : null;
      
      if (products.isEmpty) {
        return SizedBox(
          width: double.infinity,
          child: Text(
            "\n No products found",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
              fontSize: 16.0,
            ),
          ),
        );
      }
      
      return ListView(
        physics: const ClampingScrollPhysics(),
        children: getProductTiles(
          context: context,
          products: products,
          search: _searchController.text,
          sorting: (_sortType, _sortOrder),
          relevancies: relevancies,
          colorFromTop: true,
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
        ) + [
          // A text widget saying how many products are displayed
          products.length > 10 ? Container(
            color: products.length % 2 == 0 ? Colors.grey[100] : Colors.white,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  "${products.length} Products",
                  style: TextStyle(
                    color: Colors.grey[600],
                    // italic
                    fontStyle: FontStyle.italic,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
          ) : Container(),
        ],
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