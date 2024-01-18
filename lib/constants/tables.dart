import 'package:food_tracker/services/data/data_objects.dart';

const createProductTable = '''
CREATE TABLE IF NOT EXISTS "product" (
	"id"	INTEGER NOT NULL UNIQUE,
	"name"	TEXT NOT NULL UNIQUE,
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

final defaultNutrionalValues = [
  NutrionalValue(1, "Calories", "kcal"),
  NutrionalValue(2, "Protein", "g"),
  NutrionalValue(3, "Carbohydrates", "g"),
  NutrionalValue(4, "Fat", "g"),
  NutrionalValue(5, "Fiber", "g"),
  NutrionalValue(6, "Sugar", "g"),
  NutrionalValue(7, "Salt", "g"),
];