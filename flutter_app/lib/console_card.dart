import 'package:flutter/material.dart';
import 'cutom_logging.dart';
import 'package:intl/intl.dart';

class ConsoleCard extends StatefulWidget {
  @override
  _ConsoleCardState createState() => _ConsoleCardState();
}

class _ConsoleCardState extends State<ConsoleCard> {
  String _mOut = '';
  ScrollController _scrollController = ScrollController();

  void _print(Object object) {
    setState(() {
      if (_mOut.isNotEmpty) _mOut += '\n';
      Intl.defaultLocale = 'en_US';
      //DateFormat.Hms('us').format(DateTime.now())+ ": " +
      _mOut +=
          DateFormat.Hms().format(DateTime.now()) + ": " + object.toString();
    });
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    Log().addLogFunc('ConsoleCard', _print);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              child: Text(
                'Console',
                style: Theme.of(context).textTheme.headline,
              ),
              width: double.infinity,
            ),
            SizedBox(
              width: double.infinity,
              child: Container(
                height: 200,
                color: Colors.grey[700],
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Text(
                    _mOut,
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10.0,
                        color: Colors.grey[200]),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
