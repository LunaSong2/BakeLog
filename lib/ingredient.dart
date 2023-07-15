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
          _textEditingController.text = _changedAmount;
        });
      },
      child: Container(
        width: 60, height: 30,
        color: Theme.of(context).colorScheme.tertiaryContainer,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(left:5, right:5),
        child: _isEditing ? TextFormField(
          controller: _textEditingController,
          autofocus: true,
          textAlign: TextAlign.right,

          onTapOutside: (value) {
            setState(() {
              _isEditing = false;
            });
          },
          onFieldSubmitted: (value) {
            setState(() {
              _isEditing = false;
              widget.refreshCallback(double.parse(value)/widget.amount);
              _changedAmount = getChangedAmountString();
            });
          },
        ) : Text(_changedAmount) ),
      );
  }
}

class IngredientTextField extends StatefulWidget {
  IngredientTextField({required this.isEdit, required this.width, required this.ingredient, required this.type, required this.style, required this.alignment, super.key});

  final bool isEdit;
  final double width;
  final Ingredient ingredient;
  final int type;
  final TextStyle? style;
  final AlignmentGeometry alignment;

  @override
  State<IngredientTextField> createState() => _IngredientTextFieldState();
}

class _IngredientTextFieldState extends State<IngredientTextField> {
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.type == 0) {
      textEditingController.text = widget.ingredient.name;
    } else if (widget.type == 1) {
      textEditingController.text = widget.ingredient.amount;
    } else {
      textEditingController.text = widget.ingredient.unit;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isEdit ? Container(
      alignment: widget.alignment,
      width: widget.width, height: 30,
      decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              width: 2.0)),
      child: TextField(
          controller: textEditingController,
          onChanged: (value) { //todo check performance
            if (widget.type == 0) {
              widget.ingredient.name = value;
            } else if (widget.type == 1) {
              widget.ingredient.amount = value;
            } else {
              widget.ingredient.unit = value;
            }
          }
      )
    )
    : Container(alignment: widget.alignment,
      width: widget.width, height: 30,
      child: Text(textEditingController.text, style: widget.style),
    );
  }
}

class IngredientView extends StatelessWidget {
  IngredientView({required this.isEdit, required this.ingredient, required this.amountRatio,
    required this.refreshCallback, required this.deleteCallback}) : super(key: ObjectKey(ingredient));

  final bool isEdit;
  final Ingredient ingredient;
  final Function(double) refreshCallback;
  final Function(Object) deleteCallback;
  final double amountRatio;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(alignment: Alignment.center,
          width: 30, height: 30,
          child: const Icon(Icons.arrow_right),
        ),
        IngredientTextField(
          isEdit: isEdit,
          width: 100,
          ingredient: ingredient,
          type: 0, //todo replace enum
          style: Theme.of(context).textTheme.bodyLarge,
          alignment: Alignment.centerLeft),
        IngredientTextField(
          isEdit: isEdit,
          width: 50,
          ingredient: ingredient,
          type: 1,
          style: Theme.of(context).textTheme.titleLarge,
          alignment: Alignment.centerRight),
        Container(width: 10, height:30),
        IngredientTextField(
          isEdit: isEdit,
          width: 50,
          ingredient: ingredient,
          type: 2,
          style: Theme.of(context).textTheme.bodyLarge,
          alignment: Alignment.centerLeft),
        isEdit ? Container(width: 30, height:30, child: IconButton(icon: const Icon(Icons.remove), onPressed:(){ deleteCallback(ingredient);}))
            : AmountChanger(amount: double.parse(ingredient.amount), amountRatio: amountRatio, refreshCallback: refreshCallback,),
      ],
    );
  }
}