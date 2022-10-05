import 'package:flutter/material.dart' ;
import 'package:wordgame/base.dart';
import 'package:wordgame/chat.dart';
import 'package:wordgame/selectclue.dart';
import 'package:wordgame/generators.dart';
import "package:async/async.dart" show StreamQueue;
import 'dart:async';
import 'dart:convert';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'blank.dart' if (dart.library.io) 'android.dart' if (dart.library.html) 'web.dart';

const DEBUG=false;
void log(string) {
  if (DEBUG) {
    print(string);
  }
}

const DEFAULT_BG = Colors.cyanAccent;

class Game extends StatefulWidget {
//  Socket socket;
  final Stream stream;
  final String name;
  final SockWrapper sockWrap;
//  final clueKey = GlobalKey<FormState>();
//  final guessKey = GlobalKey<FormState>();
  final GlobalKey<ChatboxState> chatKey;
  final sbKey = GlobalKey();
  Chatbox chatbox;
  Widget prev = Text('nothing');
  StreamQueue<String> wordgen;
  Sink<String> _wordinp;
  dynamic prevmsg;

/*  Clues.fromSocket({Key key, @required Socket socket, @required this.name}) :
    stream = socket.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()),

    super(key: key){
    sendMsg = (var msg) {
      socket.write(jsonEncode(msg)+'\n');
    };
  }*/

  Game({Key key, @required this.name, @required this.sockWrap, @required this.chatKey}) :
        stream = sockWrap.stream,
        sendMsg = sockWrap.sendMsg,
        super(key: key) {
    chatbox = Chatbox(key: chatKey, sendMsg: sendMsg,);
    var wgcont = StreamController<String>();
    wordgen = StreamQueue<String>(wgcont.stream);
    _wordinp = wgcont.sink;
  }

  final void Function(dynamic) sendMsg;

  @override
  _GameState createState() => _GameState();
}

Widget clueWidget(BuildContext context, String clue) {
  return Text(
    clue,
    style: Theme.of(context).textTheme.headlineMedium,
  );
}

//class PermanentState {
//  List<String> wordFiles = [];
//}

class _GameState extends State<Game> {

  OverlayEntry chatWindow;
  bool newMessages = false;
  bool gm = true;
  String currphase;

  Map<String, Color> playerClrs = Map();
  List<FileWeight> currsource;
  Color currclr;

//  PermanentState perm = PermanentState();

  @override
  void dispose() {
    super.dispose();
    if (widget.sockWrap.dispose != null) {
      widget.sockWrap.dispose();
    }
  }

  Widget theWord(BuildContext context, String word) {
    return Column(
      children: <Widget>[
        Text('The word is:', style: Theme.of(context).textTheme.bodyMedium),
        Card(child: Container(
            padding: EdgeInsets.all(15.0),
            color: Colors.amber[200],
            child: Text(word, style: Theme.of(context).textTheme.headlineMedium)),
        )
      ],
    );

  }

  void afterBuilt(void callback()) {

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      log('post build phase');
      callback();
    });
  }
  //incoming message handler, passes messages that update game state to rebuild the Game, and handling other messages specially
  dynamic passStream (dynamic jsonmsg) {
    try {
      log('jsonmsg: "' + jsonmsg + '"');
      var msg = jsonDecode(jsonmsg);
      if (msg['msgtype'] == 'status') {
        return msg;
      }
      else if (msg['msgtype'] == 'error') {
        error(context, msg['msg']);
      }
      else if (msg['msgtype'] == 'giveword') {
        widget._wordinp.add(msg['word']);
      }
      else if (msg['msgtype'] == 'removed') {
        Navigator.pop(context);
      }
      else if (msg['msgtype'] == 'chat') {
        widget.chatbox.addMsg(
            ChatMsg(player: msg['from'], message: msg['text']));
        if (widget.chatKey.currentState != null) {
          widget.chatKey.currentState.setState(() {});
        }
        else {
          setState(() {
            newMessages = true;
          });
        }
      }
      else if (msg['msgtype'] == 'setcolour') {
        log('to set colour');
        setState(() {
          log('setting colour');
          playerClrs[msg['player']] = Color(msg['colour']);
          log('colours: ' + playerClrs.toString());
        });
      }
      else if (msg['msgtype'] == 'wordsource') {
        log('setting wordfiles: ' + msg['source'].toString());
        currsource = msg['source'].map((fw) => FileWeight(fw)).toList(growable: false).cast<FileWeight>();
        log('currsource: ' + currsource.toString());
      }
      else if (msg['msgtype'] == 'allcolours') {
        playerClrs = msg['colours'].map((k,v) => MapEntry(k, Color(v))).cast<String,Color>();
        currclr = playerClrs[widget.name] ?? currclr;
      }

    } catch (e, stacktrace) {
      log('EXCEPTION:' + e.toString());
      log('Stack trace:' + stacktrace.toString());
    }
    return null;
  }

  void error(BuildContext context, String s) {
    showDialog(context: context, builder: (context)=>
        AlertDialog(
          title: Text('Error', style: Theme.of(context).textTheme.titleLarge.copyWith(color: Colors.red),),
          content: Text(s),
          backgroundColor: Colors.red[100],
          actions: <Widget>[
            TextButton(child: Text('Ok'),onPressed: () {
              Navigator.of(context).pop();
            },)
          ],
        )
    );
  }

  Widget buildAppBar(BuildContext context) {
    List<Widget> actions =[];
    if (gm) {
      actions += <Widget>[
        IconButton(
          icon: Icon(Icons.fast_forward),
          onPressed: () {
            confirmDialog(context, 'Go to next phase?', () {
              widget.sendMsg({
                'msgtype': 'nextphase',
                'currphase': currphase
              });
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.skip_next),
          onPressed: () {
            confirmDialog(context, 'Skip to next turn?', () {
              widget.sendMsg({
                'msgtype': 'nextturn'
              });
            });
          },
        ),
        PopupMenuButton<int>(
          onSelected: (val) {
            switch (val) {
              case 0:
                log('showing menu');
//                log(perm.wordFiles.toString());
                /*showMenu(context: context, position: RelativeRect.fromLTRB(100, 100, 100, 100),items: List.generate(perm.wordFiles.length, (i) {
                  String wf = perm.wordFiles[i];
                  return PopupMenuItem<String>(value: wf, child: Text(wf),);
                }
                )).then((value) {
                  log('sending setsource');
                  widget.sendMsg({
                    'msgtype': 'setsource',
                    'source': value
                  });
                });*/
                log(currsource);
                var selector = SourceSelector(files: currsource);
                showDialog(context: context, builder: (context) => AlertDialog(
                  title: Text('Choose weights of word files'),
                  content: selector,
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: const Text('Done'),
                      onPressed: () {
                        try {
                          widget.sendMsg(selector.encode());
                          Navigator.of(context).pop();
                        } catch (e) {
                          Navigator.of(context).pop();
                          error(context, 'Invalid weight');
                        }
                      },
                    ),
                  ],
                ));
                break;
              case 1:
                showDialog(
                  context: context,
                  builder: (context)=> AlertDialog(
                    title: const Text('Pick a color!'),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: currclr ?? DEFAULT_BG,
                        enableAlpha: false,
                        onColorChanged: (Color c){
                          currclr = c;
                        },
                        pickerAreaHeightPercent: 0.8,
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Done'),
                        onPressed: () {
                          widget.sendMsg({
                            'msgtype': 'setcolour',
                            'colour': currclr.value
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
                break;
              case 2:
                wordGenerator(widget, context);
                break;
              case 3:
                boardGenerator(widget, context);
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem(
                  child: Text('Select word source'),
                  value: 0
              ),
              PopupMenuItem(
                  child: Text('Select colour'),
                  value: 1
              ),
              PopupMenuItem(
                  child: Text('Word Generator'),
                  value: 2
              ),
              PopupMenuItem(
                  child: Text('Board Generator'),
                  value: 3
              )
            ];
          },
        )
      ];
    }

    actions.add(IconButton(
      icon: Icon(Icons.close),
      onPressed: () {
        confirmDialog(context, 'Quit the game?', () {
          widget.sendMsg({
            'msgtype': 'quit'
          });
          Navigator.pop(context);
        });
      },
    ));
    return AppBar(
      title: Text('game'),
      actions: actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    //List<String> clues = ['word1','word2',];
    //List<Widget> clueWidgets = new List.generate(clues.length, (int i) => clueWidget(context, clues[i]));
    TextEditingController clueCtrl = TextEditingController();
    TextEditingController guessCtrl = TextEditingController();
    log('building CluesState');

    return Scaffold(
        appBar: buildAppBar(context),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.chat),
          backgroundColor: newMessages ? Colors.redAccent[400] : Colors.blueAccent,
          onPressed: () {
            if (chatWindow == null) {
              setState(() {
                newMessages = false;
              });
              RenderBox renderBox = context.findRenderObject();
              var size = renderBox.size;
              var offset = renderBox.localToGlobal(Offset.zero);
              chatWindow = OverlayEntry(
                  builder: (context) {
                    log('building');
                    log('size' + size.toString());
                    log('offsfet' + offset.toString());
                    log('key: '+ widget.chatKey.toString());
                    log('keystate: '+ widget.chatKey.currentState.toString());
                    return Positioned(
                      left: 0.0,
                      bottom: size.height /2,
                      child: widget.chatbox,
                    );
                  }
              );
              log(chatWindow.toString());
              Overlay.of(context).insert(chatWindow);
            }
            else {
              chatWindow.remove();
              chatWindow = null;
            }

          },
        ),
        // TODO: Replace StreamBuilder with a listener that calls setState()
        body: StreamBuilder(
            stream:  widget.stream.map(passStream),
            key: widget.sbKey,
            builder: (context, snapshot) {
              log('building');
              var msg = snapshot.data;
              if (msg == null) {
                log('null data!');
                if (widget.prevmsg == null)
                  return widget.prev;
                msg = widget.prevmsg;
              }
              widget.prevmsg = msg;
              if (snapshot.connectionState == ConnectionState.done) {
                log('done!');
                afterBuilt(() {Navigator.pop(context);});
              }
              if (msg['msgtype']== 'status') {
                var mystat = msg['pers_status'];
                //var me = msg['self'];
                var pls = msg['players'];
                List<Widget> col = [];
                Widget playerw = null;
                bool isgm = msg['self']['is_gm'];
                if (isgm != gm) {
                  afterBuilt(() {setState(() {
                    gm = msg['is_gm'];
                  });});
                }
                currphase = msg['phase'];
                switch(msg['phase']) {
                  case 'Prelim': {
                    playerw = otherPlayers(pls, false, diff: false);
                    col = <Widget>[
                      ElevatedButton(onPressed: () {
                        widget.sendMsg({
                          'msgtype': 'nextturn',
                        });
                      },
                        child: Text("Start"),
                      )
                    ];
                    break;
                  }
                  case 'MakeClues': {
                    playerw = otherPlayers(pls, true);
                    if (mystat['role'] == 'clue') {
                      col.add(theWord(context, mystat['word']));
                      if (mystat['myclue'] != null) {
                        col.add(Text('Clue submitted:', style: Theme.of(context).textTheme.bodyMedium));
                        col.add(Text(mystat['myclue'], style: Theme.of(context).textTheme.headlineSmall));
                      }
                      else {
                        col += <Widget>[
                          Form(
                            child: Column(
                              children: <Widget>[
                                FractionallySizedBox(
                                  child: TextFormField(controller: clueCtrl, decoration: InputDecoration(hintText: 'clue'), autofocus: true,),
                                  widthFactor: 0.5,
                                ),
                                ElevatedButton(child: Text('submit'),onPressed: () {
                                  widget.sendMsg({
                                    'msgtype': 'sendclue',
                                    'clue': clueCtrl.text
                                  });
                                  clueCtrl.text = '';
                                },)
                              ],
                            ),
                          )
                        ];

                      }
                    }
                    else {
                      col.add(Text('Waiting for other players to enter clues.', style: Theme.of(context).textTheme.headlineMedium,));
                    }
                    break;
                  }
                  case 'InspectClues': {
                    playerw = otherPlayers(pls, true);
                    if (mystat['role'] == 'clue') {
                      col.add(theWord(context, mystat['word']));
                      Map clues = mystat['clues'];
                      List<Widget> cards = forEachClue(clues, pls, (clue, p) =>
                      new SelectClue(clue: clue['word'], player: p['name'],plid: p['id'], initialStatus: clue['shown'], cparent: widget,/*key: UniqueKey(),*/ background: playerClrs.containsKey(p['name']) ? playerClrs[p['name']] : DEFAULT_BG));
                      col.add(Wrap(children: cards));
                      col.add(ElevatedButton(
                        child: Text('confirm'),
                        onPressed: (){
                          widget.sendMsg({
                            'msgtype': 'ready'
                          });
                        },
                      ));
                    }
                    else {
                      col.add(Text('Waiting for other players to confirm clues', style: Theme.of(context).textTheme.headlineMedium,));
                    }
                    break;
//                  col += List.generate(length, (index) => null)
                  }
                  case 'MakeGuess': {
                    playerw = otherPlayers(pls, false);
                    bool guessing = mystat['role'] == 'guess';
                    List<Widget> cards = forEachClue(
                        mystat['clues'], pls, (clue, p) =>
/*                      Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 10.0),
                          child: Container(
                              color: Colors.cyanAccent,
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment
                                      .center,
                                  children: <Widget>[
                                    Text(player['name']),
                                    Card(
                                        color: Colors.cyanAccent[100],
                                        child: Text(
                                            guessing ? clue : clue['word'],
                                            style: Theme
                                                .of(context)
                                                .textTheme
                                                .headline4
                                        )
                                    )
                                  ]
                              )
                          )
                      )*/
                    SelectClue(clue: guessing ? clue : clue['word'], player: p['name'],plid: p['id'], initialStatus: guessing ? true : clue['shown'], cparent: widget, active: false, background: playerClrs.containsKey(p['name']) ? playerClrs[p['name']] : DEFAULT_BG,)
                    );
                    if (!guessing) {
                      col.add(theWord(context, mystat['word']));
                      //col.add(Wrap(children: forEachClue(mystat['clues'], pls, (clue, p) =>
//                        SelectClue(clue: clue['word'], player: p['name'],plid: p['id'], initialStatus: clue['shown'], cparent: widget, active: false,)),));
                    }
                    col.add(Text('The clues are:', style: Theme.of(context).textTheme.bodyMedium));
                    col.add(Wrap(children: cards));
                    if (guessing) {
                      col.add(Form(
                        child: Column(
                          children: <Widget>[
                            FractionallySizedBox(
                              child: TextFormField(controller: guessCtrl,
                                decoration: InputDecoration(hintText: 'guess'),autofocus: true,),
                              widthFactor: 0.5,
                            ),
                            ElevatedButton(child: Text('Submit'), onPressed: () {
                              widget.sendMsg({
                                'msgtype': 'sendguess',
                                'guess': guessCtrl.text
                              });
                              guessCtrl.text = '';
                            },)
                          ],
                        ),
                      ));
                    }
                    else {
                      col.add(Text(msg['guesser'] + ' is guessing', style: Theme.of(context).textTheme.headlineMedium,));
                    }
                    break;
                  }
                  case 'Complete': {
                    playerw = otherPlayers(pls, true, guesserReady: true);
                    col += <Widget> [
                      theWord(context, mystat['word']),
                      Wrap(children: forEachClue(mystat['clues'], pls, (clue, p) =>
                          SelectClue(clue: clue['word'], player: p['name'],plid: p['id'], initialStatus: clue['shown'], cparent: widget, active: false, background: playerClrs.containsKey(p['name']) ? playerClrs[p['name']] : DEFAULT_BG,)),),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(msg['guesser'] + ' guessed: ', style: Theme.of(context).textTheme.bodyMedium),
                          Text(mystat['guess'], style: Theme.of(context).textTheme.headlineSmall),
                        ],
                      ),
                      ElevatedButton(onPressed: () {
                        widget.sendMsg({
                          'msgtype': 'ready',
                        });
                      },
                        child: Text("Next turn"),
                      )
                    ];
                    break;
                  }
                  default: {
                    widget.prev = Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(snapshot.data, style: Theme
                                .of(context)
                                .textTheme
                                .bodyLarge)
                          ]
                      ),
                    );
                    if (mystat['role'] == 'guess') {

                    }
                    else {

                    }
                  }
                }
                if (playerw != null) {
                  Widget rest = /*Container(
                        alignment: Alignment.topCenter,
                        child: */Expanded(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: col,
                    //)
                  ));
                  bool wrapAll = false;
                  //Widget wrapper;
                  if (wrapAll) {
                    widget.prev = Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runAlignment: WrapAlignment.center,
                          direction: Axis.vertical,
                          children: <Widget>[
                            playerw,
                            rest
                          ],
                        )
                    );

                  }
                  else {
                    col.add(Expanded(child:Container(constraints: BoxConstraints(minHeight: 10.0),)));
                    widget.prev = LayoutBuilder(
                      builder: (context, constraints) {
                        //return Center(child: ListView(children: <Widget>[playerw]+ col.map((e) => Center(child: e)).toList(),));
                        return SingleChildScrollView(
                            child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: constraints.maxHeight - 80),
                                child: IntrinsicHeight(
                                    child:Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.max,
                                      children: <Widget>[Expanded(child:Container(constraints: BoxConstraints(minHeight: 10.0),)),playerw, Expanded(child:Container(constraints: BoxConstraints(minHeight: 10.0),))] + col,
                                    )
                                )
                            )
                        );
                      },
                    );

                  }
                }

              }
              else if (msg['msgtype'] == 'removed') {
                afterBuilt(() {Navigator.pop(context);});
              }
              else if (msg['msgtype'] == 'chat') {
                afterBuilt(() {
                  widget.chatbox.addMsg(ChatMsg(player: msg['from'], message: msg['text']));
                  if (widget.chatKey.currentState != null) {
                    widget.chatKey.currentState.setState(() {
                    });
                  }
                  else {
                    setState(() {
                      newMessages = true;
                    });
                  }

                });
              }
              return widget.prev;
            }
        )
    );
  }

  Widget otherPlayers(List pls, bool readyStatus, {bool diff = true, bool guesserReady = false}) {
    bool flex = false;
    Widget content = Container(
        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
        alignment: Alignment.center,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Players: ', style: Theme.of(context).textTheme.headlineSmall),
              Container(
                  child: Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    defaultColumnWidth: IntrinsicColumnWidth(),
                    children: List.generate(pls.length, (index) {
                      var p = pls[index];
                      //String s=p['name'];
                      bool guesser = p['role']== 'guess';
                      List<Widget> row = [];
                      if (diff) {
                        row.add(guesser ? Icon(Icons.arrow_right) : Text(''));
                      }
                      row.add(Text(p['name'], style: Theme.of(context).textTheme.titleLarge.apply(color: (diff && guesser ? Colors.amber[900] : Colors.black))));
                      if (readyStatus) {
                        row.add(TableCell(
                          child: (!guesser || guesserReady) ? Icon(p['ready'] ? Icons.check_circle : Icons.panorama_fish_eye, size: 20.0,) : Text('')  ,
                        ));
                      }
                      row.add(TableCell( verticalAlignment: TableCellVerticalAlignment.middle, child: Container(
                        alignment: Alignment.centerRight,
                        width: 70.0,
                        height: 20.0,
                        child: IconButton(
                          padding: EdgeInsets.all(0.0),
                          icon: Icon(Icons.cancel, size: 15.0,),
                          //iconSize: 15.0,
                          alignment: Alignment.center,
                          onPressed: () {
                            confirmDialog(context, 'Remove ' + p['name'] + ' from the game?', () {
                              widget.sendMsg({
                                'msgtype': 'remplr',
                                'id': p['id']
                              });
                            });
                          },
                        ),
                      )));
                      return TableRow(
                          children: row
                      );
                    }),
                  )
              )

            ]
        )
    );
    if (!flex) return content;
    return Flexible(
      flex: 1,
      fit: FlexFit.loose,
      child: content,
    );

  }
}

class FileWeight {
  FileWeight(Map m) {
    weight = m['weight'];
    file = m['filename'];
  }

  int weight;
  String file;
}

class SourceSelector extends StatelessWidget {
  List<FileWeight> files;
  List<TextEditingController> ctrlrs;

  SourceSelector({Key key, @required this.files}) :
        ctrlrs = files.map((fw) => TextEditingController(text: fw.weight.toString())).toList(), super(key: key);

  dynamic encode() {
    var list = List.generate(files.length, (i) {
      return {'filename'
          : files[i].file, 'weight': int.parse(ctrlrs[i].text)};
    });
    //files.map((fw) => {'filename': fw.file, 'weight': fw.weight});
    return {
      'msgtype': 'setsource',
      'source': list
    };
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> entries = List.generate(files.length, (i) => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text(files[i].file),
        ),
        Container(
            width: 50,
            child:TextField(controller: ctrlrs[i], keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false), )
        )
      ],
    ));
    return ListView(children: entries,shrinkWrap: true,);
  }
}


List<Widget> forEachClue(Map clues, List pls, Widget callback(dynamic clue, Map player)) {
  List<Widget> cards = [];
  for (var p in pls) {
    if (clues.containsKey(p['id'].toString())) {
      var clue = clues[p['id'].toString()];
      log('adding card for clue ' + clue.toString());
      Widget w = callback(clue, p);
      if (w != null) {
        cards.add(w);
      }
    }
  }
  return cards;
}
void confirmDialog(BuildContext context, String text, void callback ()) {
  showDialog(context: context, builder: (context) {
    return AlertDialog(
      content: Text(text),
      actions: <Widget>[
        TextButton(
          child: Text('Yes'),
          onPressed: () {
            Navigator.pop(context);
            callback();
          },
        ),
        TextButton(
          child: Text('No'),
          onPressed: () {
            Navigator.pop(context);
          },
        )
      ],
    );
  });
}
