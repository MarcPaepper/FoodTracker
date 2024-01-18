const createProductTable = '''
CREATE TABLE IF NOT EXISTS "product" (
	"id"	INTEGER NOT NULL UNIQUE,
	"name"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id" AUTOINCREMENT)
);
''';
const createNutrionalValueTable = '''
CREATE TABLE "nutrional_value" (
	"id"	INTEGER NOT NULL UNIQUE,
	"name"	TEXT NOT NULL UNIQUE,
	"unit"	TEXT NOT NULL,
	PRIMARY KEY("id" AUTOINCREMENT)
);
''';