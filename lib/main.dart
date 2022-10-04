//import 'dart:async';
//import 'dart:convert';
//import 'dart:typed_data';
//
//import "package:async/async.dart" show StreamQueue;
import 'package:flutter/material.dart' ;
//import 'package:web_socket_channel/io.dart';
import 'package:wordgame/login.dart';
//import 'blank.dart' if (dart.library.io) 'android.dart' if (dart.library.html) 'web.dart';


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


//class WordForm extends StatelessWidget {
//  final TextEditingController _ctrlr = TextEditingController();
//  final void Function(String) submit;
//  final String hint;
//
//  WordForm({Key key, @required this.submit, this.hint = ''}) : super(key: key);
//
//  void doSubmit() {
//    submit(_ctrlr.text);
//    _ctrlr.text = '';
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return Form(
//      key: UniqueKey(),
//      child: Column(
//        children: <Widget>[
//          FractionallySizedBox(
//            child: TextFormField(
//              controller: _ctrlr,
//              decoration: InputDecoration(hintText: 'clue'),
//              autofocus: true,
//              onFieldSubmitted: (s) => doSubmit(),
//            ),
//            widthFactor: 0.5,
//          ),
//          ElevatedButton(child: Text('submit'),onPressed: doSubmit)
//        ],
//      ),
//    );
//  }
//}




