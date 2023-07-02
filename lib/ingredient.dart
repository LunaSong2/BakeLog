import 'package:flutter/material.dart';
import 'package:bakinglog/page_log.dart';
import 'package:bakinglog/data.dart';

class AmountChanger extends StatefulWidget {
  const AmountChanger({required this.amount, required this.refreshCallback, super.key});
  final String amount;
  final Function(double) refreshCallback;

  @override
  _AmountChangerState createState() => _AmountChangerState();
}

class _AmountChangerState extends State<AmountChanger> {
  bool _isEditing = false;
  TextEditingController _textEditingController = TextEditingController();
  String _amount = '0';

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _amount = widget.amount;
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isEditing = true;
          _textEditingController.text = _amount; });
      },
      child: _isEditing ? TextFormField(
        controller: _textEditingController,
        autofocus: true,
          onFieldSubmitted: (value) {
            setState(() {
            _isEditing = false;
            _amount = value;
            widget.refreshCallback(2.0); //todo change to ratio and update whole amount
            });
        },
      ) : Text(_amount),
    );
  }
}

class IngredientView extends StatelessWidget {
  IngredientView({required this.ingredient, required this.refreshCallback}) : super(key: ObjectKey(ingredient));

  final Ingredient ingredient;
  final Function(double) refreshCallback;

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
            child: AmountChanger(amount: ingredient.amount, refreshCallback: refreshCallback,),
            color: Theme.of(context).colorScheme.tertiaryContainer
        ),
      ],
    );
  }
}