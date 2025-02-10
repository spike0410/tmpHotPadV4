import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hotpadapp_v4/devices/hotpad_ctrl.dart';
import 'package:provider/provider.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:usb_serial/transaction.dart';
import 'package:xml/xml.dart';
import 'package:flutter/services.dart' show rootBundle;

enum SerialPortStatus {
  none,
  noFound,
  noOpen,
  portOpen,
  disconnected,
  connect,
  txBusy,
  rxReady,
  rxCplt,
  rxErr,
}

class TxPackage {
  final String _header = "STR";
  List<String> _operate = List.filled(10, '0');
  List<int> _cmd = List.filled(10, 0);
  List<int> _maxTemp = List.filled(10, 0);
  int _operateFAN = 0;
  int _bootmode = 0;
  final String _end = '\r\n';

  void setHTOperate(List<String> operate) {
    _operate = operate;
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

class RxPackage {
  DateTime _rxTime = DateTime.now();
  final List<String> _status = List.filled(10, '0');
  final List<String> _rtd = List.filled(10, '0');
  final List<String> _padCrnt = List.filled(10, '0.0');
  final List<String> _padCmd = List.filled(10, '0.0');
  final List<String> _padCrntOhm = List.filled(10, '0');
  String _acVolt = '';
  String _dcVolt = '';
  String _dcCrnt = '';
  String _intTemp = '';
  int _acFreqSel = 0;
  int _statusFAN = 0;
  String _fwVer = '0.0.0';

  DateTime get rxTime => _rxTime;
  List<String> get status => _status;
  List<String> get rtd => _rtd;
  List<String> get padCurrent => _padCrnt;
  List<String> get padCmd => _padCmd;
  List<String> get padOhm => _padCrntOhm;
  String get acVolt => _acVolt;
  String get dcVolt => _dcVolt;
  String get dcCrnt => _dcCrnt;
  String get intTemp => _intTemp;
  int get acFreqSel => _acFreqSel;
  int get statusFAN => _statusFAN;
  String get fwVer => _fwVer;

  void setRxPackageData(List<String> data) {
    _rxTime = DateTime.now();
    for (int i = 0; i < _status.length; i++) {
      _status[i] = data[i];
    }

    for (int i = 0; i < _rtd.length; i++) {
      _rtd[i] = data[10 + i];
    }

    for (int i = 0; i < _padCrnt.length; i++) {
      _padCrnt[i] = data[20 + i];
    }

    for (int i = 0; i < _padCmd.length; i++) {
      _padCmd[i] = data[30 + i];
    }

    _acVolt = data[40];
    _dcVolt = data[41];
    _dcCrnt = data[42];
    _intTemp = data[43];
    _acFreqSel = int.tryParse(data[44]) ?? 0;
    _statusFAN = int.tryParse(data[45]) ?? 0;
    _fwVer = data[46];
    _padCurrentToOhm(_padCrnt);

    // notifyListeners();
  }

  void _padCurrentToOhm(List<String> list) {
    for (int i = 0; i < list.length; i++) {
      double tmpPadOhm = 0;
      double dCurrentVal = double.tryParse(list[i]) ?? 0.0;
      tmpPadOhm = dCurrentVal * 10;
      _padCrntOhm[i] = tmpPadOhm.toStringAsFixed(0);
    }
  }
}

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

  set noDataRxCount(int val){
    _noDataRxCount = val;
  }

  // 초기화 함수
  void initialize() {
    txPackage = TxPackage();
    rxPackage = RxPackage();

    // // loadDeviceFilter를 먼저 호출하여 파싱 후 getDevice를 호출
    // loadDeviceFilter().then((_) => getDevice());
  }

  // Add this method to set the context
  void setContext(BuildContext context) {
    _context = context;
  }

  // device_filter.xml 파일을 읽고 파싱하는 함수
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

  // 사용 가능한 시리얼 포트를 찾는 함수
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

  // 시리얼 포트를 여는 함수
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
    // _subscription = _transaction!.stream.listen(onDataReceived);
    _subscription = _transaction!.stream.listen((data) {
      Provider.of<HotpadCtrl>(_context!, listen: false).onDataReceived(data);
    });

    serialPortStatus = SerialPortStatus.connect;
    debugPrint('### Status : $serialPortStatus');
  }

  // 시리얼 포트를 닫는 함수
  Future<void> serialClose() async {
    await _subscription?.cancel();
    _transaction?.dispose();
    await _port?.close();
    _port = null;
    // _isolate?.kill(priority: Isolate.immediate);
  }

  // 데이터 수신 여부를 확인하는 함수
  void checkDataReceived() {
    _noDataRxCount++;
    if (_noDataRxCount == 20) {
      // Show warning dialog
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

  // 데이터를 전송하는 함수
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
