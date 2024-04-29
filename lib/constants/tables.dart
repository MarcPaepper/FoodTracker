import 'package:food_tracker/services/data/data_objects.dart';

const createProductTable = '''
CREATE TABLE IF NOT EXISTS "product" (
	"id"	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
	"name"	TEXT NOT NULL UNIQUE,
	"density_conversion"	TEXT,
	"quantity_conversion"	TEXT,
	"quantity_name"	TEXT,
	"default_unit"	TEXT,
	"auto_calc_amount"	INTEGER,
	"amount_for_ingredients"	INTEGER,
	"ingredients_unit"	TEXT,
	"amount_for_nutrients"	INTEGER,
	"ingredient_unit"	TEXT
);
''';
const createNutritionalValueTable = '''
CREATE TABLE IF NOT EXISTS "nutritional_value" (
	"id"	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
	"name"	TEXT NOT NULL UNIQUE,
	"unit"	TEXT NOT NULL
);
''';
const createIngredientTable = '''
CREATE TABLE "ingredient" (
	"ingredient_id"	INTEGER NOT NULL,
	"is_contained_in_id"	INTEGER NOT NULL,
	"amount"	INTEGER NOT NULL,
	"unit"	TEXT NOT NULL,
	FOREIGN KEY("is_contained_in_id") REFERENCES "product"("id")
);
''';
const createProductNutrientTable = '''
CREATE TABLE "product_nutrient" (
	"nutritional_value_id"	INTEGER NOT NULL,
	"product_id"	INTEGER NOT NULL,
	"auto_calc"	INTEGER NOT NULL,
	"value"	INTEGER
);
''';

const productTableName = "product";
const nutritionalValueTableName = "nutritional_value";
const ingredientTableName = "ingredient";
const productNutrientTableName = "product_nutrient";

const productColumns = [
  '"id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE',
  '"name" TEXT NOT NULL UNIQUE',
  '"density_conversion" TEXT',
  '"quantity_conversion" TEXT',
  '"quantity_name" TEXT',
  '"default_unit" TEXT',
  '"auto_calc_amount" INTEGER',
  '"amount_for_ingredients" INTEGER',
  '"ingredients_unit" TEXT',
];

const nutritionalValueColumns = [
  '"id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE',
  '"name" TEXT NOT NULL UNIQUE',
  '"unit" TEXT NOT NULL',
  '"order_id"	INTEGER NOT NULL UNIQUE',
  '"show_full_name"	INTEGER NOT NULL,',
];

const ingredientColumns = [
  '"ingredient_id" INTEGER NOT NULL',
  '"is_contained_in_id" INTEGER NOT NULL',
  '"amount" INTEGER NOT NULL',
  '"unit" TEXT NOT NULL',
];

const productNutrientColumns = [
  '"nutritional_value_id" INTEGER NOT NULL',
  '"product_id" INTEGER NOT NULL',
  '"auto_calc" INTEGER NOT NULL',
  '"value" INTEGER',
];

final defaultNutritionalValues = [
  NutritionalValue(0, 0, "Calories", "kcal", false),
  NutritionalValue(1, 1, "Fat", "g", true),
  NutritionalValue(2, 2, "Saturated Fat", "g", true),
  NutritionalValue(3, 3, "Carbohydrates", "g", true),
  NutritionalValue(4, 4, "Sugar", "g", true),
  NutritionalValue(5, 5, "Protein", "g", true),
  NutritionalValue(6, 6, "Salt", "g", true),
];