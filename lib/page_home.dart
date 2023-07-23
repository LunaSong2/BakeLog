import 'package:flutter/material.dart';
import 'package:bakinglog/page_recipe.dart';
import 'package:bakinglog/data.dart';

typedef RecipeClicked = Function(Recipe recipe);

class RecipeListItem extends StatelessWidget {
  RecipeListItem({required this.recipe, required this.refreshCallback, required this.deleteCallback}) : super(key: ObjectKey(recipe));

  final Recipe recipe;
  final Function() refreshCallback;
  final Function(Object) deleteCallback;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => RecipePage(recipe: recipe))).then((_) => refreshCallback());},
      title: Text(recipe.recipeName),
      subtitle: Text(recipe.dateCreated.toString(), style: TextStyle(fontWeight: FontWeight.w200)),
      trailing:  IconButton(icon: const Icon(Icons.delete), onPressed: (){deleteCallback(recipe);}),
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
  void refresh() {
    setState(() {
    });
  }
  void deleteRecipe(Object obj) {
    setState(() {
      widget.recipes.remove(obj);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Baking Log v0.2',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'New Recipe',
            onPressed: () {
              setState(() { widget.recipes.add(Recipe.withNameOnly('new'));});
              Navigator.push(context, MaterialPageRoute(builder: (context) => RecipePage(recipe: widget.recipes.last, isEdit: true))).then((_) => refresh());}
          ),
          IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: (){}),
          IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: (){}),
        ]),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: widget.recipes.map((recipe) {
          return RecipeListItem( recipe: recipe, refreshCallback: refresh, deleteCallback: deleteRecipe,);}).toList()),
    );
  }
}