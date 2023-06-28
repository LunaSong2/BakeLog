import 'package:flutter/material.dart';
import 'package:bakinglog/page_log.dart';
import 'package:bakinglog/data.dart';

class IngredientView extends StatelessWidget {
  IngredientView({required this.ingredient}) : super(key: ObjectKey(ingredient));

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(alignment: Alignment.center,
          width: 30, height: 30,
          child: const Icon(Icons.arrow_right),
        ),
        Container(alignment: Alignment.centerLeft,
          width: 100, height: 30,
          child: Text(ingredient.name, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Container(alignment: Alignment.centerRight,
          width: 50, height: 30,
          child: Text(ingredient.amount, style: Theme.of(context).textTheme.titleLarge),
        ),
        Container(alignment: Alignment.centerLeft,
          width: 50, height: 30,
          child: Text(' ' + ingredient.unit),
        ),
        Container(alignment: Alignment.centerRight,
            width: 50, height: 30,
            child: Text(ingredient.amount),
            color: Theme.of(context).colorScheme.tertiaryContainer
        ),
      ],
    );
  }
}