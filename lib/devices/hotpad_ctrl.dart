import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotpadapp_v4/devices/file_ctrl.dart';
import 'package:intl/intl.dart';
import '../providers/language_provider.dart';
import '../providers/message_provider.dart';
import '../devices/serial_ctrl.dart';
import '../constant/user_style.dart';
import '../devices/config_file_ctrl.dart';

class HotpadCtrl with ChangeNotifier{
  final SerialCtrl serialCtrl = SerialCtrl();
  final MessageProvider messageProvider;
  BuildContext? _context;
  Isolate? _isolate;

  List<bool> _isPU45Enable = List.filled(totalChannel, false);
  bool _isGraphLive = true;
  final List<String> _sPU45Enable = List.filled(totalChannel, '0');
  List<bool> _isStartBtn = List.filled(totalChannel, false);
  List<bool> _isPreheatingBtn = List.filled(totalChannel, false);
  List<String> _padIDText = List.filled(totalChannel, '');
  List<ChannelStatus> _chStatus = List.filled(totalChannel, ChannelStatus.stop);
  List<HeatingStatus> _heatingStatus = List.filled(totalChannel, HeatingStatus.stop);
  List<HeatingStatus> _oldHeatingStatus = List.filled(totalChannel, HeatingStatus.stop);
  List<double> _remainTime = List.filled(totalChannel, 0);
  List<double> _remainTotalTime = List.filled(totalChannel, -1);
  List<List<String>> _logDataList = [];

  String _currentTime = '';
  double _totalStorage = 0.0;
  double _usedStorage = 0.0;
  double _storageProgressValue = 0.0;
  static const platform = MethodChannel('internal_storage');

  set isGraphLive(bool val) => _isGraphLive = val;
  double get totalStorage => _totalStorage;
  double get usedStorage => _usedStorage;
  double get storageProgressValue => _storageProgressValue;

  void Function(int index, String text)? onPadIDTextChanged;

  HotpadCtrl({
    required this.messageProvider
  });

  /*****************************************************************************
   *          초기화 함수
   *
   *    - HotPad GUI의 사용되는 데이터 초기화
   *****************************************************************************////
  Future<void> initialize() async {
    serialCtrl.initialize(onDataReceived);

    _currentTime = DateFormat('yyyy.MM.dd HH:mm:ss').format(DateTime.now());

    _isPU45Enable = ConfigFileCtrl.isPU45EnableList;
    _isStartBtn = ConfigFileCtrl.isStartBtnList;
    _isPreheatingBtn = ConfigFileCtrl.isPreheatingBtnList;
    _chStatus = ConfigFileCtrl.chStatusList;
    _heatingStatus = ConfigFileCtrl.heatingStatusList;
    _oldHeatingStatus = List.filled(totalChannel, HeatingStatus.stop);
    _remainTime = ConfigFileCtrl.remainTimeList;
    _remainTotalTime = ConfigFileCtrl.remainTotalTimeList;
    _padIDText = ConfigFileCtrl.padIDList;

    _logDataList = [];

    for(int i = 0; i < _isPU45Enable.length; i++) {
      _sPU45Enable[i] = (_isPU45Enable[i] == true ? "PU45" : "PU15");
    }

    await updateStorageUsage();
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  /*****************************************************************************
   *          시리얼 통신 시작 함수
   *****************************************************************************////
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

  ChannelStatus getChannelStatus(int index){
    if (index < 0 || index >= totalChannel) return ChannelStatus.stop;
    return _chStatus[index];
  }

  HeatingStatus getHeatingStatus(int index){
    if (index < 0 || index >= totalChannel) return HeatingStatus.stop;
    return _heatingStatus[index];
  }

  List<HeatingStatus> get getHeatingStatusList => _heatingStatus;

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

    if(_isPU45Enable[index] == true){
      _sPU45Enable[index] = "PU45";
    }
    else{
      _sPU45Enable[index] = "PU15";
    }

    _updateStatus();
    notifyListeners();
  }

  void setPadID(int index, String text) {
    if (index < 0 || index >= totalChannel) return;
    _padIDText[index] = text;
    _updateStatus();
  }

  /*****************************************************************************
   *          히팅 시작 함수
   *****************************************************************************////
  void startHeating(int index){
    if (index < 0 || index >= totalChannel) return;
    _isStartBtn[index] = true;
    _isPreheatingBtn[index] = false;

    // PU15와 PU45 설정에 따른 RemainTime 설정
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
    _chStatus[index] = ChannelStatus.start;
    _updateStatus();
  }

  /*****************************************************************************
   *          예열 시작 함수
   *****************************************************************************////
  void startPreheating(int index){
    if (index < 0 || index >= totalChannel) return;
    _isStartBtn[index] = false;
    _isPreheatingBtn[index] = true;
    // Preheating RemainTime 설정
    _remainTotalTime[index] = ConfigFileCtrl.preheatingTime * 60;
    _remainTime[index] = _remainTotalTime[index];
    _heatingStatus[index] = HeatingStatus.preheatRising;
    _chStatus[index] = ChannelStatus.start;
    _updateStatus();
  }

  /*****************************************************************************
   *          히팅 종료 함수
   *****************************************************************************////
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
    _chStatus[index] = ChannelStatus.stop;

    _updateStatus();
  }

  /*****************************************************************************
   *          인스턴트 메시지 다이얼로그 표시 함수
   *****************************************************************************////
  void showInstMessage(String title, String channel, String padMode, String code) {
    if (_context != null) {
      messageProvider.showInstMessageDialog(_context!, title, channel, padMode, code);
    }
  }

  /*****************************************************************************
   *          알람 메시지 표시 함수
   *****************************************************************************////
  void showAlarmMessage(String channel, String padMode, String code) {
    if (_context != null) {
      messageProvider.alarmMessage(_context!, channel, padMode, code);
    }
  }

  /*****************************************************************************
   *          상태 업데이트 함수
   *****************************************************************************////
  void _updateStatus() async {
    // 변경된 설정 값을 ConfigFileCtrl에 저장 후 SharedPreferences에 저장
    ConfigFileCtrl.isPU45EnableList = _isPU45Enable;
    ConfigFileCtrl.isStartBtnList = _isStartBtn;
    ConfigFileCtrl.isPreheatingBtnList = _isPreheatingBtn;
    ConfigFileCtrl.chStatusList = _chStatus;
    ConfigFileCtrl.heatingStatusList = _heatingStatus;
    ConfigFileCtrl.remainTimeList = _remainTime;
    ConfigFileCtrl.remainTotalTimeList = _remainTotalTime;
    ConfigFileCtrl.padIDList = _padIDText;

    await ConfigFileCtrl.setHomePageStatusData();
    notifyListeners();
  }

  /*****************************************************************************
   *          히팅 상태 문자열 반환 함수
   *****************************************************************************////
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

  /*****************************************************************************
   *          Isolate 시작 함수
   *****************************************************************************////
  void startIsolate() async {
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntry, receivePort.sendPort);  // <---!@# Test
    receivePort.listen((message) {
      if (message == 'sendData') {
        serialCtrl.txPackage.setHTOperate(_chStatus);
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

  /*****************************************************************************
   *          데이터 수신 시 호출되는 함수
   *****************************************************************************////
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
        _saveLogData();

        debugPrint('R>>>[${serialCtrl.rxPackage.rxTime}] $dataList');
      }
      else {
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

  /*****************************************************************************
   *          스토리지 사용량 업데이트 함수
   *****************************************************************************////
  Future<void> updateStorageUsage() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getIntStorageInfo');
      _totalStorage = result[0] / (1024 * 1024); // Convert to MB
      _usedStorage = result[1] / (1024 * 1024); // Convert to MB
      _storageProgressValue = _usedStorage / _totalStorage;
      debugPrint("##### Internal Storage Info] $_totalStorage / $_usedStorage(${(_storageProgressValue * 100).toStringAsFixed(1)})");
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

  /*****************************************************************************
   *          남은 시간 감소 함수
   *
   *    - Heating/Preheating Button 동작시 RemainTime 제어
   *****************************************************************************////
  void _decrementRemainTime() {
    for (int index = 0; index < totalChannel; index++) {
      if (_chStatus[index] == ChannelStatus.start) {
        if (_isPU45Enable[index] == false) { // PU15
          if (_isPreheatingBtn[index] == false) { // heating
            if ((double.tryParse(serialCtrl.rxPackage.rtd[index]) ?? 0.0) >= ConfigFileCtrl.pu15TargetTemp) {
              _remainTime[index] -= 1;
              _heatingStatus[index] = HeatingStatus.holding1st;
            }
          }
          else { // Preheating
            _remainTime[index] -= 1;
          }
        }
        else { // PU45
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

      // HeatingStatus 변경에 따라 메세지 출력
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

  /*****************************************************************************
   *          Log Data를 SQLite 형식으로 파일 저장
   *
   *    - rxPackage.setRxPackageData() 함수 사용 후 파일을 저장할 것
   *    - 데이터를 List에 10개 저장 후 파일로 저장
   *****************************************************************************////
  void _saveLogData(){
    if(_logDataList.length == 10){
      for(int i = 0; i < _logDataList.length; i++) {
        FileCtrl.saveLogData(_logDataList[i]);
      }
      _logDataList.clear();
    }
    _logDataList.add(_getRxLogData());
  }

  List<String> _getRxLogData(){
    List<String> tmpLog = List.filled(12, '0');

    tmpLog[0] = serialCtrl.rxPackage.rxTime.toString();
    tmpLog[1] = _isGraphLive.toString();
    tmpLog[2] = _sPU45Enable.join(',');
    tmpLog[3] = _heatingStatus.toList().join(',').replaceAll('HeatingStatus.', '');
    tmpLog[4] = serialCtrl.rxPackage.rtd.join(',');
    tmpLog[5] = serialCtrl.rxPackage.padCurrent.join(',');
    tmpLog[6] = serialCtrl.rxPackage.padCmd.join(',');
    tmpLog[7] = serialCtrl.rxPackage.padOhm.join(',');
    tmpLog[8] = serialCtrl.rxPackage.acVolt;
    tmpLog[9] = serialCtrl.rxPackage.dcVolt;
    tmpLog[10] = serialCtrl.rxPackage.dcCrnt;
    tmpLog[11] = serialCtrl.rxPackage.intTemp;

    return tmpLog;
  }

  @override
  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    super.dispose();
  }

}