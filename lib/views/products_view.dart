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
  
  @override
  void initState() {
    _dataService = DataService.debug();
    _dataService.open(dbName);
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
				title: const Text("Products"),
				actions: [
					IconButton(
						onPressed: () {
							Navigator.of(context).pushNamed(addProductRoute);
						},
						icon: const Icon(Icons.add)
					)
				]
			),
			body: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
          Expanded(
            child: StreamBuilder(
              stream: _dataService.streamProducts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                if (snapshot.hasData) {
                  var products = snapshot.data as List<Product>;
                  products.sort((a, b) => a.id.compareTo(b.id));
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      var product = snapshot.data![index];
                      return ListTile(
                        title: Text(product.name),
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
            )
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(addMealsRoute);
                  },
                  child: const Text("Add Meal")
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(statsRoute);
                  },
                  child: const Text("Stats")
                ),
              ]
            ),
          ),
        ]
			),
		);
	}
}
