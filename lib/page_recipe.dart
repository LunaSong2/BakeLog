import 'package:flutter/material.dart';
import 'package:bakinglog/page_log.dart';
import 'package:bakinglog/data.dart';
import 'package:bakinglog/ingredient.dart';

class IngredientList extends StatefulWidget {
  IngredientList({required this.recipe, required this.isEdit, super.key});
  final Recipe recipe;
  final bool isEdit;

  @override
  State<IngredientList> createState() => _IngredientListState();
}

class _IngredientListState extends State<IngredientList> {
  double amountRatio = 1.0;

  void refreshChildren(double ratio) {
    setState(() {
      amountRatio = ratio;
      print("AmountRatio : $amountRatio");
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top:5.0),
        itemCount: widget.recipe.ingredients.length,
        separatorBuilder: (context, index) => const Divider(
          color: Colors.grey, height: 1.0),
        itemBuilder: (context, index) {
          return IngredientView(isEdit: widget.isEdit, ingredient: widget.recipe.ingredients[index], amountRatio: amountRatio, refreshCallback: refreshChildren,);
        },
    );
  }
}

class HowToList extends StatefulWidget {
  HowToList({required this.recipe, required this.isEdit}) : super(key: ObjectKey(recipe));

  final Recipe recipe;
  final bool isEdit;

  @override
  _HowToListState createState() => _HowToListState();
}

class _HowToListState extends State<HowToList> {
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    textEditingController.text = widget.recipe.howTo[0];
  }

  @override
  Widget build(BuildContext context) {
    return widget.isEdit ? Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          width: 2.0)),
        child: TextField(
          controller: textEditingController,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textAlign: TextAlign.left,
          onChanged: (value) { //todo check performance
            widget.recipe.howTo[0] = value;
          }
        ))
      : ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(0),
        itemCount: widget.recipe.howTo.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(alignment: Alignment.centerLeft,
          //height: 30,
          child: Text('${widget.recipe.howTo[index]}'));
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
        padding: const EdgeInsets.all(5.0),
        itemCount: recipe.bakeLog.length,
        itemBuilder: (BuildContext context, int index) {
          return Card(
            child: ListTile(
              leading: Icon(Icons.bus_alert_rounded),
              title: Text('${recipe.bakeLog[index].name}'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => LogPage(bakelog: recipe.bakeLog[index])));
              },
            ));
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
  bool isEdit = false;

  void turnEditMode() {
    setState(() {
      isEdit = !isEdit;
      print("turnEditMode $isEdit");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          actions: [
            IconButton(
            icon: isEdit ? const Icon(Icons.done) : const Icon(Icons.edit),
            onPressed: () {turnEditMode();}),
            IconButton(icon: const Icon(Icons.delete), onPressed: (){}),
          ],
        title: Text(widget.recipe.recipeName),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Divider(height:10, thickness: 0, color: Colors.transparent),
              Text('  Ingredients', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
              IngredientList(recipe: widget.recipe, isEdit: isEdit),
              Divider(height:20, thickness: 20, color: Theme.of(context).colorScheme.primaryContainer),
              Divider(height:5, thickness: 0, color: Colors.transparent),
              Text('  How to', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
              Container(child: HowToList(recipe: widget.recipe, isEdit: isEdit,)),
              Divider(height:30, thickness: 20, color: Theme.of(context).colorScheme.primaryContainer),
              Text('  Bake Log', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
              Container(child: LogList(recipe: widget.recipe)),
            ],
          )
        )
      )
    );
  }
}