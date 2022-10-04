
//import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' ;

//A wrapper for platform-dependent IO implementation
class SockWrapper {
  //incoming message stream to listen on
  Stream stream;
  //sends a message after json encoding
  void Function(dynamic) sendMsg;
  //clean up
  void Function() dispose;

  SockWrapper({@required this.stream, @required this.sendMsg, this.dispose});
}

