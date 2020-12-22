import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import "package:async/async.dart" show StreamQueue;
import 'package:flutter/material.dart' ;
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordgame/base.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'blank.dart' if (dart.library.io) 'android.dart' if (dart.library.html) 'web.dart';


const DEFAULT_BG = Colors.cyanAccent;
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: Login(),
//      home: Clues(title: 'Flutter Demo Home Page'),
    );
  }
}

class Login extends StatefulWidget {
  final _formKey = GlobalKey<FormState>();

  final chatKey = GlobalKey<ChatboxState>();

  // This widget is the root of your application.


  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool ws = false;
  String ip, name, port;
  TextEditingController ipController = TextEditingController(text: 'vps728133.ovh.net');
  TextEditingController nameController = TextEditingController(text: 'JohnSmith');
  TextEditingController portController = TextEditingController(text: '3001');

  @override
  void initState() {
    super.initState();
    loadPrefs();
  }

  loadPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      ipController.text = prefs.getString('ip') ?? ipController.text;
      portController.text = prefs.getString('port') ?? portController.text;
      nameController.text = prefs.getString('name') ?? nameController.text;
    });
  }

  savePrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('ip', ipController.text);
    prefs.setString('port', portController.text);
    prefs.setString('name', nameController.text);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(padding: EdgeInsets.all(20), child: Form(
              key: widget._formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('Use websocket:'),
                      Switch(value: ws, onChanged: (bool nv) {
                        setState(() {
                          ws = nv;
                        });
                      })
                    ]
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(child: TextFormField(
                        decoration: const InputDecoration(
                          hintText: 'server address',
                        ),
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter an address';
                          }
                          return null;
                        },
                        controller: ipController,
                      )),
                      Padding(child:Text(':'),padding: EdgeInsets.all(5.0)),
                      Container(width: 100.0, child: TextFormField(
                        decoration: const InputDecoration(
                          hintText: 'port',
                        ),
                        validator: (value) {
                          return null;
                        },
                        controller: portController,
                      )),
                    ],
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'name'
                    ),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                    controller: nameController,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: RaisedButton(
                      onPressed: () {
                        // Validate will return true if the form is valid, or false if
                        // the form is invalid.
                        var joinmsg = {"msgtype": "join", "name": nameController.text};
                        if (widget._formKey.currentState.validate()) {
                          getSockWrapper(ipController.text, portController.text, websock: ws).then((sw) {
                            sw.sendMsg(joinmsg);
                            savePrefs();
                            Navigator.push(context, MaterialPageRoute(
                                builder: (context) =>
                                    Clues(
                                      key: UniqueKey(),
                                      name: nameController.text,
                                      sockWrap: sw,
                                      chatKey: widget.chatKey,
                                    )));
                          });
/*                          if (ws) {
                            final channel = IOWebSocketChannel.connect('ws://'+ ipController.text + ':'+ portController.text);
                            channel.sink.add(joinmsg);
                            print('sent: ' + joinmsg);
                            print(channel.closeReason);
//                            final dchan = channel.transform(transformer);
                            Navigator.push(context, MaterialPageRoute(
                                builder: (context) =>
                                    Clues(
                                      name: nameController.text,
                                      stream: channel.stream,
                                      sendMsg: (msg) {
                                        channel.sink.add(jsonEncode(msg)+'\n');
                                      },
                                    )));
                          }
                          else {
                            Socket.connect(ipController.text, int.parse(portController.text))
                              .then((Socket sock) {
//                            sock.listen(socketHandler);
                              sock.write(joinmsg);
                              savePrefs();
                              Navigator.push(context, MaterialPageRoute(
                                  builder: (context) =>
                                      Clues.fromSocket(key: UniqueKey(), name: nameController.text,
                                          socket: sock)));
                            });
                          } */
                          // Process data.
                        }
                      },
                      child: Text('Submit'),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
//Uint8List buffer=Uint8List(0);
//StreamTransformer<Uint8List, String> stringReader = StreamTransformer.fromBind((Stream<Uint8List> sock) {
//});

class WordForm extends StatelessWidget {
  final TextEditingController _ctrlr = TextEditingController();
  final void Function(String) submit;
  final String hint;

  WordForm({Key key, @required this.submit, this.hint = ''}) : super(key: key);

  void doSubmit() {
    submit(_ctrlr.text);
    _ctrlr.text = '';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: UniqueKey(),
      child: Column(
        children: <Widget>[
          FractionallySizedBox(
            child: TextFormField(
              controller: _ctrlr,
              decoration: InputDecoration(hintText: 'clue'),
              autofocus: true,
              onFieldSubmitted: (s) => doSubmit(),
            ),
            widthFactor: 0.5,
          ),
          RaisedButton(child: Text('submit'),onPressed: doSubmit)
        ],
      ),
    );
  }
}

class Clues extends StatefulWidget {
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
  Clues({Key key, @required this.name, @required this.sockWrap, @required this.chatKey}) :
      stream = sockWrap.stream,
      sendMsg = sockWrap.sendMsg,
      super(key: key) {
    chatbox = Chatbox(key: chatKey, sendMsg: sendMsg,);
    var wgcont = StreamController<String>();
    wordgen = StreamQueue<String>(wgcont.stream);
    _wordinp = wgcont.sink;
  }

  void Function(dynamic) sendMsg;

  @override
  _CluesState createState() => _CluesState();
}

Widget clueWidget(BuildContext context, String clue) {
  return Text(
      clue,
      style: Theme.of(context).textTheme.display1,
    );
}

class PermanentState {
  List<String> wordFiles = [];
}

class _CluesState extends State<Clues> {

  OverlayEntry chatWindow;
  bool newMessages = false;
  bool gm = true;
  String currphase;

  Map<String, Color> playerClrs = Map();
  List<FileWeight> currsource;
  Color currclr;

  PermanentState perm = PermanentState();

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
        Text('The word is:', style: Theme.of(context).textTheme.bodyText2),
        Card(child: Container(
          padding: EdgeInsets.all(15.0),
          color: Colors.amber[200],
          child: Text(word, style: Theme.of(context).textTheme.headline4)),
        )
      ],
    );

  }

  void afterBuilt(void callback()) {

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      print('post build phase');
      callback();
    });
  }

  dynamic passStream (dynamic jsonmsg) {
    try {
      print('jsonmsg: "' + jsonmsg + '"');
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
        print('to set colour');
        setState(() {
          print('setting colour');
          playerClrs[msg['player']] = Color(msg['colour']);
          print('colours: ' + playerClrs.toString());
        });
      }
      else if (msg['msgtype'] == 'wordsource') {
        print('setting wordfiles: ' + msg['source'].toString());
        currsource = msg['source'].map((fw) => FileWeight(fw)).toList(growable: false).cast<FileWeight>();
        print('currsource: ' + currsource.toString());
      }
      else if (msg['msgtype'] == 'allcolours') {
        playerClrs = msg['colours'].map((k,v) => MapEntry(k, Color(v))).cast<String,Color>();
        currclr = playerClrs[widget.name] ?? currclr;
      }

    } catch (e, stacktrace) {
      print('EXCEPTION:' + e.toString());
      print('Stack trace:' + stacktrace.toString());
    }
    return null;
  }

  void error(BuildContext context, String s) {
    showDialog(context: context, child:
      AlertDialog(
        title: Text('Error', style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.red),),
        content: Text(s),
        backgroundColor: Colors.red[100],
        actions: <Widget>[
          FlatButton(child: Text('Ok'),onPressed: () {
            Navigator.of(context).pop();
          },)
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> clues = ['word1','word2',];
    List<Widget> clueWidgets = new List.generate(clues.length, (int i) => clueWidget(context, clues[i]));
    TextEditingController clueCtrl = TextEditingController();
    TextEditingController guessCtrl = TextEditingController();
    print('building CluesState');

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
                print('showing menu');
                print(perm.wordFiles.toString());
                /*showMenu(context: context, position: RelativeRect.fromLTRB(100, 100, 100, 100),items: List.generate(perm.wordFiles.length, (i) {
                  String wf = perm.wordFiles[i];
                  return PopupMenuItem<String>(value: wf, child: Text(wf),);
                }
                )).then((value) {
                  print('sending setsource');
                  widget.sendMsg({
                    'msgtype': 'setsource',
                    'source': value
                  });
                });*/
                print(currsource);
                var selector = SourceSelector(files: currsource);
                showDialog(context: context, child: AlertDialog(
                  title: Text('Choose weights of word files'),
                  content: selector,
                  actions: <Widget>[
                    FlatButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    FlatButton(
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
                  child: AlertDialog(
                    title: const Text('Pick a color!'),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: currclr ?? DEFAULT_BG,
                        enableAlpha: false,
                        onColorChanged: (Color c){
                          currclr = c;
                        },
                        showLabel: true,
                        pickerAreaHeightPercent: 0.8,
                      ),
                    ),
                    actions: <Widget>[
                      FlatButton(
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
    return Scaffold(
    appBar: AppBar(
        title: Text('game'),
        actions: actions,
      ),
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
                  print('building');
                  print('size' + size.toString());
                  print('offsfet' + offset.toString());
                  print('key: '+ widget.chatKey.toString());
                  print('keystate: '+ widget.chatKey.currentState.toString());
                  return Positioned(
                    left: 0.0,
                    bottom: size.height /2,
                    child: widget.chatbox,
                  );
                }
            );
            print(chatWindow.toString());
            Overlay.of(context).insert(chatWindow);
          }
          else {
            chatWindow.remove();
            chatWindow = null;
          }

        },
      ),
      body: StreamBuilder(
        stream:  widget.stream.map(passStream),
        key: widget.sbKey,
        builder: (context, snapshot) {
          print('building');
          var msg = snapshot.data;
          if (msg == null) {
            print('null data!');
            if (widget.prevmsg == null)
              return widget.prev;
            msg = widget.prevmsg;
          }
          widget.prevmsg = msg;
          if (snapshot.connectionState == ConnectionState.done) {
            print('done!');
            afterBuilt(() {Navigator.pop(context);});
          }
            if (msg['msgtype']== 'status') {
              var mystat = msg['pers_status'];
              var me = msg['self'];
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
                      RaisedButton(onPressed: () {
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
                      col.add(Text('Clue submitted:', style: Theme.of(context).textTheme.bodyText2));
                      col.add(Text(mystat['myclue'], style: Theme.of(context).textTheme.headline5));
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
                              RaisedButton(child: Text('submit'),onPressed: () {
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
                    col.add(Text('Waiting for other players to enter clues.', style: Theme.of(context).textTheme.headline4,));
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
                    col.add(RaisedButton(
                      child: Text('confirm'),
                      onPressed: (){
                        widget.sendMsg({
                          'msgtype': 'ready'
                        });
                      },
                    ));
                  }
                  else {
                    col.add(Text('Waiting for other players to confirm clues', style: Theme.of(context).textTheme.headline4,));
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
                  col.add(Text('The clues are:', style: Theme.of(context).textTheme.bodyText2));
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
                          RaisedButton(child: Text('Submit'), onPressed: () {
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
                    col.add(Text(msg['guesser'] + ' is guessing', style: Theme.of(context).textTheme.headline4,));
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
                        Text(msg['guesser'] + ' guessed: ', style: Theme.of(context).textTheme.bodyText2),
                        Text(mystat['guess'], style: Theme.of(context).textTheme.headline5),
                      ],
                    ),
                    RaisedButton(onPressed: () {
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
                                .bodyText1)
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
                Widget wrapper;
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

  List<Widget> forEachClue(Map clues, List pls, Widget callback(dynamic clue, Map player)) {
    List<Widget> cards = [];
    for (var p in pls) {
      if (clues.containsKey(p['id'].toString())) {
        var clue = clues[p['id'].toString()];
        print('adding card for clue ' + clue.toString());
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
          FlatButton(
            child: Text('Yes'),
            onPressed: () {
              Navigator.pop(context);
              callback();
            },
          ),
          FlatButton(
            child: Text('No'),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      );
    });
  }

  Widget otherPlayers(List pls, bool readyStatus, {bool diff = true, bool guesserReady = false}) {
    bool flex = false;
    Widget content = Container(
        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
        alignment: Alignment.center,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Players: ', style: Theme.of(context).textTheme.headline5),
              Container(
                  child: Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    defaultColumnWidth: IntrinsicColumnWidth(),
                    children: List.generate(pls.length, (index) {
                      var p = pls[index];
                      String s=p['name'];
                      bool guesser = p['role']== 'guess';
                      List<Widget> row = [];
                      if (diff) {
                        row.add(guesser ? Icon(Icons.arrow_right) : Text(''));
                      }
                      row.add(Text(p['name'], style: Theme.of(context).textTheme.headline6.apply(color: (diff && guesser ? Colors.amber[900] : Colors.black))));
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

class ChatMsg {
  final String player;
  final String message;

  ChatMsg({@required this.player, @required this.message});
}

class Chatbox extends StatefulWidget {
  final TextEditingController inputCtrl = TextEditingController();
  final void Function(dynamic) sendMsg;
  Queue<ChatMsg> messages = ListQueue(10);

  Chatbox({Key key, @required this.sendMsg}) : super(key: key);

  @override
  ChatboxState createState() => ChatboxState();
  void addMsg(ChatMsg m) {
    messages.addLast(m);
  }
}

class ChatboxState extends State<Chatbox> {
  @override
  void initState() {
    super.initState();
    print('initState chatbox: ');
  }

  void addMsg(ChatMsg m) {
    widget.addMsg(m);
  }

  @override
  Widget build(BuildContext context) {
    var list = widget.messages.toList();
    return Material(
      elevation: 4.0,
      color: Colors.blueGrey[50],
      child: Container(
        height: 200,
        width: 300,
        child: Column(
          children: <Widget>[
            Text('Chat', style: Theme.of(context).textTheme.headline6,),
            Expanded(
              child: Container(
                child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      ChatMsg msg = list[index];
                      return Text(msg.player + ': ' + msg.message);
                    }
                ),
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child:Container(
                    color: Colors.white,
                    child:TextField(
                      controller: widget.inputCtrl,
                      onSubmitted: (content) {
                        widget.sendMsg({
                          'msgtype': 'chat',
                          'text': content
                        });
                        widget.inputCtrl.text = '';
                      },
                    )
                  ),
                ),

              ],
            )
          ],
        ),
      ),
    );
  }

}

void boardGenerator(Clues cw, BuildContext context) async {
  var cont = true;
      cw.sendMsg({'msgtype': 'getword'});
  while (cont) {
      String word = await cw.wordgen.next;
      var result = await showDialog(context: context, child: AlertDialog(
        title: Text('Word Generator'),
        content: 
        actions: <Widget>[
          FlatButton(
            child: const Text('Done'),
            onPressed: () {
              Navigator.of(context).pop<bool>(false);
            },
          ),
          FlatButton(
            child: const Text('New'),
            onPressed: () {
              cw.sendMsg({'msgtype': 'getword'});
              Navigator.of(context).pop<bool>(true);
            },
          ),
        ],
      ));
      print(result);
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
                          child: Text("seven", textAlign: TextAlign.center, style: Theme.of(context).textTheme.headline2)),
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

void wordGenerator(Clues cw, BuildContext context) async {
  var cont = true;
      cw.sendMsg({'msgtype': 'getword'});
  while (cont) {
      String word = await cw.wordgen.next;
      var result = await showDialog(context: context, child: AlertDialog(
        title: Text('Word Generator'),
        content: 
            Card(child: Container(
              padding: EdgeInsets.all(15.0),
              color: Colors.amber[200],
              child: Text(word, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headline2)),
            ),
        actions: <Widget>[
          FlatButton(
            child: const Text('Done'),
            onPressed: () {
              Navigator.of(context).pop<bool>(false);
            },
          ),
          FlatButton(
            child: const Text('New'),
            onPressed: () {
              cw.sendMsg({'msgtype': 'getword'});
              Navigator.of(context).pop<bool>(true);
            },
          ),
        ],
      ));
      print(result);
      cont = (result == true);
  }
}

class SelectClue extends StatefulWidget {
  final String clue;
  final bool initialStatus;
  final String player;
  final int plid;
  final Clues cparent;
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
    print('initState');
  }
  @override
  Widget build(BuildContext context) {
    //var background = show ? (widget.active ? Colors.cyanAccent : Colors.cyan[200]) : Colors.grey[350];
    var background = show ? widget.background : Colors.grey[350];
    print(background);
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
                        style: Theme.of(context).textTheme.headline4
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
