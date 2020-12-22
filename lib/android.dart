
import 'base.dart';
import 'dart:io';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';

Future<SockWrapper> getSockWrapper(String address, String port, {bool websock = false}) async {
  if (websock) {
    String waddr = 'ws://'+ address + ':'+ port;
    print('connecting to WS '+ waddr);
    final channel = IOWebSocketChannel.connect(waddr);
    return SockWrapper(
        stream: channel.stream,
        sendMsg: (msg) {
          channel.sink.add(jsonEncode(msg)+'\n');
        },
        dispose: () {
          print('closing sink');
          channel.sink.close();
        }
    );

  }
  Socket sock = await Socket.connect(address, int.parse(port));
  return SockWrapper(
    stream: sock.cast<List<int>>().asBroadcastStream().transform(utf8.decoder).transform(const LineSplitter()),
    sendMsg: (var msg) {
      sock.write(jsonEncode(msg)+'\n');
    },
    dispose: () {
      sock.destroy();
    }
  );
}