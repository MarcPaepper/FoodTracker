import 'package:food_tracker/services/data/data_objects.dart';

const createProductTable = '''
CREATE TABLE IF NOT EXISTS "product" (
	"id"	INTEGER NOT NULL UNIQUE,
	"name"	TEXT NOT NULL UNIQUE,
	"density_conversion"	TEXT,
	"quantity_conversion"	TEXT,
	"quantity_name"	TEXT,
	"default_unit"	TEXT,
	"auto_calc_amount"	INTEGER,
	"amount_for_ingredients"	INTEGER,
	"ingredients_unit"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
''';
const createNutrionalValueTable = '''
CREATE TABLE IF NOT EXISTS "nutritional_value" (
	"id"	INTEGER NOT NULL UNIQUE,
	"name"	TEXT NOT NULL UNIQUE,
	"unit"	TEXT NOT NULL,
	PRIMARY KEY("id" AUTOINCREMENT)
);
''';
const createIngredientTable = '''
CREATE TABLE "ingredient" (
	"ingredient_id"	INTEGER,
	"is_contained_in_id"	INTEGER,
	"amount"	INTEGER,
	"unit"	TEXT,
	FOREIGN KEY("ingredient_id") REFERENCES "product"("id")
);
''';

final defaultNutrionalValues = [
  NutrionalValue(1, "Calories", "kcal"),
  NutrionalValue(2, "Protein", "g"),
  NutrionalValue(3, "Carbohydrates", "g"),
  NutrionalValue(4, "Fat", "g"),
  NutrionalValue(5, "Fiber", "g"),
  NutrionalValue(6, "Sugar", "g"),
  NutrionalValue(7, "Salt", "g"),
];