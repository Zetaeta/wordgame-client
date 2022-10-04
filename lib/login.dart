import 'package:flutter/material.dart' ;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordgame/chat.dart';
import 'package:wordgame/game.dart';
import 'blank.dart' if (dart.library.io) 'android.dart' if (dart.library.html) 'web.dart';

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
  TextEditingController ipController = TextEditingController(text: 'localhost');
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
                    child: ElevatedButton(
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
                                    Game(
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
