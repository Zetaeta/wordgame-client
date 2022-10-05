import 'package:flutter/material.dart' ;

import 'package:wordgame/game.dart';

void boardGenerator(Game cw, BuildContext context) async {
  var cont = true;
  cw.sendMsg({'msgtype': 'getword'});
  while (cont) {
    //String word = await cw.wordgen.next;
    var result = await showDialog(context: context, builder: (context)=> AlertDialog(
      title: Text('Word Generator'),
      //content:
      actions: <Widget>[
        TextButton(
          child: const Text('Done'),
          onPressed: () {
            Navigator.of(context).pop<bool>(false);
          },
        ),
        TextButton(
          child: const Text('New'),
          onPressed: () {
            cw.sendMsg({'msgtype': 'getword'});
            Navigator.of(context).pop<bool>(true);
          },
        ),
      ],
    ));
    log(result);
    cont = (result == true);
    Navigator.push(context, MaterialPageRoute(
        builder: (context) =>
            Container(
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  defaultColumnWidth: IntrinsicColumnWidth(),
                  children: List.generate(5, (index) {
                    List<Widget> row = [];
                    for (var i=0; i<5; ++i) row.add(TableCell( verticalAlignment: TableCellVerticalAlignment.middle, child: Container(
                      alignment: Alignment.centerRight,
                      width: 70.0,
                      height: 20.0,
                      child: Card(child: Container(
                          padding: EdgeInsets.all(15.0),
                          color: Colors.amber[200],
                          child: Text("seven", textAlign: TextAlign.center, style: Theme.of(context).textTheme.displayMedium)),
                      ),
                    )));
                    return TableRow(
                        children: row
                    );
                  }),
                )
            )

    ));
  }
}

void wordGenerator(Game cw, BuildContext context) async {
  var cont = true;
  cw.sendMsg({'msgtype': 'getword'});
  while (cont) {
    String word = await cw.wordgen.next;
    var result = await showDialog(context: context, builder: (context) => AlertDialog(
      title: Text('Word Generator'),
      content:
      Card(child: Container(
          padding: EdgeInsets.all(15.0),
          color: Colors.amber[200],
          child: Text(word, textAlign: TextAlign.center, style: Theme.of(context).textTheme.displayMedium)),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Done'),
          onPressed: () {
            Navigator.of(context).pop<bool>(false);
          },
        ),
        TextButton(
          child: const Text('New'),
          onPressed: () {
            cw.sendMsg({'msgtype': 'getword'});
            Navigator.of(context).pop<bool>(true);
          },
        ),
      ],
    ));
    log(result);
    cont = (result == true);
  }
}
