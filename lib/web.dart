import 'package:web_socket_channel/html.dart';

import 'base.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';

Future<SockWrapper> getSockWrapper(String address, String port, {bool websock = true}) async {
  String waddr = 'ws://'+ address + ':'+ port;
  print('web gsw: '+waddr);
  final channel = HtmlWebSocketChannel.connect(waddr);
  print('opened');
  return SockWrapper(
      stream: channel.stream.asBroadcastStream(),
      sendMsg: (msg) {
        channel.sink.add(jsonEncode(msg)+'\n');
      },
      dispose: () {
        print("disposing sink");
        channel.sink.close();
      }
    );
}
