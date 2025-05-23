// ignore_for_file: curly_braces_in_flow_control_structures, empty_catches

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:food_tracker/utility/theme.dart';
import 'package:food_tracker/widgets/multi_stream_builder.dart';

import '../constants/ui.dart';
import '../subviews/conversion_boxes.dart';
import '../subviews/daily_targets_box.dart';
import '../subviews/nutrients_box.dart';
import '../subviews/temporary_box.dart';
import '../utility/data_logic.dart';
import '../subviews/ingredients_box.dart';
import '../utility/text_logic.dart';
import '../widgets/multi_value_listenable_builder.dart';
import '../widgets/unit_dropdown.dart';
import '../constants/routes.dart';
import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../utility/modals.dart';
import '../widgets/loading_page.dart';

import "dart:developer" as devtools show log;

class EditProductView extends StatefulWidget {
  final String? productName;
  final bool? isEdit;
  final bool isCopy; // If the product settings should be copied from another product
  final bool canDelete = true;
  
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
  int _numberOfLoads = 0;
  bool _error = false;
  bool _forceReload = false;
  
  String? _copyName;
  
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
  late final TextEditingController _descriptionController;
  
  final List<TextEditingController> _ingredientAmountControllers = [];
  final List<TextEditingController> _nutrientAmountControllers = [];
  final List<FocusNode> _ingredientDropdownFocusNodes = [];
  
  late final bool _isEdit;
  
  int _id = -1;
  late Product _prevProduct;
  Product? _interimProduct;
   // used to store the product while the user navigates to another page, can contain formal errors
  List<int> _ingredientsToFocus = [];
  DateTime? _autofocusTime;
  
  final _defaultUnitNotifier = ValueNotifier<Unit>(Unit.g);
  
  final _isTemporaryNotifier = ValueNotifier<bool>(false);
  final _temporaryBeginningNotifier = ValueNotifier<DateTime?>(null);
  final _temporaryEndNotifier = ValueNotifier<DateTime?>(null);
  
  final _densityConversionNotifier = ValueNotifier<Conversion>(Conversion.defaultDensity());
  final _quantityConversionNotifier = ValueNotifier<Conversion>(Conversion.defaultQuantity());
  
  final _autoCalcAmountNotifier = ValueNotifier<bool>(false);
  final _resultingAmountNotifier = ValueNotifier<double>(0);
  final _ingredientsUnitNotifier = ValueNotifier<Unit>(Unit.g);
  // final _ingredientsNotifier = ValueNotifier<List<ProductQuantity>>([]);
  final _ingredientsNotifier = ValueNotifier<List<(ProductQuantity, Color)>>([]);
  
  final _nutrientAmountNotifier = ValueNotifier<double>(0);
  final _nutrientsUnitNotifier = ValueNotifier<Unit>(Unit.g);
  final _nutrientsNotifier = ValueNotifier<List<ProductNutrient>>([]);
  
  final _isDuplicateNotifier = ValueNotifier<bool>(false);
  final _ingredientsValidNotifier = ValueNotifier<bool>(true);
  
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
    _descriptionController = TextEditingController();
    
    // reload product stream
    Future(() {
      _dataService.reloadProductStream();
      
      // If it's a copy, toast via SnackBar
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
    _defaultUnitNotifier.dispose();
    _isTemporaryNotifier.dispose();
    _temporaryBeginningNotifier.dispose();
    _temporaryEndNotifier.dispose();
    _densityConversionNotifier.dispose();
    _quantityConversionNotifier.dispose();
    _autoCalcAmountNotifier.dispose();
    _resultingAmountNotifier.dispose();
    _ingredientsUnitNotifier.dispose();
    _ingredientsNotifier.dispose();
    _isDuplicateNotifier.dispose();
    _ingredientsValidNotifier.dispose();
    _nutrientAmountNotifier.dispose();
    _nutrientsUnitNotifier.dispose();
    _nutrientsNotifier.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // if (_ingredientsToFocus.isNotEmpty) {
    //   _requestIngredientFocus(_ingredientsToFocus[0], _ingredientsToFocus[1]);
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     _requestIngredientFocus(_ingredientsToFocus[0], _ingredientsToFocus[1]);
    //   // _ingredientsToFocus.clear();
    //   });
    //   // after 200ms
    //   Future.delayed(const Duration(milliseconds: 1000), () {
    //     _requestIngredientFocus(_ingredientsToFocus[0], _ingredientsToFocus[1]);
    //     _ingredientsToFocus.clear();
    //   });
    // }
    // devtools.log("Building EditProductView");
    super.build(context);
    return PopScope(
      canPop: false,
      onPopInvoked: _onPopInvoked,
      child: ScrollConfiguration(
        behavior: MouseDragScrollBehavior().copyWith(scrollbars: false, overscroll: false),
        child: MultiStreamBuilder(
          streams: [
            _dataService.streamProducts(),
            _dataService.streamNutritionalValues(),
            _dataService.streamMeals(),
          ],
          builder: (context, snapshots) {
            var snapshotP = snapshots[0];
            var snapshotN = snapshots[1];
            var snapshotM = snapshots[2];
            
            List<NutritionalValue>? nutValues;
            List<Product>? products;
            List<Meal>? meals;
            
            Map<int, Product>? productsMap;
            
            if (snapshotN.hasData && snapshotP.hasData && snapshotM.hasData) {
              _loaded = true;
              _forceReload = false;
              _numberOfLoads++;
              
              nutValues = snapshotN.data as List<NutritionalValue>;
              products = snapshotP.data as List<Product>;
              meals = snapshotM.data as List<Meal>;
              productsMap = Map.fromEntries(products.map((prod) => MapEntry(prod.id, prod)));
              
              if (_isEdit) {
                try {
                  _prevProduct = products.firstWhere((prod) => prod.name == widget.productName);
                  _id = _prevProduct.id;
                } catch (e) {
                  _error = true;
                  return const Scaffold(body: LoadingPage());
                }
              } else if (widget.isCopy) {
                _prevProduct = products.firstWhere((prod) => prod.name == widget.productName, orElse: () => _prevProduct);
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
              
              if (_forceReload || _numberOfLoads <= 1) {
                // set initial values
                _productNameController.text = _interimProduct?.name ?? widget.productName ?? copyProduct.name;
                
                if (widget.isCopy && _interimProduct == null && widget.productName != null) {
                  var name = widget.productName!;
                  // Remove the copy date and number from the name
                  var regex = RegExp(r"\((\d{4}-\d{1,2}-\d{1,2})( #\d+)?\)$");
                  var match = regex.firstMatch(_productNameController.text);
                  if (match != null) {
                    name = name.substring(0, match.start).trim();
                  }
                  // add the current date in the format YYYY-MM-DD
                  name += " (${DateTime.now().toIso8601String().split("T")[0]}";
                  
                  // check all products for the highest copy number
                  // For example if there is a product "Product (2024-01-01)" the highest copy number is 0, if there is a product "Product (2024-01-01 #1)" the highest copy number is 1
                  var copyNumber = -1;
                  for (var product in products) {
                    if (product.name.startsWith(name)) {
                      var copy = product.name.substring(name.length).trim().replaceAll(RegExp(r"[\)#]"), "");
                      if (copy.isEmpty) {
                        copyNumber = 0;
                      } else {
                        try {
                          var copyInt = int.parse(copy);
                          if (copyInt > copyNumber) copyNumber = copyInt;
                        } catch (e) {}
                      }
                    }
                  }
                  if (copyNumber >= 0) {
                    copyNumber = max(1, copyNumber);
                    name += " #${copyNumber + 1}";
                  }
                  _copyName = "$name)";
                  _productNameController.text = _copyName!;
                  copyProduct = copyProduct.copyWith(newName: _copyName!);
                  _prevProduct = copyProduct.copyWith();
                }
              }
              
              _descriptionController.text = copyProduct.description;
              _densityAmount1Controller.text = truncateZeros(copyProduct.densityConversion.amount1);
              _densityAmount2Controller.text = truncateZeros(copyProduct.densityConversion.amount2);
              _quantityAmount1Controller.text = truncateZeros(copyProduct.quantityConversion.amount1);
              _quantityAmount2Controller.text = truncateZeros(copyProduct.quantityConversion.amount2);
              _quantityNameController.text = copyProduct.quantityName;
              _nutrientAmountController.text = truncateZeros(copyProduct.amountForNutrients);
              
              _defaultUnitNotifier.value = copyProduct.defaultUnit;
              _isTemporaryNotifier.value = copyProduct.isTemporary;
              _temporaryBeginningNotifier.value = copyProduct.temporaryBeginning;
              _temporaryEndNotifier.value = copyProduct.temporaryEnd;
              _densityConversionNotifier.value = copyProduct.densityConversion;
              _quantityConversionNotifier.value = copyProduct.quantityConversion;
              _autoCalcAmountNotifier.value = copyProduct.autoCalc;
              _ingredientsUnitNotifier.value = copyProduct.ingredientsUnit;
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
              // add colors to copy ingredients
              List<(ProductQuantity, Color)> copyIngredients = [];
              for (var i = 0; i < copyProduct.ingredients.length; i++) {
                var color = productColors[i % productColors.length];
                copyIngredients.add((copyProduct.ingredients[i], color));
              }
              _ingredientsNotifier.value = copyIngredients;
              
              // calculate nutrients
              
              var nutrients = calcNutrients(
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
              
              _nutrientsNotifier.value = nutrients;
              
              // populate nutrient amount controllers
              _nutrientAmountControllers.clear();
              // for (var nutrient in copyNutrients) {
              //   var controller = TextEditingController();
              //   if (!nutrient.autoCalc) controller.text = truncateZeros(nutrient.value);
              //   _nutrientAmountControllers.add(controller);
              // }
              for (var nutrient in nutrients) {
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
            
            int? focusIndex;
            if (_ingredientsToFocus.isNotEmpty && _ingredientsToFocus[1] == 0) {
              focusIndex = _ingredientsToFocus[0];
            }
            
            return Scaffold(
              appBar: AppBar(
                title: Text(title, style: const TextStyle(fontSize: 16 * gsf)),
                toolbarHeight: appBarHeight,
                actions: _isEdit && _loaded && widget.canDelete ? [
                  _buildInfoButton(),
                  ValueListenableBuilder(
                    valueListenable: _productNameController,
                    builder: (context, value, child) {
                      return _buildDeleteButton(productsMap!);
                    }
                  ),
                  const SizedBox(width: 5 * gsf),
                ] : null
              ),
              body: _loaded ? SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(6.0) * gsf,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildNameWidget(products!),
                        // const SizedBox(height: 5 * gsf),
                        _buildDefaultUnitDropdown(),
                        TemporaryBox(
                          isTemporaryNotifier: _isTemporaryNotifier,
                          beginningNotifier: _temporaryBeginningNotifier,
                          endNotifier: _temporaryEndNotifier,
                          intermediateSave: () => _interimProduct = getProductFromForm().$1,
                          meals: meals ?? [],
                          productId: _id,
                        ),
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
                          intermediateSave: () => _interimProduct = getProductFromForm().$1,
                          onConversionChanged: (newDensityConversion, newQuantityConversion) {
                            updateDefaultAmounts(_defaultUnitNotifier.value, newQuantityConversion);
                            _interimProduct = getProductFromForm().$1.copyWith(
                              newDensityConversion: newDensityConversion,
                              newQuantityConversion: newQuantityConversion,
                            );
                          },
                          onNameChanged: (newName) => _interimProduct = getProductFromForm().$1.copyWith(newQuantityName: newName),
                        ),
                        const SizedBox(height: 14 * gsf),
                        IngredientsBox(
                          id: _id,
                          prevProduct: _prevProduct,
                          productsMap: productsMap!,
                          focusIndex: focusIndex,
                          autofocusTime: _autofocusTime,
                          defaultUnitNotifier: _defaultUnitNotifier,
                          quantityNameController: _quantityNameController,
                          autoCalcAmountNotifier: _autoCalcAmountNotifier,
                          ingredientsNotifier: _ingredientsNotifier,
                          ingredientsUnitNotifier: _ingredientsUnitNotifier,
                          densityConversionNotifier: _densityConversionNotifier,
                          quantityConversionNotifier: _quantityConversionNotifier,
                          resultingAmountNotifier: _resultingAmountNotifier,
                          validNotifier: _ingredientsValidNotifier,
                          productNameController: _productNameController,
                          resultingAmountController: _resultingAmountController,
                          ingredientAmountControllers: _ingredientAmountControllers,
                          ingredientDropdownFocusNodes: _ingredientDropdownFocusNodes,
                          intermediateSave: () => _interimProduct = getProductFromForm().$1,
                          onChanged: (newIngredientsUnit, newIngredients, index) {
                            var oldP = getProductFromForm().$1;
                            _ingredientsToFocus = index == null ? [] : [index, 0];
                            _autofocusTime = DateTime.now();
                            _interimProduct = oldP.copyWith(
                              newIngredientsUnit: newIngredientsUnit,
                              newIngredients: newIngredients.map((e) => e.$1).toList(),
                            );
                            if (index != null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _ingredientsNotifier.value = newIngredients;
                                // focus the ingredient dropdown
                                _requestIngredientFocus(index, 0);
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _requestIngredientFocus(index, 0);
                                });
                                // after 200ms
                                Future.delayed(const Duration(milliseconds: 200), () {
                                  _requestIngredientFocus(index, 0);
                                });
                              });
                            }
                          },
                          requestIngredientFocus: _requestIngredientFocus,
                        ),
                        const SizedBox(height: 14 * gsf),
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
                          onUnitChanged: (unit) {
                            _interimProduct = getProductFromForm().$1.copyWith(newNutrientsUnit: unit);
                          },
                          intermediateSave: () => _interimProduct = getProductFromForm().$1,
                        ),
                        const SizedBox(height: 14 * gsf),
                        MultiValueListenableBuilder( // Daily Targets Box
                          listenables: [
                            _ingredientsNotifier,
                            _nutrientsNotifier,
                            _productNameController,
                          ],
                          builder: (context, values, child) {
                            var ingredients = values[0] as List<(ProductQuantity, Color)>;
                            var nutrients = values[1] as List<ProductNutrient>;
                            nutrients = nutrients.where((n) => !n.autoCalc).toList();
                            var name = _productNameController.text.trim();
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0) * gsf,
                              child: DailyTargetsBox(
                                null,
                                ingredients,
                                null,
                                (newIngredients) => _ingredientsNotifier.value = List.from(newIngredients),
                                FoldMode.startFolded,
                                true,
                                false,
                                null,
                                name,
                                _defaultUnitNotifier,
                                _nutrientsNotifier,
                                _nutrientAmountNotifier,
                                _nutrientsUnitNotifier,
                                _resultingAmountNotifier,
                                _ingredientsUnitNotifier,
                                _densityConversionNotifier,
                                _quantityConversionNotifier,
                                _quantityNameController,
                              ),
                            );
                          }
                        ),
                        const SizedBox(height: 11 * gsf),
                        _buildAddButton(meals!),
                      ]
                    ),
                  ),
                ),
              ) : const LoadingPage()
            );
          }
        ),
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
    
    var compProduct = _prevProduct;
    if (_copyName != null) compProduct = product.copyWith(newName: _copyName!);
    
    if (product.equals(compProduct)) {
      Future(() => navigator.pop(_prevProduct));
      return;
    }
    
    bool willPop = await showContinueWithoutSavingDialog(context, save: () => saveProduct(null), prodName: product.name) == true;
    
    if (willPop) {
      Future(() => navigator.pop(product));
    }
  }
  
  Widget _buildInfoButton() => SizedBox(
    width: 30 * gsf,
    child: IconButton(
      onPressed: () {
        showProductInfoDialog(context, _prevProduct);
      },
      icon: const Icon(Icons.info_outline, size: 21 * gsf),
      padding: kIsWeb ? 
        const EdgeInsets.fromLTRB(5, 5, 10, 5) * gsf : 
        EdgeInsets.zero,
      constraints: const BoxConstraints(),
    ),
  );
  
  Widget _buildDeleteButton(Map<int, Product> productsMap) => 
    ValueListenableBuilder(
      valueListenable: _productNameController,
      builder: (context, value, child) {
        var name = _productNameController.text.trim();
        return IconButton(
          padding: kIsWeb ? 
            const EdgeInsets.fromLTRB(5, 5, 5, 5) * gsf : 
            EdgeInsets.zero,
          icon: const Icon(Icons.delete, size: 21 * gsf),
          constraints: const BoxConstraints(),
          onPressed: () async {
            // Map all products which include the current product (_id) as an ingredient
            Map<int, Product> usedAsIngredientIn = {};
            for (var product in productsMap.values) {
              if (product.ingredients.any((ingr) => ingr.productId == _id)) {
                usedAsIngredientIn[product.id] = product;
              }
            }
            var targets = await _dataService.getAllTargets();
            // Check if any target has the Type product and the product id
            targets = targets.where((target) => target.trackedType == Product && target.trackedId == _id).toList();
            
            if (usedAsIngredientIn.isNotEmpty) {
              if (!context.mounted) return;
              // Tell the user that the product is used in following recipes
              showUsedAsIngredientDialog(
                name: name,
                context: context,
                usedAsIngredientIn: usedAsIngredientIn,
                beforeNavigate: () {
                  _interimProduct = getProductFromForm().$1;
                },
              );
            } else if(targets.isNotEmpty) {
              if (!context.mounted) return;
              // simple dialog informing that the product is used in a target
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Delete Product"),
                  content: const Text("This product is used in a daily target. You have to remove the target in order to delete the product."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            } else {
              // count how many meals contain the product
              var meals = await _dataService.getAllMeals();
              
              var mealCount = meals.where((meal) => meal.productQuantity.productId == _id).length;
              
              var text = const Text("If you delete this product, all associated data will be lost.");
              if (mealCount > 0) {
                text = Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: "Deleting this product will also delete "),
                      TextSpan(
                        text: "$mealCount ",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: "meal${mealCount == 1 ? "" : "s"}."),
                    ],
                  ),
                );
              }
              
              if (context.mounted) showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Delete Product"),
                    content: text,
                    icon: mealCount > 0 ? const Icon(Icons.warning, size: 24 * gsf) : null,
                    surfaceTintColor: Colors.transparent,
                    actions: [
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              style: actionButtonStyle,
                              onPressed: () {
                                _dataService.deleteProductWithName(widget.productName!);
                                Navigator.of(context).pop(null);
                                Navigator.of(context).pop(null);
                              },
                              child: const Text("Delete"),
                            ),
                          ),
                          const SizedBox(width: 20 * gsf),
                          Expanded(
                            child: TextButton(
                              style: actionButtonStyle,
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text("Cancel"),
                            ),
                          ),
                        ],
                      )
                    ],
                  )
                );
            }
          },
        );
      }
    );
  
  Widget _buildNameWidget(List<Product> products) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isDuplicateNotifier,
      builder: (context, value, child) {
        return Padding(
          padding: const EdgeInsets.all(8.0) * gsf,
          child: Column(
            children: [
              if (widget.isCopy) _buildShowOrigButton(products),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildNameField(products)),
                    const SizedBox(width: 10 * gsf),
                    _buildDescriptionButton(),
                  ]
                ),
              ),
              if (value) _buildShowDuplicateButton(products),
            ],
          ),
        );
      }
    );
  }
  
  Widget _buildNameField(List<Product> products) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1 * gsf),
      child: TextFormField(
        autofocus: !(_isEdit || widget.isCopy || _interimProduct != null),
        controller: _productNameController,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: "Name",
          contentPadding: const EdgeInsets.fromLTRB(12, 6, 12, 2) * gsf,
        ),
        validator: (String? value) {
          value = value?.trim();
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
  }
  
  Widget _buildShowOrigButton(List<Product> products) => _buildProductReferrelButton(false, products);
  
  Widget _buildShowDuplicateButton(List<Product> products) => _buildProductReferrelButton(true, products);
  
  Widget _buildProductReferrelButton(
    bool isNameDuplicate,
    List<Product> products,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8) * gsf,
      child: TextButton(
        onPressed: () {
          String name;
          if (isNameDuplicate) {
            name = _productNameController.text;
            name = name.trim();
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
          "Show ${isNameDuplicate ? "Duplicate" : "Original \"${widget.productName}\""}",
          style: TextStyle(
            color: isNameDuplicate ? Colors.red : Colors.teal,
            fontSize: 16 * gsf,
          ),
        ),
      ),
    );
  }
  
Widget _buildDescriptionButton() {
  return SizedBox(
    width: 50 * gsf,
    child: ValueListenableBuilder(
      valueListenable: _descriptionController,
      builder: (context, descValue, child) {
        bool hasDescription = descValue.text.isNotEmpty;
        return SizedBox.expand(
          child: ElevatedButton(
            style: lightButtonStyle.copyWith(
              backgroundColor: WidgetStateProperty.all(
                hasDescription ? areaButtonColor : Colors.grey.withAlpha(40),
              ),
              overlayColor: WidgetStateProperty.all(Colors.transparent),
            ),
            child: Icon(
              hasDescription ? Icons.description : Icons.description_outlined,
              color: hasDescription ? Theme.of(context).primaryColor : Colors.black54,
              size: 21 * gsf,
            ),
            onPressed: () async {
              String? newDescription = await showProductDescriptionDialog(context, _descriptionController.text, _productNameController.text);
              if (newDescription != null) {
                _descriptionController.text = newDescription;
                _interimProduct = getProductFromForm().$1;
              }
            },
          ),
        );
      }
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
              padding: const EdgeInsets.all(8.0) * gsf,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12) * gsf,
                      child: Text(
                        "Default Unit:",
                        style: TextStyle(
                          color: Colors.black.withAlpha(200),
                          fontSize: 16 * gsf,
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
                          updateDefaultAmounts(unit, _quantityConversionNotifier.value);
                          
                          _interimProduct = getProductFromForm().$1.copyWith(newDefaultUnit: unit,);
                          _defaultUnitNotifier.value = unit;
                        }
                      },
                      intermediateSave: () => _interimProduct = getProductFromForm().$1,
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
  
  Widget _buildAddButton(List<Meal> meals) => Padding(
    padding: const EdgeInsets.all(8.0) * gsf,
    child: ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.teal.shade400),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        minimumSize: WidgetStateProperty.all(const Size(double.infinity, 60 * gsf)),
        textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16 * gsf)),
        shape: WidgetStateProperty.all(const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14 * gsf)),
        )),
        padding: WidgetStateProperty.all(const EdgeInsets.all(12 * gsf)),
      ),
      onPressed: () => saveProduct(meals),
      child: Text(_isEdit ? "Update Product" : "Add Product"),
    ),
  );
  
  void saveProduct(Iterable<Meal>? meals, {bool popAfter = true}) async {
    var (product, isValid) = getProductFromForm();
    
    List? problems = validUnits(product, await _dataService.getAllMeals(), await _dataService.getAllProducts());
    if (problems != null && problems.isNotEmpty) {
      isValid = false;
      
      List<Widget> children = [];
      // Check if it's a list of products
      if (problems is List<Product>) {
        children.add(const Text("You changed the available units for this product. The product is used as an ingredient with now unavailable units in the following products:\n"));
        for (var product in problems) {
          children.add(Text(product.name));
        }
        children.add(const Text("\nThe units cannot be changed until every instance is changed to a compatible unit."));
      } else if (problems is List<Meal>) {
        children.add(const Text("You changed the available units for this product. The product is used as an ingredient with now unavailable units in the following meals:\n"));
        for (var meal in problems) {
          if (mounted) {
            var amountStr = meal.productQuantity.amount.toString();
            var unitStr = unitToLongString(meal.productQuantity.unit);
            var dateStr = conditionallyRemoveYear(context, [meal.dateTime], showWeekDay: false, removeYear: YearMode.never)[0];
            children.add(Text("$amountStr $unitStr at $dateStr"));
          }
        }
        children.add(const Text("\nThe units cannot be changed until every instance is changed to a compatible unit."));
      }
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            scrollable: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
    
    product.lastEditDate = DateTime.now();
    
    // check if the product is used in a meal that is outside the new temporary interval
    if (product.isTemporary && _isEdit && isValid) {
      // get all meals with the product
      meals ??= await _dataService.getAllMeals();
      meals = meals.where((meal) => meal.productQuantity.productId == _id);
      for (var meal in meals) {
        if (isDateInsideInterval(meal.dateTime, product.temporaryBeginning!, product.temporaryEnd!) != 0) {
          isValid = false;
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Error"),
                content: const Text("The product is used in a meal that is outside the temporary interval."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          }
          break;
        }
      }
    }
    
    // check if the product has a daily target and the target unit is incompatible with the new default unit
    if (_isEdit && isValid) {
      var targets = await _dataService.getAllTargets();
      var target = targets.firstWhereOrNull((target) => target.trackedType == Product && target.trackedId == _id);
      if (target != null) {
        var targetUnit = target.unit;
        // get all units that this can be converted to
        var densityConversion = product.densityConversion;
        var quantityConversion = product.quantityConversion;
        var units = getConvertibleUnits(product.defaultUnit, densityConversion, quantityConversion);
        if (!units.contains(targetUnit)) {
          isValid = false;
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Error"),
                content: Text("The product is used in a daily target with the unit \"${targetUnit == null ? "???" : unitToLongString(targetUnit)}\" which cannot be converted to the default unit."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          }
        }
      }
    }
    
    if (isValid) {
      Future<Product> future;
      
      if (_isEdit) {
        future = _dataService.updateProduct(product);
      } else {
        future = _dataService.createProduct(product);
      }
      
      if (popAfter) {
        if (_isEdit) {
          if (mounted) Navigator.of(context).pop(_interimProduct);
        } else {
          future.then((newProduct) {
            Navigator.of(context).pop(newProduct);
          });
        }
      }
    }
  }
  
  void _requestIngredientFocus(int index, int subIndex) {
    try {
      if (index < _ingredientDropdownFocusNodes.length) {
        if (subIndex == 0) {
          // If sub index = 0, focus the product dropdown
          _ingredientDropdownFocusNodes[index].requestFocus();
        } else {
          // If sub index = 1, focus the amount field
          _ingredientDropdownFocusNodes[index].requestFocus();
          Future.delayed(const Duration(milliseconds: 20), () {
            for (var i = 0; i < 1; i++) FocusManager.instance.primaryFocus?.nextFocus();
          });
        }
      }
    } catch (e) {
      devtools.log("Error focusing ingredient $index: $e");
    }
  }
  
  // if ingredient and nutrient values are default, change them to the new unit                    
  void updateDefaultAmounts(Unit unit, Conversion quantityConversion) {
    Unit oldUnit = _defaultUnitNotifier.value;
    if (_defaultUnitNotifier.value == Unit.quantity && _quantityConversionNotifier.value.enabled) {
      // if the quantity conversion is enabled, the old unit is the unit given in the quantity conversion
      oldUnit = _quantityConversionNotifier.value.unit2;
    }
    Unit newUnit = unit;
    if (newUnit == Unit.quantity && quantityConversion.enabled) {
      // if the quantity conversion is enabled, change the unit to the other unit
      newUnit = quantityConversion.unit2;
    }
    double oldDefValue = oldUnit == Unit.quantity ? 1.0 : Product.defaultValues().amountForIngredients;
    double newDefValue = newUnit == Unit.quantity ? 1.0 : Product.defaultValues().amountForIngredients;
    
    Unit ingredientsUnit = _ingredientsUnitNotifier.value;
    Unit nutrientsUnit = _nutrientsUnitNotifier.value;
    double resultingAmount = _resultingAmountNotifier.value;
    double amountForNutrients = _nutrientAmountNotifier.value;
    bool hasChanged = false;
    if (
      _ingredientsNotifier.value.isEmpty
      && ingredientsUnit == oldUnit
      && resultingAmount == oldDefValue
    ) {
      ingredientsUnit = newUnit;
      resultingAmount = newDefValue;
      hasChanged = true;
    }
    if (
      _nutrientsNotifier.value.every((nutrient) => nutrient.autoCalc)
      && nutrientsUnit == oldUnit
      && amountForNutrients == oldDefValue
    ) {
      nutrientsUnit = newUnit;
      amountForNutrients = newDefValue;
      hasChanged = true;
    }
    if (!hasChanged) return;
              
    _interimProduct = getProductFromForm().$1.copyWith(
      newIngredientsUnit: ingredientsUnit,
      newNutrientsUnit: nutrientsUnit,
      newAmountForIngredients: resultingAmount,
      newAmountForNutrients: amountForNutrients,
    );
    _defaultUnitNotifier.value = unit;
    _ingredientsUnitNotifier.value = ingredientsUnit;
    _nutrientsUnitNotifier.value = nutrientsUnit;
    _resultingAmountNotifier.value = resultingAmount;
    _nutrientAmountNotifier.value = amountForNutrients;
    _nutrientAmountController.text = truncateZeros(amountForNutrients);
    _resultingAmountController.text = truncateZeros(resultingAmount);
  }
  
  (Product, bool) getProductFromForm() {
    final name = _productNameController.text.trim();
    final description = _descriptionController.text.trim();
    final defUnit = _defaultUnitNotifier.value;
    final densityConversion = _densityConversionNotifier.value;
    final quantityConversion = _quantityConversionNotifier.value;
    final temporaryBeginning = _temporaryBeginningNotifier.value;
    final temporaryEnd = _temporaryEndNotifier.value;
    final isTemporary = _isTemporaryNotifier.value;
    final quantityName = _quantityNameController.text;
    final autoCalc = _autoCalcAmountNotifier.value;
    final resultingAmount = _resultingAmountNotifier.value;
    final ingredientsUnit = _ingredientsUnitNotifier.value;
    final ingredients = _ingredientsNotifier.value.map((pair) => pair.$1).toList();
    final amountForNutrients = _nutrientAmountNotifier.value;
    final nutrientsUnit = _nutrientsUnitNotifier.value;
    final nutrients = _nutrientsNotifier.value;
    
    var anyNutrientAutoCalc = nutrients.any((nutrient) => nutrient.autoCalc);
    var areNutrientsEmpty = !(anyNutrientAutoCalc || nutrients.any((nutrient) => nutrient.value != 0));
    nutrients.sort((a, b) => a.nutritionalValueId - b.nutritionalValueId);
    
    final isValid = _formKey.currentState!.validate()
      && _ingredientsValidNotifier.value
      && (!isTemporary || validateTemporaryInterval(temporaryBeginning, temporaryEnd) == null)
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
    // devtools.log("Product is valid: $isValid")
    // if (!isValid) {
    //   devtools.log("1: ${_formKey.currentState!.validate()}");
    //   devtools.log("2: ${_ingredientsValidNotifier.value}");
    //   devtools.log("3: ${!isTemporary || validateTemporaryInterval(temporaryBeginning, temporaryEnd) == null}");
    //   devtools.log("4: ${validateConversionBox(0, defUnit, densityConversion, quantityConversion, quantityName) == null}");
    //   devtools.log("5: ${validateConversionBox(1, defUnit, densityConversion, quantityConversion, quantityName) == null}");
    //   devtools.log("6: ${validateAmount(ingredientsUnit, defUnit, autoCalc, ingredients.isEmpty, resultingAmount, densityConversion, quantityConversion).$1 != ErrorType.error}");
    //   devtools.log("7: ${validateAmount(nutrientsUnit, defUnit, anyNutrientAutoCalc, areNutrientsEmpty, amountForNutrients, densityConversion, quantityConversion).$1 != ErrorType.error}");
    // }
    return (
      Product(
        id:                   _isEdit ? _id : -1,
        name:                 name,
        description:          description,
        creationDate:         _isEdit ? _prevProduct.creationDate : null,
        lastEditDate:         DateTime.now(),
        temporaryBeginning:   temporaryBeginning,
        temporaryEnd:         temporaryEnd,
        isTemporary:          isTemporary,
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
  
  List? validUnits(Product p, Iterable<Meal> meals, Iterable<Product> products) {
    // list of all units that can be converted to the default unit
    var units = getConvertibleUnits(p.defaultUnit, p.densityConversion, p.quantityConversion);
    
    // list of all products that contain p as an ingredient
    products = products.where((prod) => prod.ingredients.any((ingr) => ingr.productId == p.id));
    List<Product> incompatibleProducts = [];
    for (var product in products) {
      var unit = product.ingredients.firstWhere((ingr) => ingr.productId == p.id).unit;
      if (!units.contains(unit)) {
        incompatibleProducts.add(product);
      }
    }
    if (incompatibleProducts.isNotEmpty) return incompatibleProducts;
    
    // check if every meal of this product has a compatible unit
    meals = meals.where((meal) => meal.productQuantity.productId == p.id);
    List<Meal> incompatibleMeals = [];
    for (var meal in meals) {
      var unit = meal.productQuantity.unit;
      if (!units.contains(unit)) {
        incompatibleMeals.add(meal);
      }
    }
    if (incompatibleMeals.isNotEmpty) return incompatibleMeals;
    
    return null;
  }
}