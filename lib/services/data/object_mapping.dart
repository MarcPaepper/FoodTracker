import '../../utility/data_logic.dart';
import '../../utility/text_logic.dart';
import 'data_objects.dart';

import 'dart:developer' as devtools show log;

// multiple tables
const idColumn                    = "id";
const productIdColumn             = "product_id";
const amountColumn                = "amount";
const orderIdColumn               = "order_id";
const unitColumn                  = "unit";

// product table
const nameColumn                  = "name";
const creationDateColumn          = "creation_date";
const lastEditDateColumn          = "last_edit_date";
const temporaryBeginningColumn    = "temporary_beginning";
const temporaryEndColumn          = "temporary_end";
const isTemporaryColumn           = "is_temporary";
const quantityNameColumn          = "quantity_name";
const densityConversionColumn     = "density_conversion";
const quantityConversionColumn    = "quantity_conversion";
const defaultUnitColumn           = "default_unit";
const autoCalcAmountColumn        = "auto_calc_amount";
const amountForIngredientsColumn  = "amount_for_ingredients";
const ingredientsUnitColumn       = "ingredients_unit";
const amountForNutrientsColumn    = "amount_for_nutrients";
const nutrientsUnitColumn         = "nutrients_unit";

// nutritional value table
const unitNameColumn              = "unit";
const showFullNameColumn          = "show_full_name";

// ingredient table
const isContainedInIdColumn       = "is_contained_in_id";

// product nutrient table
const nutritionalValueIdColumn    = "nutritional_value_id";
const autoCalcColumn              = "auto_calc";
const valueColumn                 = "value";

// meal table
const dateTimeColumn               = "date_time";

// target table
const typeColumn                   = "type";
const trackedIdColumn              = "tracked_id";
const primaryColumn                = "is_primary";

// ----- Maps to objects -----

Product mapToProduct(Map<String, dynamic> row) {
  List<ProductQuantity> ingredients = [];
  List<ProductNutrient> nutrients = [];
  if (row["ingredients"] != null) {
    ingredients = (row["ingredients"] as List).map((ingr) => mapToProductQuantity(ingr)).toList();
  }
  if (row["nutrients"] != null) {
    nutrients = (row["nutrients"] as List).map((nut) => mapToProductNutrient(nut)).toList();
  }
  
  return Product(
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
    ingredients:           ingredients,
    nutrients:             nutrients,
  );
}
  
ProductQuantity mapToProductQuantity(Map<String, Object?> row) =>
  ProductQuantity(
    productId: row[productIdColumn] as int,
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
      amount:           toDouble(row[amountColumn]),
      unit:             unitFromString(row[unitColumn] as String),
    ),
  );

Target mapToTarget(Map<String, Object?> map) {
  Type trackedType;
  switch (map[typeColumn]) {
    case "Product":
      trackedType = Product;
      break;
    case "NutritionalValue":
      trackedType = NutritionalValue;
      break;
    default:
      throw ArgumentError("Unknown target type: ${map[typeColumn]}");
  }
  String unit = map[unitColumn] as String;
  
  return Target(
    trackedType: trackedType,
    trackedId:   map[trackedIdColumn] as int,
    isPrimary:   map[primaryColumn] == 1,
    amount:      toDouble(map[amountColumn]),
    unit:        unit == "" ? null : unitFromString(unit),
    orderId:     map[orderIdColumn] as int,
  );
}

// ----- Objects to maps -----
  
Map<String, dynamic> productToMap(Product product) =>
  {
    idColumn:                   product.id,
    nameColumn:                 product.name,
    defaultUnitColumn:          unitToString(product.defaultUnit),
    creationDateColumn:         product.creationDate?.toIso8601String(),
    lastEditDateColumn:         product.lastEditDate?.toIso8601String(),
    temporaryBeginningColumn:   product.temporaryBeginning?.toIso8601String().split("T")[0], // YYYY-MM-DD format
    temporaryEndColumn:         product.temporaryEnd?.toIso8601String().split("T")[0], // YYYY-MM-DD format
    isTemporaryColumn:          product.isTemporary ? 1 : 0,
    quantityNameColumn:         product.quantityName,
    densityConversionColumn:    product.densityConversion.toString(),
    quantityConversionColumn:   product.quantityConversion.toString(),
    autoCalcAmountColumn:       product.autoCalc ? 1 : 0,
    amountForIngredientsColumn: product.amountForIngredients,
    ingredientsUnitColumn:      unitToString(product.ingredientsUnit),
    amountForNutrientsColumn:   product.amountForNutrients,
    nutrientsUnitColumn:        unitToString(product.nutrientsUnit),
    "ingredients":              product.ingredients.map((ingr) => {
      productIdColumn:            ingr.productId!,
      amountColumn:               ingr.amount,
      unitColumn:                 unitToString(ingr.unit),
    }).toList(),
    "nutrients":                product.nutrients.map((nut) => {
      nutritionalValueIdColumn:   nut.nutritionalValueId,
      autoCalcColumn:             nut.autoCalc ? 1 : 0,
      valueColumn:                nut.value,
    }).toList(),
  };
  
Map<String, dynamic> nutValueToMap(NutritionalValue nutValue) =>
  {
    idColumn:               nutValue.id,
    nameColumn:             nutValue.name,
    orderIdColumn:          nutValue.orderId,
    unitNameColumn:         nutValue.unit,
    showFullNameColumn:     nutValue.showFullName ? 1 : 0,
  };
  
Map<String, dynamic> mealToMap(Meal meal) =>
  {
    idColumn:           meal.id,
    dateTimeColumn:     meal.dateTime.toIso8601String(),
    productIdColumn:    meal.productQuantity.productId,
    amountColumn:       meal.productQuantity.amount,
    unitColumn:         unitToString(meal.productQuantity.unit),
    creationDateColumn: meal.creationDate?.toIso8601String(),
    lastEditDateColumn: meal.lastEditDate?.toIso8601String(),
  };

Map<String, dynamic> targetToMap(Target target) {
  String targetType;
  if (target.trackedType == Product) {
    targetType = "Product";
  } else if (target.trackedType == NutritionalValue) {
    targetType = "NutritionalValue";
  } else {
    throw ArgumentError("Unknown target type: ${target.trackedType}");
  }
  
  return {
    typeColumn:      targetType,
    trackedIdColumn: target.trackedId,
    amountColumn:    target.amount,
    unitColumn:      target.unit == null ? "" : unitToString(target.unit!),
    primaryColumn:   target.isPrimary,
    orderIdColumn:   target.orderId,
  };
}

// ----- Utility -----

// Type targetIntToType(int typeInt) {
//   switch (typeInt) {
//     case 0:
//       return NutritionalValue;
//     case 1:
//       return Product;
//     default:
//       throw ArgumentError("Unknown target type: $typeInt");
//   }
// }

// int targetTypeToInt(Type type) {
//   switch (type) {
//     case NutritionalValue:
//       return 0;
//     case Product:
//       return 1;
//     default:
//       throw ArgumentError("Unknown target type: $type");
//   }
// }