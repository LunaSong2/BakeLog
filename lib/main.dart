import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:bakinglog/page_home.dart';
import 'package:bakinglog/data.dart';
import 'package:bakinglog/color_schemes.g.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      //darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      home: RecipeBuilder(),
    );
  }
}


class RecipeBuilder extends StatefulWidget {
  @override
  _RecipeBuilderState createState() => _RecipeBuilderState();
}

class _RecipeBuilderState extends State<RecipeBuilder> {
  UserData? userData;

  Future<void> loadRecipeDataForTest() async {
    String jsonString = await rootBundle.loadString('assets/data.json');
    Map<String, dynamic> jsonData = jsonDecode(jsonString);
    setState(() {
      userData = UserData.fromJson(jsonData);
    });
    print('Recipe from asset path loaded successfully');
  }

  Future<void> loadRecipeData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/data.json');
      String jsonString = await file.readAsString();
      Map<String, dynamic> jsonData = jsonDecode(jsonString);
      setState(() {
        userData = UserData.fromJson(jsonData);
      });
      print('Recipe loaded successfully');
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> saveRecipeData() async {
    if (userData != null) {
      String jsonString = jsonEncode(userData!.toJson());
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/data.json');
      await file.writeAsString(jsonString);
      print ('Recipe saved successfully');
    }
  }

  @override
  void initState() {
    super.initState();
    loadRecipeDataForTest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
//      appBar: AppBar(),
    body: RecipeList(recipes: userData!.recipes));}

/*  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Baking Log'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: loadRecipeDataForTest,
              child: Text('Load Test Recipe'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: loadRecipeData,
              child: Text('Load Recipe'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: saveRecipeData,
              child: Text('Save Recipe'),
            ),
          ],
        ),
      ),
    );
  }*/
}