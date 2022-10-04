import 'package:flutter/material.dart' ;
//import 'dart:async';
//import "package:async/async.dart" show StreamQueue;
import 'dart:collection';

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
            Text('Chat', style: Theme.of(context).textTheme.titleLarge,),
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

