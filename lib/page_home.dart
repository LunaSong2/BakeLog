import 'package:flutter/material.dart';
import 'package:bakinglog/page_recipe.dart';
import 'package:bakinglog/data.dart';

typedef RecipeClicked = Function(Recipe recipe);

class RecipeListItem extends StatelessWidget {
  RecipeListItem({required this.recipe, required this.onClick}) : super(key: ObjectKey(recipe));

  final Recipe recipe;
  final RecipeClicked onClick;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => RecipePage(recipe: recipe)));},
      title: Text(recipe.recipeName),
      subtitle: Text(recipe.dateCreated.toString(), style: TextStyle(fontWeight: FontWeight.w200)),
      trailing: const Icon(Icons.more_vert),
    );
  }
}

class RecipeList extends StatefulWidget {
  const RecipeList({required this.recipes, super.key});

  final List<Recipe> recipes;

  @override
  State<RecipeList> createState() => _RecipeListState();
}

class _RecipeListState extends State<RecipeList> {
  void _openRecipePage(Recipe recipe) {
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Baking Log',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'New Recipe',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => RecipePage(recipe: Recipe.withNameOnly('new'))));}
          ),
          IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: (){}),
          IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: (){}),
        ]),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: widget.recipes.map((recipe) {
          return RecipeListItem( recipe: recipe, onClick: _openRecipePage,);}).toList()),
    );
  }
}