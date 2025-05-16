import '../../utility/data_logic.dart';
import '../../utility/text_logic.dart';
import 'data_objects.dart';

// import 'dart:developer' as devtools show log;

// multiple tables
const idColumn                    = "id";
const productIdColumn             = "product_id";
const amountColumn                = "amount";
const orderIdColumn               = "order_id";
const unitColumn                  = "unit";

// product table
const nameColumn                  = "name";
const descriptionColumn           = "description";
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

Product mapToProduct(Map<String, dynamic> map) {
  List<ProductQuantity> ingredients = [];
  List<ProductNutrient> nutrients = [];
  if (map["ingredients"] != null) {
    ingredients = (map["ingredients"] as List).map((ingr) => mapToProductQuantity(ingr)).toList();
  }
  if (map["nutrients"] != null) {
    nutrients = (map["nutrients"] as List).map((nut) => mapToProductNutrient(nut)).toList();
  }
  
  return Product(
    id:                    map[idColumn] as int,
    name:                  map[nameColumn] as String,
    description:           map[descriptionColumn] as String? ?? "",
    creationDate:          DateTime.parse(map[creationDateColumn] as String),
    lastEditDate:          DateTime.parse(map[lastEditDateColumn] as String),
    temporaryBeginning:    condParse(map[temporaryBeginningColumn] as String?),
    temporaryEnd:          condParse(map[temporaryEndColumn] as String?),
    isTemporary:           map[isTemporaryColumn] == 1,
    defaultUnit:           unitFromString(map[defaultUnitColumn] as String),
    densityConversion:     Conversion.fromString(map[densityConversionColumn] as String),
    quantityConversion:    Conversion.fromString(map[quantityConversionColumn] as String),
    quantityName:          map[quantityNameColumn] as String,
    autoCalc:              map[autoCalcAmountColumn] == 1,
    amountForIngredients:  toDouble(map[amountForIngredientsColumn] ?? 100),
    ingredientsUnit:       unitFromString((map[ingredientsUnitColumn] ?? map[defaultUnitColumn]) as String),
    amountForNutrients:    toDouble(map[amountForNutrientsColumn] ?? 100),
    nutrientsUnit:         unitFromString((map[nutrientsUnitColumn] ?? map[defaultUnitColumn]) as String),
    ingredients:           ingredients,
    nutrients:             nutrients,
  );
}
  
ProductQuantity mapToProductQuantity(Map<String, Object?> map) =>
 ProductQuantity(
    productId: map[productIdColumn] as int,
    amount:    toDouble(map[amountColumn]),
    unit:      unitFromString(map[unitColumn] as String),
  );

NutritionalValue mapToNutritionalValue(Map<String, Object?> map) =>
  NutritionalValue(
    map[idColumn] as int,
    (map[orderIdColumn] ?? map[idColumn]) as int,
    map[nameColumn] as String,
    map[unitNameColumn] as String,
    map[showFullNameColumn] == 1,
  );

ProductNutrient mapToProductNutrient(Map<String, Object?> row) =>
  ProductNutrient(
    nutritionalValueId: row[nutritionalValueIdColumn] as int,
    productId:          row[productIdColumn] as int,
    autoCalc:           row[autoCalcColumn] == 1,
    value:              toDouble(row[valueColumn]),
  );

Meal mapToMeal(Map<String, Object?> map) =>
 Meal(
    id:               map[idColumn] as int,
    dateTime:         DateTime.parse(map[dateTimeColumn] as String),
    creationDate:     DateTime.parse(map[creationDateColumn] as String? ?? map[dateTimeColumn] as String),
    lastEditDate:     DateTime.parse(map[lastEditDateColumn] as String? ?? map[dateTimeColumn] as String),
    productQuantity:  ProductQuantity(
      productId:        map[productIdColumn] as int,
      amount:           toDouble(map[amountColumn]),
      unit:             unitFromString(map[unitColumn] as String),
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
    descriptionColumn:          product.description,
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
    primaryColumn:   target.isPrimary ? 1 : 0,
    orderIdColumn:   target.orderId,
  };
}