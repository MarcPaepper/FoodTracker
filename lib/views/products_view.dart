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
            title: Text(product.name),
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
}
