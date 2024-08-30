import '../../utility/data_logic.dart';
import '../../utility/text_logic.dart';
import 'data_objects.dart';
import 'sqflite_data_provider.dart';

// Maps to objects

Product mapToProduct(Map<String, dynamic> row) =>
  Product(
    id:                    row[idColumn] as int,
    name:                  row[nameColumn] as String,
    creationDate:          DateTime.parse(row[creationDateColumn] as String),
    lastEditDate:          DateTime.parse(row[lastEditDateColumn] as String),
    temporaryBeginning:    condParse(row[temporaryBeginningColumn] as String?),
    temporaryEnd:          condParse(row[temporaryEndColumn] as String?),
    isTemporary:           row[isTemporaryColumn] == 1,
    defaultUnit:           unitFromString(row[defaultUnitColumn] as String),
    densityConversion:     Conversion.fromString(row[densityConversionColumn] as String),
    quantityConversion:    Conversion.fromString(row[quantityConversionColumn] as String),
    quantityName:          row[quantityNameColumn] as String,
    autoCalc:              row[autoCalcAmountColumn] == 1,
    amountForIngredients:  toDouble(row[amountForIngredientsColumn] ?? 100),
    ingredientsUnit:       unitFromString((row[ingredientsUnitColumn] ?? row[defaultUnitColumn]) as String),
    amountForNutrients:    toDouble(row[amountForNutrientsColumn] ?? 100),
    nutrientsUnit:         unitFromString((row[nutrientsUnitColumn] ?? row[defaultUnitColumn]) as String),
    ingredients:           [],
    nutrients:             [],
  );
  
ProductQuantity mapToProductQuantity(Map<String, Object?> row) =>
  ProductQuantity(
    productId: row[ingredientIdColumn] as int,
    amount:    toDouble(row[amountColumn]),
    unit:      unitFromString(row[unitColumn] as String),
  );

NutritionalValue mapToNutritionalValue(Map<String, Object?> row) =>
  NutritionalValue(
    row[idColumn] as int,
    (row[orderIdColumn] ?? row[idColumn]) as int,
    row[nameColumn] as String,
    row[unitNameColumn] as String,
    row[showFullNameColumn] == 1,
  );



ProductNutrient mapToProductNutrient(Map<String, Object?> row) =>
  ProductNutrient(
    nutritionalValueId: row[nutritionalValueIdColumn] as int,
    productId:          row[productIdColumn] as int,
    autoCalc:           row[autoCalcColumn] == 1,
    value:              toDouble(row[valueColumn]),
  );

Meal mapToMeal(Map<String, Object?> row) =>
  Meal(
    id:               row[idColumn] as int,
    dateTime:         DateTime.parse(row[dateTimeColumn] as String),
    creationDate:     DateTime.parse(row[creationDateColumn] as String),
    lastEditDate:     DateTime.parse(row[lastEditDateColumn] as String),
    productQuantity:  ProductQuantity(
      productId:        row[productIdColumn] as int,
      amount:           toDouble(row[mealAmountColumn]),
      unit:             unitFromString(row[mealUnitColumn] as String),
    ),
  );

// Objects to maps
  
Map<String, dynamic> productToMap(Product product) =>
  {
    "id":                     product.id,
    "name":                   product.name,
    "creation_date":          product.creationDate?.toIso8601String(),
    "last_edit_date":         product.lastEditDate?.toIso8601String(),
    "temporary_beginning":    product.temporaryBeginning?.toIso8601String(),
    "temporary_end":          product.temporaryEnd?.toIso8601String(),
    "is_temporary":           product.isTemporary,
    "default_unit":           product.defaultUnit.toString(),
    "quantity_name":          product.quantityName,
    "auto_calc":              product.autoCalc,
    "ingredients_unit":       product.ingredientsUnit.toString(),
    "nutrients_unit":         product.nutrientsUnit.toString(),
    "amount_for_ingredients": product.amountForIngredients,
    "amount_for_nutrients":   product.amountForNutrients,
    "density_conversion":     product.densityConversion.toString(),
    "quantity_conversion":    product.quantityConversion.toString(),
    "ingredients":            product.ingredients.map((ingr) => {
      "product_id":             ingr.productId,
      "amount":                 ingr.amount,
      "unit":                   ingr.unit.toString(),
    }).toList(),
    "nutrients":              product.nutrients.map((nut) => {
      "nutritional_value_id":   nut.nutritionalValueId,
      "auto_calc":              nut.autoCalc,
      "value":                  nut.value,
    }).toList(),
  };
  
Map<String, dynamic> nutValueToMap(NutritionalValue nutValue) =>
  {
    "id":           nutValue.id,
    "order_id":     nutValue.orderId,
    "name":         nutValue.name,
    "unit":         nutValue.unit,
    "showFullName": nutValue.showFullName,
  };
  
Map<String, dynamic> mealToMap(Meal meal) =>
  {
    "id":             meal.id,
    "date_time":      meal.dateTime.toIso8601String(),
    "product_id":     meal.productQuantity.productId,
    "amount":         meal.productQuantity.amount,
    "unit":           unitToString(meal.productQuantity.unit),
    "creation_date":  meal.creationDate?.toIso8601String(),
    "last_edit_date": meal.lastEditDate?.toIso8601String(),
  };