import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class UserData {
  List<Recipe> recipes;
  String appVersion;
  int schemaVersion;

  UserData({required this.recipes, required this.appVersion, this.schemaVersion = 1});

  factory UserData.fromJson(Map<String, dynamic> json) {
    int version = json['schema_version'] ?? 1;
    return UserData(
      recipes: List<Recipe>.from(json['recipes'].map((recipe) => Recipe.fromJson(recipe))),
      appVersion: json['app_version'] ?? 'unknown',
      schemaVersion: version,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schema_version': schemaVersion,
      'recipes': List<dynamic>.from(recipes.map((recipe) => recipe.toJson())),
      'app_version': appVersion,
    };
  }
}

class Recipe {
  String recipeName = '';
  String dateCreated = '';
  String dateModified = '';
  List<Ingredient> ingredients = [];
  List<String> howTo = [""];
  List<BakeLog> bakeLog = [];
  bool isFavorite = false;

  Recipe({
    required this.recipeName,
    required this.dateCreated,
    required this.dateModified,
    required this.ingredients,
    required this.howTo,
    required this.bakeLog,
    this.isFavorite = false,
  });

  Recipe.createNew(this.recipeName, this.dateCreated);

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
      isFavorite: json['is_favorite'] ?? false,
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
      'is_favorite': isFavorite,
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
  String date;
  String note;

  BakeLog({
    required this.name,
    required this.score,
    required this.imageUrl,
    required this.date,
    required this.note,
  });

  factory BakeLog.fromJson(Map<String, dynamic> json) {
    return BakeLog(
      name: json['name'],
      score: json['score'],
      imageUrl: json['image_url'],
      date: json['date'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'score': score,
      'image_url': imageUrl,
      'date': date,
      'note' : note,
    };
  }
}

Future<void> uploadUserDataToFirestore(UserData userData) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('No user is currently signed in.');
    return;
  }
  final uid = user.uid;
  final jsonString = jsonEncode(userData.toJson());
  await FirebaseFirestore.instance.collection('users').doc(uid).set({'data': jsonString});
}

Future<UserData?> downloadUserDataFromFirestore() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final data = doc.data();
  if (data == null || data['data'] == null) return null;
  final jsonData = jsonDecode(data['data']);
  return UserData.fromJson(jsonData);
}
