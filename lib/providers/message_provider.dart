import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../devices/file_ctrl.dart';
import '../devices/logger.dart';

class MessageProvider extends ChangeNotifier {
  Timer? _timer;
  // 메시지 데이터를 저장하는 리스트
  final List<Map<String, String>> _data = [];

  /***********************************************************************
   *          데이터를 불러와서 _data 리스트에 추가하는 함수
   ***********************************************************************////
  void loadData(List<Map<String, dynamic>> data) {
    if(_data.isNotEmpty){
      _data.clear();
    }

    for (var item in data) {
      _data.insert(0, {
        'NO.': item['id'].toString(),
        'Channel': item['channel'],
        'HotPad': item['hotPad'],
        'Descriptions': item['code'],
        'Date Time': item['dateTime'],
      });

      Logger.msg("### Alarm File : $item");
    }
  }
  /***********************************************************************
   *          인스턴트 메시지 다이얼로그를 표시하는 함수
   ***********************************************************************////
  void showInstMessageDialog(BuildContext context,
      String title,
      String ch,
      String padMode,
      String message,
      int duration) {
    // 기존 타이머를 취소합니다.
    _timer?.cancel();
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    alarmMessage(context, ch, padMode, message);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        _timer = Timer(Duration(seconds: duration), () {
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
  /***********************************************************************
   *          알람 메시지를 처리하고 저장하는 함수
   ***********************************************************************////
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

  // 메시지 데이터를 반환하는 getter
  List<Map<String, String>> get data => _data;
}
