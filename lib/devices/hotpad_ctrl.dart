import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import '../providers/language_provider.dart';
import '../providers/message_provider.dart';
import '../devices/serial_ctrl.dart';
import '../constant/user_style.dart';
import '../devices/config_file_ctrl.dart';

class HotpadCtrl with ChangeNotifier {
  final SerialCtrl serialCtrl = SerialCtrl();
  final MessageProvider messageProvider;
  BuildContext? _context;
  Isolate? _isolate;

  List<bool> _isPU45Enable = List.filled(totalChannel, false);
  List<HeatingStepStatus> _heatingStepStatus = List.filled(totalChannel, HeatingStepStatus.step1);
  List<bool> _isStartBtn = List.filled(totalChannel, false);
  List<bool> _isPreheatingBtn = List.filled(totalChannel, false);
  List<String> _padIDText = List.filled(totalChannel, '');

  HotpadCtrl({
    required this.messageProvider
  });

  void initialize() {
    serialCtrl.initialize();

    _isPU45Enable = ConfigFileCtrl.isPU45EnableList;
    _heatingStepStatus = ConfigFileCtrl.heatingStepStatusList;
    _isStartBtn = ConfigFileCtrl.isStartBtnList;
    _isPreheatingBtn = ConfigFileCtrl.isPreheatingBtnList;
    _padIDText = ConfigFileCtrl.padIDList;
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  void serialStart(){
    serialCtrl.setContext(_context!);
    serialCtrl.loadDeviceFilter().then((_) => serialCtrl.getDevice());

    startIsolate();
  }

  bool getIsPU45Enable(int index){
    return _isPU45Enable[index];
  }

  HeatingStepStatus getHeatingStepStatus(int index){
    return _heatingStepStatus[index];
  }

  bool getIsStartBtn(int index){
    return _isStartBtn[index];
  }

  bool getIsPreheatingBtn(int index){
    return _isPreheatingBtn[index];
  }

  String getPadIDText(int index){
    return _padIDText[index];
  }

  void togglePU45Enable(int index) {
    _isPU45Enable[index] = !_isPU45Enable[index];
    _updateStatus();
  }

  void setPadID(int index, String text) {
    _padIDText[index] = text;
    _updateStatus();
  }

  void startHeating(int index){
    _isStartBtn[index] = true;
    _isPreheatingBtn[index] = false;
    _updateStatus();
  }

  void startPreheating(int index){
    _isStartBtn[index] = false;
    _isPreheatingBtn[index] = true;
    _updateStatus();
  }

  void stopHeating(index){
    _padIDText[index] = '';
    _isStartBtn[index] = false;
    _isPreheatingBtn[index] = false;
    _updateStatus();
  }

  void showInstMessage(String title, String channel, String padMode, String code) {
    if (_context != null) {
      messageProvider.showInstMessageDialog(_context!, title, channel, padMode, code);
    }
  }

  void showAlarmMessage(String channel, String padMode, String code) {
    if (_context != null) {
      messageProvider.alarmMessage(_context!, channel, padMode, code);
    }
  }

  void _updateStatus() async {
    ConfigFileCtrl.isPU45EnableList = _isPU45Enable;
    ConfigFileCtrl.heatingStepStatusList = _heatingStepStatus;
    ConfigFileCtrl.isStartBtnList = _isStartBtn;
    ConfigFileCtrl.isPreheatingBtnList = _isPreheatingBtn;
    ConfigFileCtrl.padIDList = _padIDText;

    await ConfigFileCtrl.setHomePageStatusData();
    notifyListeners();
  }

  String getHeatingStatus(LanguageProvider languageProvider, HeatingStatus status) {
    String tmpStr = '';

    switch (status) {
      case HeatingStatus.stop:
        tmpStr = "Stop";
        break;
      case HeatingStatus.rising1st:
        tmpStr = "1st Rising";
        break;
      case HeatingStatus.holding1st:
        tmpStr = "1st Holding";
        break;
      case HeatingStatus.rising2nd:
        tmpStr = "2nd Rising";
        break;
      case HeatingStatus.holding2nd:
        tmpStr = "2nd Holding";
        break;
      case HeatingStatus.preheatRising:
        tmpStr = "Preheat Rising";
        break;
      case HeatingStatus.preheatHolding:
        tmpStr = "Preheat Holding";
        break;
      case HeatingStatus.error:
        tmpStr = "Pad Error";
        break;
    }

    return languageProvider.getStatusLanguageTransValue(tmpStr);
  }

  void startIsolate() async {
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntry, receivePort.sendPort);
    receivePort.listen((message) {
      if (message == 'sendData') {
        serialCtrl.sendData();
        serialCtrl.checkDataReceived();
      }
    });
  }

  static void _isolateEntry(SendPort sendPort) async {
    Timer.periodic(Duration(seconds: 1), (timer) {
      sendPort.send('sendData');
    });
  }


  void onDataReceived(String data) {
    serialCtrl.noDataRxCount = 0; // Reset counter on data received
    serialCtrl.isError = false;

    // 데이터를 쉼표로 구분하여 리스트에 저장
    List<String> dataList = data.split(',');
    if (dataList.isNotEmpty) {
      String headerStr = dataList[0];
      dataList.removeAt(0);

      if (headerStr == 'STR') {
        serialCtrl.serialPortStatus = SerialPortStatus.rxCplt;
        serialCtrl.rxPackage.setRxPackageData(dataList);
        debugPrint('R>>>[${DateTime.now()}] $dataList');
      } else {
        serialCtrl.serialPortStatus = SerialPortStatus.rxErr;
        debugPrint('### Status : ${serialCtrl.serialPortStatus}');
      }
    }
    serialCtrl.serialPortStatus = SerialPortStatus.rxReady;
  }

  @override
  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    super.dispose();
  }
}