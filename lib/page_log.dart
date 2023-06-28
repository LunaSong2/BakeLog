import 'package:flutter/material.dart';
import 'package:bakinglog/data.dart';

class LogPage extends StatefulWidget {
  const LogPage({required this.bakelog, super.key});
  final BakeLog bakelog;

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  int count = 0;
  void _addCount() {
    setState(() { count++; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.bakelog.name)),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.bakelog.imageUrl.toString()),
            Divider(),
            Text('Score', style: Theme.of(context).textTheme.headlineSmall),
            Text(widget.bakelog.score.toString()),
            Divider(),
            Text('Date', style: Theme.of(context).textTheme.headlineSmall),
            Text(widget.bakelog.date.toString())
          ],
        )
    );
  }
}
