
//import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' ;

class SockWrapper {
  Stream stream;
  void Function(dynamic) sendMsg;
  void Function() dispose;

  SockWrapper({@required this.stream, @required this.sendMsg, this.dispose});
}

