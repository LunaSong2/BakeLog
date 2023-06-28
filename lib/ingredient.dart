import 'package:flutter/material.dart';
import 'package:bakinglog/page_log.dart';
import 'package:bakinglog/data.dart';

class IngredientWidget extends StatelessWidget {
  IngredientWidget({required this.ingredient}) : super(key: ObjectKey(ingredient));

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(alignment: Alignment.centerLeft,
          width: 100, height: 30,
          child: Text(ingredient.name),
        ),
        Container(alignment: Alignment.centerRight,
          width: 50, height: 30,
          child: Text(ingredient.amount),
        ),
        Container(alignment: Alignment.centerLeft,
          width: 50, height: 30,
          child: Text(' ' + ingredient.unit),
        )
      ],
    );
  }
}