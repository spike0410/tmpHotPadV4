import 'dart:async';
import 'dart:isolate';
import 'package:shared_preferences/shared_preferences.dart';

class Logger {
  static const String _isStartLoggerKey = 'isStartLogger';
  static Isolate? _isolate;
  static SendPort? _sendPort;
  static ReceivePort? _receivePort;

  static Future<void> saveStartLoggerFlag(bool value) async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isStartLoggerKey, value);
  }

  static Future<bool> loadStartLoggerFlag() async{
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isStartLoggerKey) ?? false;
  }

  static Future<void> start() async {
    bool isStartLogger = await loadStartLoggerFlag();

    if(!isStartLogger) return;
    if (_isolate != null) {
      // 이미 초기화된 경우, 기존 isolate를 종료합니다.
      dispose();
    }
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntry, _receivePort!.sendPort);
    _sendPort = await _receivePort!.first;
  }

  static void msg(dynamic message, {String tag = 'MYAPP'}) {
    if(_sendPort != null) {
      final stackTrace = StackTrace.current;
      final logDetails = _getLogDetails(stackTrace);

      _sendPort!.send('$tag] ${logDetails['function']!.padRight(30)} (${logDetails['line']!.padLeft(4, '0')}): $message');
    }
  }

  static Map<String, String> _getLogDetails(StackTrace stackTrace) {
    final stackTraceString = stackTrace.toString().split('\n')[1];
    final regex = RegExp(r'^\s*#\d+\s+(.+?)\((.+?):(\d+):(\d+)\)');
    final matches = regex.firstMatch(stackTraceString);

    if (matches != null) {
      final function = matches.group(1)?.trim() ?? 'Unknown';
      final file = matches.group(2) ?? 'Unknown';
      final line = matches.group(3) ?? 'Unknown';
      return {
        'function': function,
        'file': file,
        'line': line,
      };
    }

    return {
      'function': 'Unknown',
      'file': 'Unknown',
      'line': 'Unknown',
    };
  }

  static void _isolateEntry(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      print(message);
    });
  }

  static void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    _isolate = null;
    _sendPort = null;
    _receivePort= null;
  }
}