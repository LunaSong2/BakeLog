import 'package:flutter/material.dart';
import 'package:bakinglog/page_log.dart';
import 'package:bakinglog/data.dart';
import 'package:bakinglog/ingredient.dart';

class IngredientList extends StatefulWidget {
  const IngredientList({required this.recipe, required this.isEdit, super.key});
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

  void addNewIngredient() {
    setState(() {
      widget.recipe.ingredients.add(Ingredient(name:"", unit:"g", amount:"0"));
    });
  }

  void deleteIngredient(Object obj) {
    setState(() {
      widget.recipe.ingredients.remove(obj);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top:5.0),
        itemCount: widget.recipe.ingredients.length + (widget.isEdit? 1 : 0),
        separatorBuilder: (context, index) => const Divider(
          color: Colors.grey, height: 1.0),
        itemBuilder: (context, index) {
          return (index == widget.recipe.ingredients.length)?
              IconButton(icon: const Icon(Icons.add), onPressed:(){ addNewIngredient(); })
              : IngredientView(isEdit: widget.isEdit, ingredient: widget.recipe.ingredients[index],
            amountRatio: amountRatio, refreshCallback: refreshChildren, deleteCallback: deleteIngredient,);
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
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(0),
        itemCount: widget.recipe.howTo.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(alignment: Alignment.centerLeft,
          //height: 30,
          child: Text(widget.recipe.howTo[index]));
       },
    );
  }
}

class LogList extends StatefulWidget {
  LogList({required this.recipe, required this.isEdit}) : super(key: ObjectKey(recipe));

  final Recipe recipe;
  final bool isEdit;

  @override
  _LogListState createState() => _LogListState();
}

class _LogListState extends State<LogList> {
  @override
  void initState() {
    super.initState();
  }

  void refreshChildren() {
    setState(() {
    });
  }

  void addNewLog() {
    setState(() {
      widget.recipe.bakeLog.add(BakeLog(name: "${widget.recipe.recipeName} #${widget.recipe.bakeLog.length + 1}",
          score: 5, imageUrl: "", date: DateTime.now().toString().substring(0,16), note:""),);
    });
  }

  void deleteLog(Object obj) {
    setState(() {
      widget.recipe.bakeLog.remove(obj);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(5.0),
      itemCount: widget.recipe.bakeLog.length + (widget.isEdit ? 0 : 1),
      itemBuilder: (BuildContext context, int index) {
        return (index == widget.recipe.bakeLog.length) ? Card (
            child: IconButton(icon: const Icon(Icons.add), onPressed:() {
              addNewLog();
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => LogPage(bakelog: widget.recipe.bakeLog[index], isEdit: true,))).then((_)=>refreshChildren());
            }))
        : Card(
          child: ListTile(
            leading: const Icon(Icons.cookie_outlined),

            title: Text(widget.recipe.bakeLog[index].name),
            subtitle: Text(widget.recipe.bakeLog[index].note),
            trailing: widget.isEdit? IconButton(icon: const Icon(Icons.remove), onPressed: (){ deleteLog(widget.recipe.bakeLog[index]);})
                : Text(widget.recipe.bakeLog[index].date),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => LogPage(bakelog: widget.recipe.bakeLog[index]))).then((_)=>refreshChildren());}
        ));
      });
  }
}

class RecipePage extends StatefulWidget {
  const RecipePage({required this.recipe, this.isEdit = false, super.key});
  final Recipe recipe;
  final bool isEdit;

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  bool isEdit = false;
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isEdit = widget.isEdit;
    textEditingController.text = widget.recipe.recipeName;
  }

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
          ],
        title: isEdit ? TextField(
          controller: textEditingController,
          onChanged: (value) {
            widget.recipe.recipeName = value;
          }, )
          : Text(widget.recipe.recipeName),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Divider(height:10, thickness: 0, color: Colors.transparent),
              Text('  Ingredients', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
              IngredientList(recipe: widget.recipe, isEdit: isEdit),
              Divider(height:20, thickness: 20, color: Theme.of(context).colorScheme.primaryContainer),
              const Divider(height:5, thickness: 0, color: Colors.transparent),
              Text('  How to', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
              Container(padding: const EdgeInsets.all(10),child: HowToList(recipe: widget.recipe, isEdit: isEdit,),),
              Divider(height:30, thickness: 20, color: Theme.of(context).colorScheme.primaryContainer),
              Text('  Bake Log', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
              Container(child: LogList(recipe: widget.recipe, isEdit: isEdit)),
            ],
          )
        )
      )
    );
  }
}