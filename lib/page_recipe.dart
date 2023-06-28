import 'package:flutter/material.dart';
import 'package:bakinglog/page_log.dart';
import 'package:bakinglog/data.dart';
import 'package:bakinglog/ingredient.dart';

class IngredientList extends StatelessWidget {
  IngredientList({required this.recipe}) : super(key: ObjectKey(recipe));

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(5),
      itemCount: recipe.ingredients.length,
      itemBuilder: (BuildContext context, int index) {
        return IngredientWidget(ingredient: recipe.ingredients[index]);
      },
    );
  }
}

class HowToList extends StatelessWidget {
  HowToList({required this.recipe}) : super(key: ObjectKey(recipe));

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(5),
      itemCount: recipe.howTo.length,
      itemBuilder: (BuildContext context, int index) {
        return Container(alignment: Alignment.centerLeft,
        height: 30,
        child: Text('${index+1}. ${recipe.howTo[index]}'));
     },
    );
  }
}

class LogList extends StatelessWidget {
  LogList({required this.recipe}) : super(key: ObjectKey(recipe));

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(1.0),
        itemCount: recipe.bakeLog.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            leading: Icon(Icons.bus_alert_rounded),
            title: Text('${recipe.bakeLog[index].name}'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => LogPage(bakelog: recipe.bakeLog[index])));
            },
          );
        });
  }
}


class RecipePage extends StatefulWidget {
  const RecipePage({required this.recipe, super.key});
  final Recipe recipe;

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  int count = 0;

  void _addCount() {
    setState(() {count++;});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.recipe.recipeName),
          backgroundColor: Colors.green),
      body: Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Ingredients', style: Theme.of(context).textTheme.headlineSmall),
            Flexible(child: IngredientList(recipe: widget.recipe)),
            Divider(),
            Text('How to', style: Theme.of(context).textTheme.headlineSmall),
            Flexible(child: HowToList(recipe: widget.recipe)),
            Divider(),
            Text('Baking Log', style: Theme.of(context).textTheme.headlineSmall),
            Flexible(child: LogList(recipe: widget.recipe)),
          ],
        )
      )
    );
  }
}