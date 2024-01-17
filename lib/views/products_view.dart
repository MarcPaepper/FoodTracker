import 'package:flutter/material.dart';
import 'package:food_tracker/constants/routes.dart';
import 'package:food_tracker/constants/data.dart';
import 'package:food_tracker/services/data/data_objects.dart';
import 'package:food_tracker/services/data/data_service.dart';
// import "dart:developer" as devtools show log;

class ProductsView extends StatefulWidget {
	const ProductsView({super.key});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  late final DataService _dataService;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  
  @override
  void initState() {
    _dataService = DataService.current();
    _dataService.open(dbName);
    _dataService.streamProducts().listen((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    });
    super.initState();
  }
  
  @override
  void dispose() {
    _dataService.close();
    super.dispose();
  }
  
	@override
	Widget build(BuildContext context) {
		return Scaffold (
			appBar: AppBar(
				title: const Text("Products")
			),
			body: StreamBuilder(
        stream: _dataService.streamProducts(),
        builder: (context, snapshot) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      suffixIcon: _isSearching
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _isSearching = false;
                            });
                          },
                        )
                      : const Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _isSearching = value.isNotEmpty;
                      });
                    },
                  ),
                ),
              ),
              Expanded(
                child: _buildProductList(snapshot)
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 210, 235, 198),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                  textStyle: Theme.of(context).textTheme.bodyLarge,
                ),
                icon: const Icon(Icons.add),
                label: const Padding(
                  padding: EdgeInsets.only(left: 5.0),
                  child: Text("Add Product"),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed(addProductRoute);
                },
              )
            ]
          );
        }
			)
		);
	}
  
  Widget _buildProductList(AsyncSnapshot snapshot) {
    if (snapshot.hasError) {
      return Text("Error: ${snapshot.error}");
    }
    if (snapshot.hasData) {
      var products = snapshot.data as List<Product>;
      
      // only show products that contain every word in the search
      var search = _searchController.text.split(" ");
      products = products.where((product) {
        var name = product.name.toLowerCase();
        return search.every((word) => name.contains(word.toLowerCase()));
      }).toList();
      
      // sort products by id
      products.sort((a, b) => a.id.compareTo(b.id));
      
      var length = products.length;
      return ListView.builder(
        controller: _scrollController,
        itemCount: length,
        itemBuilder: (context, index) {
          var product = products[index];
          bool dark = (length - index) % 2 == 1;
          var color = dark ? const Color.fromARGB(255, 237, 246, 253) : Colors.white;
          
          return ListTile(
            title: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.copyWith(
                  color: Colors.black,
                  fontSize: 16.5,
                ),
                children: highlightOccurrences(product.name, search),
              ),
            ),
            tileColor: color,
            onTap: () {
              Navigator.pushNamed (
                context,
                editProductRoute,
                arguments: product.id,
              );
            },
          );
        }
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(50.0),
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            color: Colors.teal.shade500
          ),
        ),
      )
    );
  }
  
  List<TextSpan> highlightOccurrences(String source, List<String> search) {
    var spans = <TextSpan>[];
    var lowerSource = source.toLowerCase();
    var index = 0;
    for (var word in search) {
      var lowerWord = word.toLowerCase();
      var wordIndex = lowerSource.indexOf(lowerWord, index);
      if (wordIndex == -1) {
        continue;
      }
      spans.add(TextSpan(
        text: source.substring(index, wordIndex),
      ));
      spans.add(TextSpan(
        text: source.substring(wordIndex, wordIndex + word.length),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      index = wordIndex + word.length;
    }
    spans.add(TextSpan(
      text: source.substring(index),
    ));
    return spans;
  }
}