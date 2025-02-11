import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
  List<bool> _isStartBtn = List.filled(totalChannel, false);
  List<bool> _isPreheatingBtn = List.filled(totalChannel, false);
  List<String> _padIDText = List.filled(totalChannel, '');
  List<StatusChannel> _statusCh = List.filled(totalChannel, StatusChannel.ready);
  List<HeatingStatus> _heatingStatus = List.filled(totalChannel, HeatingStatus.stop);
  List<HeatingStatus> _oldHeatingStatus = List.filled(totalChannel, HeatingStatus.stop);
  List<double> _remainTime = List.filled(totalChannel, 0);
  List<double> _remainTotalTime = List.filled(totalChannel, -1);

  String _currentTime = '';
  double _totalStorage = 0.0;
  double _usedStorage = 0.0;
  double _storageValue = 0.0;
  static const platform = MethodChannel('internal_storage');

  double get totalStorage => _totalStorage;
  double get usedStorage => _usedStorage;
  double get storageValue => _storageValue;

  void Function(int index, String text)? onPadIDTextChanged;

  HotpadCtrl({
    required this.messageProvider
  });

  Future<void> initialize() async {
    serialCtrl.initialize(onDataReceived);

    _currentTime = DateFormat('yyyy.MM.dd HH:mm:ss').format(DateTime.now());

    _isPU45Enable = ConfigFileCtrl.isPU45EnableList;
    _isStartBtn = ConfigFileCtrl.isStartBtnList;
    _isPreheatingBtn = ConfigFileCtrl.isPreheatingBtnList;
    _statusCh = ConfigFileCtrl.statusChList;
    _heatingStatus = ConfigFileCtrl.heatingStatusList;
    // _oldHeatingStatus = ConfigFileCtrl.heatingStatusList;
    _oldHeatingStatus = List.filled(totalChannel, HeatingStatus.stop);
    _remainTime = ConfigFileCtrl.remainTimeList;
    _remainTotalTime = ConfigFileCtrl.remainTotalTimeList;
    _padIDText = ConfigFileCtrl.padIDList;

    await updateStorageUsage();
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  void serialStart(){
    if(_context != null){
      serialCtrl.setContext(_context!);
      // loadDeviceFilter를 먼저 호출하여 파싱 후 getDevice를 호출
      serialCtrl.loadDeviceFilter().then((_) => serialCtrl.getDevice());
      startIsolate();
    }
  }

  bool getIsPU45Enable(int index){
    if (index < 0 || index >= totalChannel) return false;
    return _isPU45Enable[index];
  }

  StatusChannel getStatusChannel(int index){
    if (index < 0 || index >= totalChannel) return StatusChannel.ready;
    return _statusCh[index];
  }

  HeatingStatus getHeatingStatus(int index){
    if (index < 0 || index >= totalChannel) return HeatingStatus.stop;
    return _heatingStatus[index];
  }

  double getRemainTime(int index){
    if (index < 0 || index >= totalChannel) return -1;
    return _remainTime[index];
  }

  double getRemainTotalTime(int index){
    if (index < 0 || index >= totalChannel) return -1;
    return _remainTotalTime[index];
  }

  bool getIsStartBtn(int index){
    if (index < 0 || index >= totalChannel) return false;
    return _isStartBtn[index];
  }

  bool getIsPreheatingBtn(int index){
    if (index < 0 || index >= totalChannel) return false;
    return _isPreheatingBtn[index];
  }

  String getPadIDText(int index){
    if (index < 0 || index >= totalChannel) return '';
    return _padIDText[index];
  }

  void togglePU45Enable(int index) {
    if (index < 0 || index >= totalChannel) return;
    _isPU45Enable[index] = !_isPU45Enable[index];
    _updateStatus();
    notifyListeners();
  }

  void setPadID(int index, String text) {
    if (index < 0 || index >= totalChannel) return;
    _padIDText[index] = text;
    _updateStatus();
  }

  void startHeating(int index){
    if (index < 0 || index >= totalChannel) return;
    _isStartBtn[index] = true;
    _isPreheatingBtn[index] = false;

    if(_isPU45Enable[index] == false){
      _remainTotalTime[index] = ConfigFileCtrl.pu15HoldTime * 60;
    }
    else{
      _remainTotalTime[index] = (ConfigFileCtrl.pu45Ramp1stTime +
                                ConfigFileCtrl.pu45Hold1stTime +
                                ConfigFileCtrl.pu45Ramp2ndTime +
                                ConfigFileCtrl.pu45Hold2ndTime) * 60;
    }
    _remainTime[index] = _remainTotalTime[index];
    _heatingStatus[index] = HeatingStatus.rising1st;
    _statusCh[index] = StatusChannel.start;
    _updateStatus();
  }

  void startPreheating(int index){
    if (index < 0 || index >= totalChannel) return;
    _isStartBtn[index] = false;
    _isPreheatingBtn[index] = true;
    _remainTotalTime[index] = ConfigFileCtrl.preheatingTime * 60;
    _remainTime[index] = _remainTotalTime[index];
    _heatingStatus[index] = HeatingStatus.preheatRising;
    _statusCh[index] = StatusChannel.start;
    _updateStatus();
  }

  void stopHeating(index){
    if (index < 0 || index >= totalChannel) return;
    if (onPadIDTextChanged != null) {
      onPadIDTextChanged!(index, '');
    }

    _padIDText[index] = '';
    _isStartBtn[index] = false;
    _isPreheatingBtn[index] = false;
    _remainTime[index] = 0;
    _remainTotalTime[index] = -1;
    _heatingStatus[index] = HeatingStatus.stop;
    _oldHeatingStatus[index] = HeatingStatus.stop;
    _statusCh[index] = StatusChannel.ready;

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
    ConfigFileCtrl.isStartBtnList = _isStartBtn;
    ConfigFileCtrl.isPreheatingBtnList = _isPreheatingBtn;
    ConfigFileCtrl.statusChList = _statusCh;
    ConfigFileCtrl.heatingStatusList = _heatingStatus;
    ConfigFileCtrl.remainTimeList = _remainTime;
    ConfigFileCtrl.remainTotalTimeList = _remainTotalTime;
    ConfigFileCtrl.padIDList = _padIDText;

    await ConfigFileCtrl.setHomePageStatusData();
    notifyListeners();
  }

  String getHeatingStatusString(LanguageProvider languageProvider, HeatingStatus status) {
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
      else if (message == 'updateTime') {
        _currentTime = getCurrentTime();
      }
      else if (message == 'decrementRemainTime') {
        _decrementRemainTime();
      }
      else if (message == 'updateStorage') {
        updateStorageUsage();
        _updateStatus();
      }
    });
  }

  static void _isolateEntry(SendPort sendPort) async {
    Timer.periodic(Duration(seconds: 1), (timer) {
      sendPort.send('sendData');
      sendPort.send('updateTime');
      sendPort.send('decrementRemainTime');
    });

    Timer.periodic(Duration(minutes: 1), (timer) {
      sendPort.send('updateStorage');
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

  String getCurrentTime() {
    notifyListeners();

    return DateFormat('yyyy.MM.dd HH:mm:ss').format(DateTime.now());
  }

  String getCurrentTimeValue() {
    return _currentTime;
  }

  Future<void> updateStorageUsage() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getIntStorageInfo');
      _totalStorage = result[0] / (1024 * 1024); // Convert to MB
      _usedStorage = result[1] / (1024 * 1024); // Convert to MB
      _storageValue = _usedStorage / _totalStorage;
      debugPrint("##### Internal Storage Info] $_totalStorage / $_usedStorage(${(_storageValue * 100).toStringAsFixed(1)})");
      notifyListeners();
    } on PlatformException catch (e) {
      debugPrint("Failed to get USB storage info: '${e.message}'.");
    }
  }

  String settingTempSelect(int index)
  {
    String tmpStr = '';

    if(_heatingStatus[index] == HeatingStatus.stop){
      return (tmpStr= '0.0');
    }

    if(_isPU45Enable[index] == false){
      tmpStr =  ConfigFileCtrl.pu15TargetTemp.toStringAsFixed(1);
    }
    else{
      if((_heatingStatus[index] == HeatingStatus.rising1st)
      || (_heatingStatus[index] == HeatingStatus.holding1st)){
        tmpStr =  ConfigFileCtrl.pu45Target1stTemp.toStringAsFixed(1);
      }
      else{
        tmpStr =  ConfigFileCtrl.pu45Target2ndTemp.toStringAsFixed(1);
      }
    }

    return tmpStr;
  }

  void _decrementRemainTime() {
    for (int index = 0; index < totalChannel; index++) {
      if (_statusCh[index] == StatusChannel.start) {
        if (_isPU45Enable[index] == false) { // PU15
          if (_isPreheatingBtn[index] == false) { // heating
            if ((double.tryParse(serialCtrl.rxPackage.rtd[index]) ?? 0.0) >= ConfigFileCtrl.pu15TargetTemp) {
              _remainTime[index] -= 1;
              _heatingStatus[index] = HeatingStatus.holding1st;
            }
          } else { // Preheating
            _remainTime[index] -= 1;
          }
        } else { // PU45
          if (_remainTime[index] > (_remainTotalTime[index] - (ConfigFileCtrl.pu45Ramp1stTime * 60))) {
            _heatingStatus[index] = HeatingStatus.rising1st;
          }
          else if (_remainTime[index] > (_remainTotalTime[index] - (ConfigFileCtrl.pu45Ramp1stTime + ConfigFileCtrl.pu45Hold1stTime) * 60)) {
            _heatingStatus[index] = HeatingStatus.holding1st;
          }
          else if (_remainTime[index] > (_remainTotalTime[index] - (ConfigFileCtrl.pu45Ramp1stTime + ConfigFileCtrl.pu45Hold1stTime + ConfigFileCtrl.pu45Ramp2ndTime) * 60)) {
            _heatingStatus[index] = HeatingStatus.rising2nd;
          }
          else {
            _heatingStatus[index] = HeatingStatus.holding2nd;
          }

          _remainTime[index] -= 1;
        }

        if (_remainTime[index] <= 0) {
          _heatingStatus[index] = HeatingStatus.stop;
        }
      }

      if(_heatingStatus[index] != _oldHeatingStatus[index]){
        String codeStr = '';
        _oldHeatingStatus[index] = _heatingStatus[index];

        switch(_heatingStatus[index]) {
          case HeatingStatus.stop:
            codeStr = 'I0008';
            stopHeating(index);
            break;
          case HeatingStatus.rising1st:
            codeStr = 'I0002';
            break;
          case HeatingStatus.holding1st:
            codeStr = 'I0003';
            break;
          case HeatingStatus.rising2nd:
            codeStr = 'I0004';
            break;
          case HeatingStatus.holding2nd:
            codeStr = 'I0005';
            break;
          case HeatingStatus.preheatRising:
            codeStr = 'I0006';
            break;
          case HeatingStatus.preheatHolding:
            codeStr = 'I0007';
            break;
          case HeatingStatus.error:
            codeStr = 'E0000';
            break;
        }

        showAlarmMessage(
            'CH${(index+1).toString().padLeft(2,'0')}',
            getIsPU45Enable(index) ? 'PU45' : 'PU15',
            codeStr);
      }
    }
  }

  @override
  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    super.dispose();
  }
}