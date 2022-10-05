import 'package:flutter/material.dart' ;

import 'package:wordgame/game.dart';

class SelectClue extends StatefulWidget {
  final String clue;
  final bool initialStatus;
  final String player;
  final int plid;
  final Game cparent;
  final bool active;
  final Color background;

  SelectClue({Key key, @required this.clue, @required this.player, @required this.plid, @required this.initialStatus, @required this.cparent, this.active = true, this.background = Colors.cyanAccent}) : super(key: key);
  @override
  _SelectClueState createState() => _SelectClueState();
}


class _SelectClueState extends State<SelectClue> {
  bool show;
  void onTap() {
    setState(() {
      show = !show;
    });
    widget.cparent.sendMsg({
      'msgtype': 'cluevis',
      'playerid': widget.plid,
      'visible': show
    });
  }

  @override
  void initState() {
    super.initState();
    show = widget.initialStatus;
    log('initState');
  }
  @override
  Widget build(BuildContext context) {
    //var background = show ? (widget.active ? Colors.cyanAccent : Colors.cyan[200]) : Colors.grey[350];
    var background = show ? widget.background : Colors.grey[350];
    log(background);
    Widget interior = Container(
        color: background,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(widget.player),
              Card(
                  color: background,
                  child: Container(
                      color: Colors.white.withAlpha(70),
                      child: Text(
                          widget.clue,
                          style: Theme.of(context).textTheme.headlineMedium
                      )
                  )
              )
            ]
        )
    );
    Widget wrappedInt = widget.active ? GestureDetector(onTap: onTap,child: interior) : interior;
    return Container(
        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
        child: wrappedInt
    );
  }
}
