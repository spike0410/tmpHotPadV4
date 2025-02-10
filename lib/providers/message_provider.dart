import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../devices/file_ctrl.dart';

class MessageProvider extends ChangeNotifier {
  Timer? _timer;
  final List<Map<String, String>> _data = [];

  void loadData(List<Map<String, dynamic>> data) {
    for (var item in data) {
      _data.insert(0, {
        'NO.': item['id'].toString(),
        'Channel': item['channel'],
        'HotPad': item['hotPad'],
        'Descriptions': item['code'],
        'Date Time': item['dateTime'],
      });

      debugPrint("## Alarm File : $item");
    }
  }

  void showInstMessageDialog(BuildContext context,
      String title,
      String ch,
      String padMode,
      String message) {
    // 기존 타이머를 취소합니다.
    _timer?.cancel();
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    alarmMessage(context, ch, padMode, message);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        _timer = Timer(Duration(seconds: 3), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
        return AlertDialog(
          backgroundColor: Colors.red.shade200,
          title: Text(
            languageProvider.getMessageTransValue(title),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width - 100,
            child: Text(
              '[$ch] ${languageProvider.getMessageTransValue(message)}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    ).then((_) {
      // 다이얼로그가 프로그래밍적으로 닫힐 때 타이머를 취소합니다.
      _timer?.cancel();
    });
  }

  void alarmMessage(BuildContext context, String ch, String padMode, String desc) {
    final DateTime now = DateTime.now();
    final String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    String strNo = (_data.length + 1).toString();

    List<String> tmpDataList = [strNo, ch, padMode, desc, formattedDate];

    _data.insert(0, {
      'NO.': tmpDataList[0],
      'Channel': tmpDataList[1],
      'HotPad': tmpDataList[2],
      'Descriptions': tmpDataList[3],
      'Date Time': tmpDataList[4],
    });

    FileCtrl.saveAlarmMessage(context, tmpDataList);
    notifyListeners();
  }

  List<Map<String, String>> get data => _data;
}
