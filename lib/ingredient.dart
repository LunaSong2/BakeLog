import 'package:flutter/material.dart';
import 'package:bakinglog/page_log.dart';
import 'package:bakinglog/data.dart';

class AmountChanger extends StatefulWidget {
  AmountChanger({required this.amount, required this.amountRatio, required this.refreshCallback, super.key});
  final double amount;
  final double amountRatio;
  final Function(double) refreshCallback;

  @override
  _AmountChangerState createState() => _AmountChangerState();
}

class _AmountChangerState extends State<AmountChanger> {
  bool _isEditing = false;
  String _changedAmount = '';
  TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print("AmountChanger amount:${widget.amount} ratio:${widget.amountRatio}");
    _textEditingController = TextEditingController();
  }

  String removeTrailingZerosAndNumberfy(String n) {
    if(n.contains('.')){
      return n.replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "");
    }
    else{
      return n;
    }
  }

  String getChangedAmountString()
  {
    double amount = widget.amount * widget.amountRatio;
    String amountString = amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 3);

    return removeTrailingZerosAndNumberfy(amountString);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _changedAmount = getChangedAmountString();
    return GestureDetector(
      onTap: () {
        setState(() {
          _isEditing = true;
          _textEditingController.text = _changedAmount; });
      },
      child: _isEditing ? TextFormField(
        controller: _textEditingController,
        autofocus: true,
          onFieldSubmitted: (value) {
            setState(() {
              _isEditing = false;
              widget.refreshCallback(double.parse(value)/widget.amount);
              _changedAmount = getChangedAmountString();
            });},
      ) : Text(_changedAmount)
      );
  }
}

class IngredientView extends StatelessWidget {
  IngredientView({required this.ingredient, required this.amountRatio, required this.refreshCallback}) : super(key: ObjectKey(ingredient));

  final Ingredient ingredient;
  final Function(double) refreshCallback;
  final double amountRatio;

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
            width: 60, height: 30,
            child: AmountChanger(amount: double.parse(ingredient.amount), amountRatio: amountRatio, refreshCallback: refreshCallback,),
            color: Theme.of(context).colorScheme.tertiaryContainer
        ),
      ],
    );
  }
}