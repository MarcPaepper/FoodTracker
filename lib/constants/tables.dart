import 'package:food_tracker/services/data/data_objects.dart';

const createProductTable = '''
CREATE TABLE IF NOT EXISTS "product" (
	"id"	INTEGER,
	"name"	TEXT,
	"density_conversion"	TEXT,
	"quantity_conversion"	TEXT,
	"temporary_beginning" TEXT,
  "temporary_end" TEXT,
  "is_temporary" INTEGER,
	"quantity_name"	TEXT,
	"default_unit"	TEXT,
	"auto_calc_amount"	INTEGER,
	"amount_for_ingredients"	INTEGER,
	"ingredients_unit"	TEXT,
	"amount_for_nutrients"	INTEGER,
	"nutrients_unit"	TEXT,
	"creation_date"	TEXT,
	"last_edit_date"	TEXT,
);
''';
const createNutritionalValueTable = '''
CREATE TABLE IF NOT EXISTS "nutritional_value" (
	"id"	INTEGER,
	"name"	TEXT,
	"unit"	TEXT
);
''';
const createIngredientTable = '''
CREATE TABLE "ingredient" (
	"ingredient_id"	INTEGER,
	"is_contained_in_id"	INTEGER,
	"amount"	INTEGER,
	"unit"	TEXT,
	FOREIGN KEY("is_contained_in_id") REFERENCES "product"("id")
);
''';
const createProductNutrientTable = '''
CREATE TABLE "product_nutrient" (
	"nutritional_value_id"	INTEGER,
	"product_id"	INTEGER,
	"auto_calc"	INTEGER,
	"value"	INTEGER
);
''';

const productTableName = "product";
const nutritionalValueTableName = "nutritional_value";
const ingredientTableName = "ingredient";
const productNutrientTableName = "product_nutrient";

const productColumns = [
  '"id" INTEGER',
  '"name" TEXT',
  '"density_conversion" TEXT',
  '"quantity_conversion" TEXT',
  '"temporary_beginning" TEXT',
  '"temporary_end" TEXT',
  '"is_temporary" INTEGER',
  '"quantity_name" TEXT',
  '"default_unit" TEXT',
  '"auto_calc_amount" INTEGER',
  '"amount_for_ingredients" INTEGER',
  '"ingredients_unit" TEXT',
  '"amount_for_nutrients" INTEGER',
  '"nutrients_unit" TEXT',
	'"creation_date" TEXT',
	'"last_edit_date" TEXT',
];

const nutritionalValueColumns = [
  '"id" INTEGER',
  '"name" TEXT',
  '"unit" TEXT',
  '"order_id" INTEGER',
  '"show_full_name" INTEGER',
];

const ingredientColumns = [
  '"ingredient_id" INTEGER',
  '"is_contained_in_id" INTEGER',
  '"amount" INTEGER',
  '"unit" TEXT',
];

const productNutrientColumns = [
  '"nutritional_value_id" INTEGER',
  '"product_id" INTEGER',
  '"auto_calc" INTEGER',
  '"value" INTEGER',
];

var missingProductColumns = {
  "creation_date":  () => "UPDATE $productTableName SET creation_date = datetime('now') WHERE creation_date IS NULL;",
  "last_edit_date": () => "UPDATE $productTableName SET last_edit_date = datetime('now') WHERE last_edit_date IS NULL;",
};

var missingNutritionalValueColumns = {};
var missingIngredientColumns = {};
var missingProductNutrientColumns = {};

final defaultNutritionalValues = [
  NutritionalValue(0, 0, "Calories", "kcal", false),
  NutritionalValue(1, 1, "Fat", "g", true),
  NutritionalValue(2, 2, "Saturated Fat", "g", true),
  NutritionalValue(3, 3, "Carbohydrates", "g", true),
  NutritionalValue(4, 4, "Sugar", "g", true),
  NutritionalValue(5, 5, "Protein", "g", true),
  NutritionalValue(6, 6, "Salt", "g", true),
];