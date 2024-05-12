// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:food_tracker/subviews/ingredients_box.dart';
import 'package:food_tracker/utility/text_logic.dart';
import 'package:food_tracker/widgets/unit_dropdown.dart';

import 'package:food_tracker/constants/routes.dart';
import 'package:food_tracker/services/data/data_objects.dart';
import 'package:food_tracker/services/data/data_service.dart';
import 'package:food_tracker/utility/modals.dart';
import 'package:food_tracker/widgets/loading_page.dart';

import "dart:developer" as devtools show log;

import '../subviews/conversion_boxes.dart';
import '../subviews/nutrients_box.dart';
import '../utility/data_logic.dart';

class EditProductView extends StatefulWidget {
  final String? productName;
  final bool? isEdit;
  final bool isCopy; // If the product settings should be copied from another product
  
  const EditProductView({
    this.isEdit,
    this.productName,
    this.isCopy = false,
    Key? key,
  }) : super(key: key);

  @override
  State<EditProductView> createState() => _EditProductViewState();
}

class _EditProductViewState extends State<EditProductView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  bool _loaded = false;
  bool _error = false;
  
  final _dataService = DataService.current();
  
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _productNameController;
  late final TextEditingController _densityAmount1Controller;
  late final TextEditingController _densityAmount2Controller;
  late final TextEditingController _quantityAmount1Controller;
  late final TextEditingController _quantityAmount2Controller;
  late final TextEditingController _quantityNameController;
  late final TextEditingController _resultingAmountController;
  late final TextEditingController _nutrientAmountController;
  
  final List<TextEditingController> _ingredientAmountControllers = [];
  final List<TextEditingController> _nutrientAmountControllers = [];
  
  late final bool _isEdit;
  
  int _id = -1;
  late Product _prevProduct;
  Product? _interimProduct;
  // used to store the product while the user navigates to another page, can contain formal errors
  
  final _densityConversionNotifier = ValueNotifier<Conversion>(Conversion.defaultDensity());
  final _quantityConversionNotifier = ValueNotifier<Conversion>(Conversion.defaultQuantity());
  final _defaultUnitNotifier = ValueNotifier<Unit>(Unit.g);
  
  final _autoCalcAmountNotifier = ValueNotifier<bool>(false);
  final _resultingAmountNotifier = ValueNotifier<double>(0);
  final _ingredientsUnitNotifier = ValueNotifier<Unit>(Unit.g);
  final _ingredientsNotifier = ValueNotifier<List<ProductQuantity>>([]);
  
  final _nutrientAmountNotifier = ValueNotifier<double>(0);
  final _nutrientsUnitNotifier = ValueNotifier<Unit>(Unit.g);
  final _nutrientsNotifier = ValueNotifier<List<ProductNutrient>>([]);
  
  final _isDuplicateNotifier = ValueNotifier<bool>(false);
  final _circRefNotifier = ValueNotifier<bool>(false);
  
  @override
  void initState() {
    if (widget.isEdit == null || (widget.isEdit! && widget.productName == null)) {
      Future(() {
        showErrorbar(context, "Error: Product not found");
        Navigator.of(context).pop(null);
      });
    }
    
    _formKey = GlobalKey<FormState>();
    
    _isEdit = widget.isEdit ?? false;
    
    _productNameController = TextEditingController();
    _densityAmount1Controller = TextEditingController();
    _densityAmount2Controller = TextEditingController();
    _quantityAmount1Controller = TextEditingController();
    _quantityAmount2Controller = TextEditingController();
    _quantityNameController = TextEditingController();
    _resultingAmountController = TextEditingController();
    _nutrientAmountController = TextEditingController();
    
    // reload product stream
    Future(() {
      _dataService.reloadProductStream();// If it's a copy, toast via SnackBar
      if (widget.isCopy) {
        Future(() {
          showSnackbar(context, "Product duplicated from '${widget.productName}'");
        });
      }
    });
    
    super.initState();
  }
  
  @override
  void dispose() {
    _productNameController.dispose();
    _densityAmount1Controller.dispose();
    _densityAmount2Controller.dispose();
    _quantityAmount1Controller.dispose();
    _quantityAmount2Controller.dispose();
    _quantityNameController.dispose();
    _resultingAmountController.dispose();
    _densityConversionNotifier.dispose();
    _quantityConversionNotifier.dispose();
    _defaultUnitNotifier.dispose();
    _autoCalcAmountNotifier.dispose();
    _resultingAmountNotifier.dispose();
    _ingredientsUnitNotifier.dispose();
    _ingredientsNotifier.dispose();
    _isDuplicateNotifier.dispose();
    _circRefNotifier.dispose();
    _nutrientAmountNotifier.dispose();
    _nutrientsUnitNotifier.dispose();
    _nutrientsNotifier.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: false,
      onPopInvoked: _onPopInvoked,
      child: StreamBuilder(
        stream: _dataService.streamNutritionalValues(),
        builder: (contextN, snapshotN) {
          return StreamBuilder(
            stream: _dataService.streamProducts(),
            builder: (contextP, snapshotP) {
              
              List<NutritionalValue>? nutValues;
              List<Product>? products;
              
              Map<int, Product>? productsMap;
              
              // if data has loaded
              if (snapshotN.hasData && snapshotP.hasData) {
                _loaded = true;
                
                nutValues = snapshotN.data as List<NutritionalValue>;
                products = snapshotP.data as List<Product>;
                productsMap = Map.fromEntries(products.map((prod) => MapEntry(prod.id, prod)));
                
                if (_isEdit) {
                  try {
                    _prevProduct = products.firstWhere((prod) => prod.name == widget.productName);
                    _id = _prevProduct.id;
                  } catch (e) {
                    _error = true;
                    return const Text("Error: Product not found");
                  }
                } else {
                  _prevProduct = Product.defaultValues();
                  // create one nutrient per nutritional value
                  _prevProduct.nutrients = nutValues.map((nutVal) => ProductNutrient(
                    productId: -1,
                    nutritionalValueId: nutVal.id,
                    value: 0,
                    autoCalc: true,
                  )).toList();
                }
                
                var copyProduct = _interimProduct ?? _prevProduct;
                
                // check whether nutValues and copyProduct nutrients match
                
                var copyNutrients = checkNutrients(copyProduct.id, copyProduct.nutrients, nutValues);
                
                // set initial values
                _productNameController.text = _interimProduct?.name ?? widget.productName ?? copyProduct.name;
                _densityAmount1Controller.text = truncateZeros(copyProduct.densityConversion.amount1);
                _densityAmount2Controller.text = truncateZeros(copyProduct.densityConversion.amount2);
                _quantityAmount1Controller.text = truncateZeros(copyProduct.quantityConversion.amount1);
                _quantityAmount2Controller.text = truncateZeros(copyProduct.quantityConversion.amount2);
                _quantityNameController.text = copyProduct.quantityName;
                _nutrientAmountController.text = truncateZeros(copyProduct.amountForNutrients);
                
                _densityConversionNotifier.value = copyProduct.densityConversion;
                _quantityConversionNotifier.value = copyProduct.quantityConversion;
                _defaultUnitNotifier.value = copyProduct.defaultUnit;
                _autoCalcAmountNotifier.value = copyProduct.autoCalc;
                _ingredientsUnitNotifier.value = copyProduct.ingredientsUnit;
                _ingredientsNotifier.value = List.from(copyProduct.ingredients);
                _nutrientsUnitNotifier.value = copyProduct.nutrientsUnit;
                _nutrientAmountNotifier.value = copyProduct.amountForNutrients;
                
                _resultingAmountController.text = truncateZeros(copyProduct.amountForIngredients);
                _resultingAmountNotifier.value = copyProduct.amountForIngredients;
                
                // populate ingredient amount controllers
                _ingredientAmountControllers.clear();
                for (var ingredient in copyProduct.ingredients) {
                  var controller = TextEditingController();
                  controller.text = truncateZeros(ingredient.amount);
                  _ingredientAmountControllers.add(controller);
                }
                
                // calculate nutrients
                
                _nutrientsNotifier.value = calcNutrients(
                  nutrients: copyNutrients,
                  ingredients: copyProduct.ingredients,
                  productsMap: productsMap,
                  ingredientsUnit: copyProduct.ingredientsUnit,
                  nutrientsUnit: copyProduct.nutrientsUnit,
                  densityConversion: copyProduct.densityConversion,
                  quantityConversion: copyProduct.quantityConversion,
                  amountForIngredients: copyProduct.amountForIngredients,
                  amountForNutrients: copyProduct.amountForNutrients,
                ).$1;
                
                // populate nutrient amount controllers
                _nutrientAmountControllers.clear();
                for (var nutrient in copyNutrients) {
                  var controller = TextEditingController();
                  if (!nutrient.autoCalc) controller.text = truncateZeros(nutrient.value);
                  _nutrientAmountControllers.add(controller);
                }
              }
              
              String title;
              if (widget.isEdit == true) {
                title = "Edit Product";
              } else if (widget.isCopy) {
                title = "Add Product (Copy)";
              } else {
                title = "Add Product";
              }
              
              return Scaffold(
                appBar: AppBar(
                  title: Text(title),
                  actions: _isEdit && _loaded ? [
                    ValueListenableBuilder(
                      valueListenable: _productNameController,
                      builder: (context, value, child) {
                        var name = _productNameController.text;
                        return _buildDeleteButton(name, productsMap!);
                      }
                    )
                  ] : null
                ),
                body: ScrollConfiguration(
                  // clamping scroll physics to avoid overscroll
                  behavior: const ScrollBehavior().copyWith(overscroll: false),
                  child: 
                    _loaded ? SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildNameField(products!),
                              const SizedBox(height: 5),
                              _buildDefaultUnitDropdown(),
                              const SizedBox(height: 8),
                              ConversionBoxes(
                                densityAmount1Controller: _densityAmount1Controller,
                                densityAmount2Controller: _densityAmount2Controller,
                                quantityAmount1Controller: _quantityAmount1Controller,
                                quantityAmount2Controller: _quantityAmount2Controller,
                                quantityNameController: _quantityNameController,
                                densityConversionNotifier: _densityConversionNotifier,
                                quantityConversionNotifier: _quantityConversionNotifier,
                                defaultUnitNotifier: _defaultUnitNotifier,
                                onValidate: () => _formKey.currentState!.validate(),
                              ),
                              const SizedBox(height: 14),
                              IngredientsBox(
                                id: _id,
                                prevProduct: _prevProduct,
                                productsMap: productsMap!,
                                defaultUnitNotifier: _defaultUnitNotifier,
                                quantityNameController: _quantityNameController,
                                autoCalcAmountNotifier: _autoCalcAmountNotifier,
                                ingredientsNotifier: _ingredientsNotifier,
                                ingredientsUnitNotifier: _ingredientsUnitNotifier,
                                densityConversionNotifier: _densityConversionNotifier,
                                quantityConversionNotifier: _quantityConversionNotifier,
                                resultingAmountNotifier: _resultingAmountNotifier,
                                circRefNotifier: _circRefNotifier,
                                productNameController: _productNameController,
                                resultingAmountController: _resultingAmountController,
                                ingredientAmountControllers: _ingredientAmountControllers,
                                intermediateSave: () => _interimProduct = getProductFromForm().$1,
                              ),
                              const SizedBox(height: 14),
                              NutrientsBox(
                                nutValues: nutValues!,
                                productsMap: productsMap,
                                nutrientAmountNotifier: _nutrientAmountNotifier,
                                nutrientsUnitNotifier: _nutrientsUnitNotifier,
                                nutrientsNotifier: _nutrientsNotifier,
                                defaultUnitNotifier: _defaultUnitNotifier,
                                densityConversionNotifier: _densityConversionNotifier,
                                quantityConversionNotifier: _quantityConversionNotifier,
                                ingredientsNotifier: _ingredientsNotifier,
                                ingredientsUnitNotifier: _ingredientsUnitNotifier,
                                resultingAmountNotifier: _resultingAmountNotifier,
                                quantityNameController: _quantityNameController,
                                nutrientAmountController: _nutrientAmountController,
                                nutrientAmountControllers: _nutrientAmountControllers,
                              ),
                              const SizedBox(height: 8),
                              _buildAddButton(),
                            ]
                          ),
                        ),
                      ),
                    ) : const LoadingPage()
                )
              );
            }
          );
        }
      ),
    );
  }
  
  Future _onPopInvoked(bool didPop) async {
    if (didPop) return;
    if (!_loaded || _error) {
      // if the data is not loaded yet, pop immediately 
      Navigator.of(context).pop(null);
      return;
    }
    
    final NavigatorState navigator = Navigator.of(context);
    
    // test whether the product has been changed compared to the prevProduct
    var (product, _) = getProductFromForm();
    
    if (product.equals(_prevProduct)) {
      Future(() => navigator.pop(_prevProduct));
      return;
    }
    
    bool willPop = await showContinueWithoutSavingDialog(context) == true;
    
    if (willPop) {
      Future(() => navigator.pop(product));
    }
  }
  
  Widget _buildDeleteButton(String? name, Map<int, Product> productsMap) => 
    IconButton(
      onPressed: () {
        // Check whether the product is used in any recipe
        // List<Product> usedAsIngredientIn = productsMap.where((prod) => prod.ingredients.any((ingr) => ingr.productId == _id)).toList();
        
        // Map all products which include the current product (_id) as an ingredient
        Map<int, Product> usedAsIngredientIn = {};
        for (var product in productsMap.values) {
          if (product.ingredients.any((ingr) => ingr.productId == _id)) {
            usedAsIngredientIn[product.id] = product;
          }
        }
        
        if (usedAsIngredientIn.isEmpty) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Delete Product"),
              content: const Text("If you delete this product, all associated data will be lost."),
              surfaceTintColor: Colors.transparent,
              actions: [
                TextButton(
                  onPressed: () {
                    _dataService.deleteProductWithName(widget.productName!);
                    Navigator.of(context).pop(null);
                    Navigator.of(context).pop(null);
                  },
                  child: const Text("Delete"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                )
              ],
            )
          );
        } else {
          // Tell the user that the product is used in following recipes
          showUsedAsIngredientDialog(
            name: name ?? "",
            context: context,
            usedAsIngredientIn: usedAsIngredientIn,
            beforeNavigate: () {
              _interimProduct = getProductFromForm().$1;
            },
          );
        }
      },
      icon: const Icon(Icons.delete),
    );
  
  Widget _buildNameField(List<Product> products) {
    var textField = Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: _productNameController,
        decoration: const InputDecoration(
          labelText: "Name"
        ),
        validator: (String? value) {
          for (var prod in products) {
            if (prod.name == value && !(prod.name == widget.productName && (widget.isEdit ?? false))) {
              // change notifier after build complete
              if (!_isDuplicateNotifier.value) {
                Future(() {
                  _isDuplicateNotifier.value = true;
                });
              }
              return "Already taken";
            }
          }
          if (_isDuplicateNotifier.value) {
            Future(() {
              _isDuplicateNotifier.value = false;
            });
          }
          if (value == null || value.isEmpty) {
            return "Required Field";
          }
          return null;
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
    
    return ValueListenableBuilder<bool>(
      valueListenable: _isDuplicateNotifier,
      builder: (context, value, child) {
        return Column(
          children: [
            if (widget.isCopy) _buildShowOrigButton(products),
            textField,
            if (value) _buildShowDuplicateButton(products),
          ],
        );
      }
    );
  }
  
  Widget _buildShowOrigButton(List<Product> products) => _buildProductReferrelButton(false, products);
  
  Widget _buildShowDuplicateButton(List<Product> products) => _buildProductReferrelButton(true, products);
  
  Widget _buildProductReferrelButton(
    bool isNameDuplicate,
    List<Product> products,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextButton(
        onPressed: () {
          String name;
          if (isNameDuplicate) {
            name = _productNameController.text;
          } else {
            name = widget.productName!;
          }
          // navigate to edit view of duplicate product
          try {
            final product = products.firstWhere((prod) => prod.name == name);
            _interimProduct = getProductFromForm().$1;
            Navigator.of(context).pushNamed(
              editProductRoute,
              arguments: (product.name, null),
            );
          } catch (e) {
            devtools.log("Error: Product not found");
          }
        },
        child: Text(
          "Show ${isNameDuplicate ? "Duplicate" : "Original (${widget.productName})"}",
          style: TextStyle(
            color: isNameDuplicate ? Colors.red : Colors.teal,
          ),
        ),
      ),
    );
  }
  
  Widget _buildDefaultUnitDropdown() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return ValueListenableBuilder(
          valueListenable: _quantityNameController,
          builder: (context, value, child) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "Default Unit:",
                        style: TextStyle(
                          color: Colors.black.withAlpha(200),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: UnitDropdown(
                      items: buildUnitItems(quantityName: value.text),
                      current: _defaultUnitNotifier.value,
                      onChanged: (Unit? unit) {
                        if (unit != null) {
                          setState(() {
                            _defaultUnitNotifier.value = unit;
                          });
                        }
                      }
                    )
                  ),
                ]
              ),
            );
          }
        );
      }
    );
  }
  
  Widget _buildAddButton() => Padding(
    padding: const EdgeInsets.all(8.0),
    child: ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.teal.shade400),
        foregroundColor: MaterialStateProperty.all(Colors.white),
        minimumSize: MaterialStateProperty.all(const Size(double.infinity, 60)),
        textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 16)),
        shape: MaterialStateProperty.all(const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        )),
      ),
      onPressed: () {
        var (product, isValid) = getProductFromForm();
        
        if (isValid) {
          Future<Product> future;
          
          if (_isEdit) {
            future = _dataService.updateProduct(product);
          } else {
            future = _dataService.createProduct(product);
          }
          
          future.then((newProduct) {
            Navigator.of(context).pop(newProduct);
          });
        }
      },
      child: Text(_isEdit ? "Update Product" : "Add Product"),
    ),
  );
  
  (Product, bool) getProductFromForm() {
    final name = _productNameController.text;
    final defUnit = _defaultUnitNotifier.value;
    final densityConversion = _densityConversionNotifier.value;
    final quantityConversion = _quantityConversionNotifier.value;
    final quantityName = _quantityNameController.text;
    final autoCalc = _autoCalcAmountNotifier.value;
    final resultingAmount = _resultingAmountNotifier.value;
    final ingredientsUnit = _ingredientsUnitNotifier.value;
    final ingredients = _ingredientsNotifier.value;
    final amountForNutrients = _nutrientAmountNotifier.value;
    final nutrientsUnit = _nutrientsUnitNotifier.value;
    final nutrients = _nutrientsNotifier.value;
    
    var anyNutrientAutoCalc = nutrients.any((nutrient) => nutrient.autoCalc);
    var areNutrientsEmpty = !(anyNutrientAutoCalc || nutrients.any((nutrient) => nutrient.value != 0));
    
    final isValid = _formKey.currentState!.validate()
      && !_circRefNotifier.value
      && validateConversionBox(0, defUnit, densityConversion, quantityConversion, quantityName) == null
      && validateConversionBox(1, defUnit, densityConversion, quantityConversion, quantityName) == null
      && validateAmount(
          ingredientsUnit,
          defUnit,
          autoCalc,
          ingredients.isEmpty,
          resultingAmount,
          densityConversion,
          quantityConversion,
        ).$1 != ErrorType.error
      && validateAmount(
          nutrientsUnit,
          defUnit,
          anyNutrientAutoCalc,
          areNutrientsEmpty,
          amountForNutrients,
          densityConversion,
          quantityConversion,
        ).$1 != ErrorType.error;
    
    
    return (
      Product(
        id:                   _isEdit ? _id : -1,
        name:                 name,
        creationDate:         _isEdit ? _prevProduct.creationDate : DateTime.now(),
        defaultUnit:          defUnit,
        densityConversion:    densityConversion,
        quantityConversion:   quantityConversion,
        quantityName:         quantityName,
        autoCalc:             autoCalc,
        amountForIngredients: resultingAmount,
        ingredientsUnit:      ingredientsUnit,
        ingredients:          ingredients,
        amountForNutrients:   amountForNutrients,
        nutrientsUnit:        nutrientsUnit,
        nutrients:            nutrients,
      ),
      isValid,
    );
  }
}