class UserData {
  String user;
  List<Recipe> recipes;

  UserData({required this.user, required this.recipes});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      user: json['user'],
      recipes: List<Recipe>.from(json['recipes'].map((recipe) => Recipe.fromJson(recipe))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user,
      'recipes': List<dynamic>.from(recipes.map((recipe) => recipe.toJson())),
    };
  }
}

class Recipe {
  String recipeName = '';
  int dateCreated = 0;
  int dateModified = 0;
  List<Ingredient> ingredients = [];
  List<String> howTo = [];
  List<BakeLog> bakeLog = [];

  Recipe({
    required this.recipeName,
    required this.dateCreated,
    required this.dateModified,
    required this.ingredients,
    required this.howTo,
    required this.bakeLog,
  });

  Recipe.withNameOnly(this.recipeName);

  factory Recipe.fromJson(Map<String, dynamic> json) {
    List<dynamic> jsonIngredients = json['ingredients'] ?? [];
    List<Ingredient> ingredients = jsonIngredients.map((ingredient) => Ingredient.fromJson(ingredient)).toList();

    List<dynamic> jsonHowTo = json['how_to'] ?? [];
    List<String> howTo = jsonHowTo.map((step) => step.toString()).toList();

    List<dynamic> jsonBakeLog = json['bake_log'] ?? [];
    List<BakeLog> bakeLog = jsonBakeLog.map((log) => BakeLog.fromJson(log)).toList();

    return Recipe(
      recipeName: json['recipe_name'] ?? '',
      dateCreated: json['date_created'] ?? 0,
      dateModified: json['date_modified'] ?? 0,
      ingredients: ingredients,
      howTo: howTo,
      bakeLog: bakeLog,
    );
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> jsonIngredients = ingredients.map((ingredient) => ingredient.toJson()).toList();
    List<dynamic> jsonHowTo = howTo.map((step) => step).toList();
    List<Map<String, dynamic>> jsonBakeLog = bakeLog.map((log) => log.toJson()).toList();

    return {
      'recipe_name': recipeName,
      'date_created': dateCreated,
      'date_modified': dateModified,
      'ingredients': jsonIngredients,
      'how_to': jsonHowTo,
      'bake_log': jsonBakeLog,
    };
  }
}

class Ingredient {
  String name;
  String unit;
  String amount;

  Ingredient({
    required this.name,
    required this.unit,
    required this.amount,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] ?? '',
      unit: json['unit'] ?? '',
      amount: json['amount'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'unit': unit,
      'amount': amount,
    };
  }
}


class BakeLog {
  String name;
  int score;
  String imageUrl;
  int date;

  BakeLog({
    required this.name,
    required this.score,
    required this.imageUrl,
    required this.date,
  });

  factory BakeLog.fromJson(Map<String, dynamic> json) {
    return BakeLog(
      name: json['name'],
      score: json['score'],
      imageUrl: json['image_url'],
      date: json['date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'score': score,
      'image_url': imageUrl,
      'date': date,
    };
  }
}
