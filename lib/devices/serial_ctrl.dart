import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:usb_serial/transaction.dart';
import 'package:xml/xml.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../devices/hotpad_ctrl.dart';
import '../constant/user_style.dart';
import '../devices/config_file_ctrl.dart';

enum SerialPortStatus {
  none, noFound, noOpen, portOpen, disconnected,
  connect, txBusy, rxReady, rxCplt, rxErr}

/*****************************************************************************
 *          송신 패키지 클래스
 *****************************************************************************////
class TxPackage {
  final String _header = "STR";
  final List<String> _operate = List.filled(10, '0');
  // List<int> _cmd = List.filled(10, 0);
  List<int> _cmd = List.filled(10, 2);      // <---!@# Test
  List<int> _maxTemp = List.filled(10, 0);
  int _operateFAN = 0;
  int _bootmode = 0;
  final String _end = '\r\n';

  void setHTOperate(List<ChannelStatus> operate) {
    String tmpStr = '';
    for(int i = 0; i < totalChannel; i++) {
      switch(operate[i]){
        case ChannelStatus.stop:
          tmpStr = '0';
          break;
        case ChannelStatus.start:
          tmpStr = '1';
          break;
        case ChannelStatus.calTempStart:
          tmpStr = 'A';
          break;
        case ChannelStatus.calACStart:
          tmpStr = 'B';
          break;
        case ChannelStatus.calStart:
          tmpStr = 'C';
          break;
        case ChannelStatus.error:
          tmpStr = '!';
          break;
      }
      _operate[i] = tmpStr;
    }
  }

  void setHTCmd(List<int> cmd) {
    _cmd = cmd;
  }

  void setHTMaxTemp(List<int> maxTemp) {
    _maxTemp = maxTemp;
  }

  void setOperateFAN(int operateFAN) {
    _operateFAN = operateFAN;
  }

  void setBootMode(int bootmode) {
    _bootmode = bootmode;
  }

  /*****************************************************************************
   *          송신 패키지 데이터를 생성하는 함수
   *****************************************************************************////
  String getTxPackageData() {
    String tmpPackage = "$_header,";
    tmpPackage += "${_operate.join(',')},";
    tmpPackage += "${_cmd.map((e) => e.toString().padLeft(3, '0')).join(',')},";
    tmpPackage += "${_maxTemp.map((e) => e.toString().padLeft(4, '0')).join(',')},";
    tmpPackage += "${_operateFAN.toString().padLeft(1, '0')},";
    tmpPackage += "$_bootmode$_end";
    return tmpPackage;
  }
}

/*****************************************************************************
 *          수신 패키지 클래스
 *****************************************************************************////
class RxPackage {
  /// ### RTD Constant ###
  static const double kVRef = 3300.0;                           // mV
  static const double kADCResolution = 4096.0;
  static const double kRTDGain = 11.0;
  static const double kRRtd = 1000.0;                           // ohm
  static const double kRdivH = 1000.0;                          // ohm
  static const double kRdivL = 5100.0;                          // ohm
  /// ### AC Constant ###
  static const double kACSens = 132;                            // mV/A
  static const double kACGain = 0.5;
  static const double kACVf = (300 * 2);                        // diode Vf(mV) x 2
  static const double kN = 85;                                  // 권선비
  /// ### DC Constant ###
  static const double kDCR1 = 10000;                            // DC R1 ohm
  static const double kDCR2 = 2700;                             // DC R2 ohm
  static const double kDCVoltGain = (kDCR1 + kDCR2) / kDCR2;    // R1//R2 전압분배
  static const double kRshunt = 0.003;                          // Rshut ohm
  static const double kDCSens = 200;                            // V/V
  static const double kDCCrntGain = kDCSens * kRshunt;          // V/A
  static const double kSqrt2 = 1.41421356237309;  // sqrt(2)
  static const double kVdiv = (kVRef * kRdivL/(kRdivL+kRdivH));
  static const double kVlsb = (kVRef/kADCResolution);

  DateTime _rxTime = DateTime.now();
  final List<String> _status = List.filled(10, '0');
  final List<String> _rawRTD = List.filled(10, '0');
  final List<String> _rtdTemp = List.filled(10, '0');
  final List<double> _rtdOhm = List.filled(10, 0);
  final List<String> _rawPadCrnt = List.filled(10, '0');
  final List<double> _padCrnt = List.filled(10, 0.0);
  final List<String> _padCmd = List.filled(10, '0.0');
  final List<String> _padCrntOhm = List.filled(10, '0');
  String _acVolt = '';
  double _acVoltValue = 0.0;
  double _acTotalCurrent = 0.0;
  String _dcVolt = '';
  String _dcCrnt = '';
  String _intTemp = '';
  double _acFreqSel = 0;
  int _statusFAN = 0;
  String _fwVer = '0.0.0';

  DateTime get rxTime => _rxTime;
  List<String> get status => _status;
  List<String> get rtdTemp => _rtdTemp;
  List<double> get rtdOhm => _rtdOhm;
  List<double> get padCurrent => _padCrnt;
  List<String> get padCmd => _padCmd;
  List<String> get padOhm => _padCrntOhm;
  String get acVolt => _acVolt;
  double get acVoltValue => _acVoltValue;
  double get acTotalCurrent => _acTotalCurrent;
  String get dcVolt => _dcVolt;
  String get dcCrnt => _dcCrnt;
  String get intTemp => _intTemp;
  int get statusFAN => _statusFAN;
  String get fwVer => _fwVer;

  /*****************************************************************************
   *          수신 패키지 데이터를 설정하는 함수
   *****************************************************************************////
  void setRxPackageData(List<String> data) {
    _rxTime = DateTime.now();

    _acVoltValue = _convertRawACVolt(data[40]);
    _acVolt = _acVoltValue.toStringAsFixed(1);
    _dcVolt = _convertRawDCVolt(data[41]);
    _dcCrnt = _convertRawDCCrnt(data[42]);
    _intTemp = _convertRawIntTemp(data[43]);
    _acFreqSel = (data[44] == '0') ? 120.0 : 100.0;
    _statusFAN = int.tryParse(data[45]) ?? 0;
    _fwVer = data[46];

    for (int i = 0; i < _status.length; i++) {
      _status[i] = data[i];
    }
    for (int i = 0; i < _rtdTemp.length; i++) {
      _rawRTD[i] = data[10 + i];
    }
    for (int i = 0; i < _padCmd.length; i++) {
      _padCmd[i] = data[30 + i];
    }
    for (int i = 0; i < _padCrnt.length; i++) {
      _rawPadCrnt[i] = data[20 + i];
    }

    _padRawRtdToTemp(_rawRTD);
    _padRawCrntToPadData(_rawPadCrnt);
  }
  /*****************************************************************************
   *          AC Voltage로 변환하는 함수
   *****************************************************************************////
  double _convertRawACVolt(String data){
    double tmpVolt = 0.0;

    double? dVadc = double.tryParse(data)! * kVlsb;
    double dVdc = dVadc / kACGain;
    double dVtrans = (dVdc + kACVf) / kSqrt2;
    tmpVolt = dVtrans * kN / 1000;

    return tmpVolt;
  }
  /*****************************************************************************
   *          DC Voltage로 변환하는 함수
   *****************************************************************************////
  String _convertRawDCVolt(String data){
    double tmpVolt = 0.0;

    double? dVadc = double.tryParse(data)! * kVlsb;
    tmpVolt = dVadc * kDCVoltGain / 1000;

    return tmpVolt.toStringAsFixed(1);
  }
  /*****************************************************************************
   *          DC Current로 변환하는 함수
   *****************************************************************************////
  String _convertRawDCCrnt(String data){
    double tmpCrnt = 0.0;

    double? dVadc = double.tryParse(data)! * kVlsb;
    tmpCrnt = dVadc * kDCCrntGain / 1000;

    if(tmpCrnt > 1){
      return tmpCrnt.toStringAsFixed(1);
    }
    else{
      return tmpCrnt.toStringAsFixed(3);
    }
  }
  /*****************************************************************************
   *          패드 RawRTD를 온도로 변환하는 함수
   *****************************************************************************////
  void _padRawRtdToTemp(List<String> list) {
    for (int i = 0; i < list.length; i++) {
      double dVadc = double.tryParse(list[i])! * kVlsb;
      double dVo = dVadc / kRTDGain;
      double dVrtd = dVo + kVdiv;
      _rtdOhm[i] = kRRtd*(kVRef - dVrtd) / dVrtd + ConfigFileCtrl.tempCalData[i];
      _rtdTemp[i] = ohmToTemp(_rtdOhm[i]).toStringAsFixed(1);
    }
  }
  /*****************************************************************************
   *          패드 RawCrnt를 패드 저항과 전류 변환하는 함수
   *****************************************************************************////
  void _padRawCrntToPadData(List<String> list) {
    double dItotal = 0.0;
    for (int i = 0; i < list.length; i++) {
      double dVadc = double.tryParse(list[i])! * kVlsb;
      double dIac = dVadc / kACSens;
      double dIpad = dIac * (double.tryParse(_padCmd[i])! / _acFreqSel);
      int iRpad = 0;
      if(dIac > 0){
        iRpad = (_acVoltValue / dIac).toInt();
      }
      dItotal += dIpad;

      _padCrntOhm[i] = iRpad.toString();
      _padCrnt[i] = dIpad;
    }

   _acTotalCurrent = dItotal * _acVoltValue;
  }
  /*****************************************************************************
   *          Int.Temp로 변환하는 함수
   *****************************************************************************////
  String _convertRawIntTemp(String data){
    double tmpTemp = 0.0;

    double? dVadc = double.tryParse(data)! * kVlsb;

    return '25.4';
  }

  /***********************************************************************
   *          저항 값을 온도로 변환하는 함수
   ***********************************************************************////
  double ohmToTemp(double resistance) {
    const double kR0 = 100.0; // PT100의 0°C에서의 저항값
    const double kA = 3.9083e-3;
    const double kB = -5.775e-7;
    const double kC = -4.183e-12; // 0°C 이하에서만 사용
    double t = 0;

    if (resistance >= kR0) {
      // 0°C 이상
      t = (-kA + sqrt(kA * kA - 4 * kB * (1 - resistance / kR0))) / (2 * kB);
    } else {
      // 0°C 이하
      t = -200.0; // 초기 추정값
      double delta;
      do {
        final double kRt = kR0 * (1 + kA * t + kB * t * t + kC * (t - 100) * t * t);
        final double dRdt = kR0 * (kA + 2 * kB * t + kC * (3 * t * t - 200 * t));
        delta = (resistance - kRt) / dRdt;
        t += delta;
      } while (delta.abs() > 0.0001); // 수렴 조건
    }
    return t;
  }
}

/*****************************************************************************
 *          시리얼 제어 클래스
 *****************************************************************************////
class SerialCtrl{
  UsbPort? _port;
  StreamSubscription<String>? _subscription;
  Transaction<String>? _transaction;
  List<Map<String, String>> deviceFilters = [];
  SerialPortStatus serialPortStatus = SerialPortStatus.none;
  int _noDataRxCount = 0; // Counter for no data received
  bool isError = false;

  late TxPackage txPackage;
  late RxPackage rxPackage;
  BuildContext? _context; // Add this line
  late Function(String) onDataReceivedCallback;

  set noDataRxCount(int val){
    _noDataRxCount = val;
  }

  void initialize(Function(String) onDataReceived) {
    txPackage = TxPackage();
    rxPackage = RxPackage();
    // 데이터 수신 콜백 함수 등록
    onDataReceivedCallback = onDataReceived;
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  /*****************************************************************************
   *          USBtoSerial 장치 검색 함수
   *
   *    - device_filter.xml 파일을 읽고 파싱하는 함수
   *****************************************************************************////
  Future<void> loadDeviceFilter() async {
    final String xmlString = await rootBundle.loadString('asset/xml/device_filter.xml');
    final XmlDocument xmlDocument = XmlDocument.parse(xmlString);
    final Iterable<XmlElement> usbDevices = xmlDocument.findAllElements('usb-device');

    for (var device in usbDevices) {
      final vendorId = device.getAttribute('vendor-id');
      final productId = device.getAttribute('product-id');

      if (vendorId != null) {
        deviceFilters.add({'vendorId': vendorId, 'productId': productId ?? ''});
      }
    }
    debugPrint('Loaded device filters: $deviceFilters');
  }

  /*****************************************************************************
   *          사용 가능한 시리얼 포트를 찾는 함수
   *****************************************************************************////
  Future<void> getDevice() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    for (var device in devices) {
      for (var filter in deviceFilters) {
        if (device.vid.toString() == filter['vendorId'] &&
            (filter['productId']!.isEmpty || device.pid.toString() == filter['productId'])) {
          debugPrint('Matching device found: ${device.deviceName}, Vendor ID: ${device.vid}, Product ID: ${device.pid}');
          serialPortStatus = SerialPortStatus.noFound;
          serialOpen(device);
          return; // 일치하는 장치를 찾으면 더 이상 검색하지 않음
        }
      }
    }

    serialPortStatus = SerialPortStatus.noFound;
    debugPrint('### Status : $serialPortStatus');
  }

  /*****************************************************************************
   *          시리얼 포트를 여는 함수
   *****************************************************************************////
  Future<void> serialOpen(UsbDevice device) async {
    _port = await device.create();
    if (_port == null) {
      serialPortStatus = SerialPortStatus.noOpen;
      debugPrint('### Status : $serialPortStatus');
      return;
    }

    bool openResult = await _port!.open();
    if (!openResult) {
      serialPortStatus = SerialPortStatus.noOpen;
      debugPrint('### Status : $serialPortStatus');
      return;
    }

    await _port!.setDTR(false);
    await _port!.setRTS(false);
    await _port!.setPortParameters(
        115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    _transaction = Transaction.stringTerminated(
        _port!.inputStream as Stream<Uint8List>, Uint8List.fromList([13, 10]));

    // 스트림 리스너에 콜백 함수 설정
    _subscription = _transaction!.stream.listen(onDataReceivedCallback);

    serialPortStatus = SerialPortStatus.connect;
    debugPrint('### Status : $serialPortStatus');
  }

  /*****************************************************************************
   *          시리얼 포트를 닫는 함수
   *****************************************************************************////
  Future<void> serialClose() async {
    await _subscription?.cancel();
    _transaction?.dispose();
    await _port?.close();
    _port = null;
    // _isolate?.kill(priority: Isolate.immediate);
  }

  /*****************************************************************************
   *          데이터 수신 여부를 확인하는 함수
   *****************************************************************************////
  void checkDataReceived() {
    _noDataRxCount++;
    // 20회(약 20초) 데이터 미수신 된 경우 경고 다이얼로그 표시
    if (_noDataRxCount == 20) {
      if (_context != null) {
        String tmpMsg = isError ? 'E0002' : 'E0001';

        Provider.of<HotpadCtrl>(_context!, listen: false)
            .showInstMessage('Error', 'SYS', '-', tmpMsg);
      }

      _noDataRxCount = 0;
      isError = true;
      serialClose().then((_) => getDevice());
    }
  }

  /*****************************************************************************
   *          데이터를 전송하는 함수
   *****************************************************************************////
  void sendData() {
    if ((serialPortStatus == SerialPortStatus.connect || serialPortStatus == SerialPortStatus.rxReady)
        && _port != null) {
      serialPortStatus = SerialPortStatus.txBusy;
      String dataToSend = txPackage.getTxPackageData();

      _port!.write(Uint8List.fromList(dataToSend.codeUnits));
      debugPrint('T<<<[${DateTime.now()}] $dataToSend');
    }
  }


}
