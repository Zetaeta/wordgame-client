import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wordgame/main.dart';

class Board extends StatefulWidget {
  final Clues cw;
  final List<String> words;
  //final List<List<WordCard>> cards;

  static _BoardState of(BuildContext context) => context.findAncestorStateOfType<_BoardState>();

  const Board({Key key, this.cw, this.words}) : super(key: key);
  @override
  _BoardState createState() => _BoardState();
}

class _BoardState extends State<Board> {
  int activeteam=0;
  bool active=false;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    double cellw=width * 0.95 / 5;
    double cellh=height * 0.8 / 5;
    List<Widget> actions = <Widget>[];
    for (var i=0;i<5;++i){
      actions.add(
        Container(padding: EdgeInsets.all(8.0),
          color: (active && (activeteam== i)) ? Colors.purpleAccent : Colors.transparent,
          child:
        RaisedButton(onPressed: (){
          setState(() {
            if(!active || activeteam!= i) {
              active = true;
              activeteam = i;
            }
            else active=false;
          });
        }, color: backgrounds[i], ),)
      );
    }
    actions.add(Container(constraints: BoxConstraints(minWidth: width/6),));
    return Scaffold(
      appBar: AppBar(
        title: Text('Board'),
        backgroundColor: Colors.purple[400],
        actions: actions /*[Ink(
          decoration: ShapeDecoration(color: backgrounds[0], shape: CircleBorder()),
          child: IconButton(
            icon: Icon(Icons.credit_card)
          ),
        ),
          RaisedButton(onPressed: (){}, color: backgrounds[0], child: Container(),)
        ]*/,
      ),
      body:
    Container(
        alignment: Alignment.center,
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          defaultColumnWidth: IntrinsicColumnWidth(),
          children: List.generate(5, (index) {
            List<Widget> row = [];
            for (var i=0; i<5; ++i) row.add(TableCell( verticalAlignment: TableCellVerticalAlignment.middle, child: Container(
                        width: cellw,
              height: cellh,
//                        height: 20.0,
              child: WordCard(word: widget.words[5*index+i], board: widget,)/* Card(child: Container(
                  padding: EdgeInsets.all(15.0),
                  color: Colors.amber[200],
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text(widget.words[5*index+i], textAlign: TextAlign.center, style: Theme.of(context).textTheme.headline2))),
              ),*/
            )));
            return TableRow(
                children: row
            );
          }),
        )
    )                                 ,);

  }
}


class WordCard extends StatefulWidget {
  final String word;
  final Board board;

  WordCard({Key key, @required this.word, @required this.board}) : super(key: key);
  @override
  _WordCardState createState() => _WordCardState();
}

List<Color> backgrounds = [Colors.amber[200], Colors.red, Colors.grey[350], Colors.blue[600], Colors.grey[900]];

class _WordCardState extends State<WordCard> {
  int team=0;
//  double cellh;
//  double cellw;
  void onTap(BuildContext context) {
    var bs=Board.of(context);
    if (bs.active) {
      bs.setState(() {
        bs.active=false;
      });
      setState(() {
        team = bs.activeteam;
  //      ++team;
  //      while (team>4) team -= 5;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //var background = show ? (widget.active ? Colors.cyanAccent : Colors.cyan[200]) : Colors.grey[350];
    var background = backgrounds[team];
    print(background);
    Widget interior = Container(
//        color: background,
        child:
              Card(
                  //color: background,
                  child: Container(
                      color: background,
                      padding: EdgeInsets.all(15.0),
                      //height: cellh,
                      //color: Colors.white.withAlpha(70),
                      child: FittedBox(fit: BoxFit.scaleDown, child: Text(widget.word, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headline2))),
                      /*child: Text(
                          widget.clue,
                          style: Theme.of(context).textTheme.headline4
                      )*/
                  )
    );
    Widget wrappedInt = GestureDetector(onTap: ()=>  onTap(context),child: interior);
    return Container(
        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
        child: wrappedInt
    );
  }
}
