import '../../utility/data_logic.dart';
import '../../utility/text_logic.dart';
import 'data_objects.dart';

// multiple tables
const idColumn                    = "id";

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
const orderIdColumn               = "order_id";
const showFullNameColumn          = "show_full_name";
const hasTargetColumn             = "has_target";
const targetColumn                = "target";
const alwaysShowTargetColumn      = "always_show_target";

// ingredient table
const ingredientIdColumn          = "ingredient_id";
const isContainedInIdColumn       = "is_contained_in_id";
const amountColumn                = "amount";
const unitColumn                  = "unit";

// product nutrient table
const nutritionalValueIdColumn    = "nutritional_value_id";
const productIdColumn             = "product_id";
const autoCalcColumn              = "auto_calc";
const valueColumn                 = "value";

// meal table
const dateTimeColumn               = "date_time";
const mealAmountColumn             = "amount";
const mealUnitColumn               = "unit";


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
    row[hasTargetColumn] == 1,
    toDouble(row[targetColumn]),
    row[alwaysShowTargetColumn] == 1,
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
    idColumn:                   product.id,
    nameColumn:                 product.name,
    creationDateColumn:         product.creationDate?.toIso8601String(),
    lastEditDateColumn:         product.lastEditDate?.toIso8601String(),
    temporaryBeginningColumn:   product.temporaryBeginning?.toIso8601String(),
    temporaryEndColumn:         product.temporaryEnd?.toIso8601String(),
    isTemporaryColumn:          product.isTemporary,
    defaultUnitColumn:          product.defaultUnit.toString(),
    quantityNameColumn:         product.quantityName,
    autoCalcAmountColumn:       product.autoCalc,
    ingredientsUnitColumn:      product.ingredientsUnit.toString(),
    nutrientsUnitColumn:        product.nutrientsUnit.toString(),
    amountForIngredientsColumn: product.amountForIngredients,
    amountForNutrientsColumn:   product.amountForNutrients,
    densityConversionColumn:    product.densityConversion.toString(),
    quantityConversionColumn:   product.quantityConversion.toString(),
    "ingredients":              product.ingredients.map((ingr) => {
      productIdColumn:            ingr.productId,
      amountColumn:               ingr.amount,
      unitColumn:                 unitToString(ingr.unit),
    }).toList(),
    "nutrients":                product.nutrients.map((nut) => {
      nutritionalValueIdColumn:   nut.nutritionalValueId,
      autoCalcColumn:             nut.autoCalc,
      valueColumn:                nut.value,
    }).toList(),
  };
  
Map<String, dynamic> nutValueToMap(NutritionalValue nutValue) =>
  {
    idColumn:               nutValue.id,
    orderIdColumn:          nutValue.orderId,
    nameColumn:             nutValue.name,
    unitNameColumn:         nutValue.unit,
    showFullNameColumn:     nutValue.showFullName,
    hasTargetColumn:        nutValue.hasTarget,
    targetColumn:           nutValue.target,
    alwaysShowTargetColumn: nutValue.alwaysShowTarget,
  };
  
Map<String, dynamic> mealToMap(Meal meal) =>
  {
    idColumn:             meal.id,
    dateTimeColumn:       meal.dateTime.toIso8601String(),
    productIdColumn:      meal.productQuantity.productId,
    mealAmountColumn:     meal.productQuantity.amount,
    mealUnitColumn:       unitToString(meal.productQuantity.unit),
    creationDateColumn:   meal.creationDate?.toIso8601String(),
    lastEditDateColumn:   meal.lastEditDate?.toIso8601String(),
  };