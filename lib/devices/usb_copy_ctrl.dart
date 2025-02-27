import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../constant/user_style.dart';
import '../devices/file_ctrl.dart';
import '../devices/logger.dart';

class UsbCopyCtrl with ChangeNotifier{
  late String _startPath;
  late String _endPath;
  late String _usbPath;
  late int _totalFileCount;
  late int _fileCount;
  double _copyProgressValue = 0;
  Isolate? _isolate;
  bool _isIndicator = false;
  bool _isEjectCheckBox = false;

  late Future<void> Function() _ejectUSB;

  bool get isIndicator => _isIndicator;
  set isIndicator(bool val){
    _isIndicator = val;
    notifyListeners();
  }
  double get copyProgressValue => _copyProgressValue;
  set copyProgressValue(double val){
    _copyProgressValue = val;
    notifyListeners();
  }
  /*****************************************************************************
   *          USB로 데이터를 복사하기 위한 파라미터 전달 및 시작 함수
   *****************************************************************************////
  void startUsbCopy(
      String startPath,
      String endPath,
      String usbPath,
      bool isEjectCheckBox,
      Future<void> Function() ejectUSB,
      ){
    _startPath = startPath;
    _endPath = endPath;
    _usbPath = usbPath;
    _totalFileCount = 0;
    _fileCount = 0;
    _copyProgressValue = 0;
    _isEjectCheckBox = isEjectCheckBox;
    _ejectUSB = ejectUSB;
    startIsolate();
  }
  /*****************************************************************************
   *          File Progress Value 연산 함수
   *****************************************************************************////
  void fileProgressValueOperate(){
    double value;
    if(_totalFileCount <= 0){
      value = 0;
    }
    else{
      if(_fileCount++ <= _totalFileCount) {
        value = _fileCount.toDouble() / _totalFileCount.toDouble();
      }
      else{
        value = 1;
      }
      notifyListeners();
      // Logger.msg('@@@ USB Copy File Count:$_fileCount/$_totalFileCount');
    }
    _copyProgressValue = value;
  }
  /*****************************************************************************
   *          Isolate 설정 및 시작 비동기 함수
   *****************************************************************************////
  void startIsolate() async{
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntry, receivePort.sendPort);

    StreamSubscription? subscription;

    // receivePort로부터 수신된 메시지를 처리하기 위해 listen 함수
    subscription = receivePort.listen((msg) async {
      if(msg == 'startCopy'){
        _isIndicator = true;
        notifyListeners();
        FileCtrl.closeAllDatabase();
        await _copyDataToUsb(_startPath, _endPath, _usbPath).then((_){
          // 데이터 복사가 완료되면 'copyComplete' 메시지를 SendPort로 전송합니다.
          receivePort.sendPort.send('copyComplete');
        });
      }
      else if(msg == 'copyComplete'){
        FileCtrl.reCreateDatabase();
        subscription?.cancel();                       // 더 이상 listen을 하지 않음.
        _isolate?.kill(priority: Isolate.immediate);  // Isolate를 종료함
        _isolate = null;                              // 참조를 해제
        _isIndicator = false;
        notifyListeners();

        if(_isEjectCheckBox){
          await _ejectUSB();
          await Future.delayed(const Duration(seconds: 1));
          _copyProgressValue = 0;
          notifyListeners();
        }
      }
    });
  }
  /*****************************************************************************
   *          Isolate 시작 함수
   *****************************************************************************////
  static void _isolateEntry(SendPort sendPort) async {
    // Isolate가 시작되면 'startCopy' 메시지를 전송
    sendPort.send('startCopy');
  }
  /*****************************************************************************
   *          선택된 항목의 데이터를 USB로 복사를 제어하는 함수
   *****************************************************************************////
  Future<void> _copyDataToUsb(String startPath, String endPath, String usbPath) async{
    List<String> subFolderList = FileCtrl.searchSubFolder();
    List<List<String>> usbFolderList = [];
    List<List<File>> alarmFiles = [];
    List<List<File>> graphFiles = [];
    List<List<File>> logFiles = [];
    List<List<File>> screenShotsFiles = [];

    _totalFileCount = await getFolderFileList(
        subFolderList,
        startPath,
        endPath,
        alarmFiles,
        graphFiles,
        logFiles,
        screenShotsFiles);

    if(_totalFileCount >= 0){
      await _createUSBFolder(subFolderList, startPath, endPath, usbPath, usbFolderList);
      await Future.delayed(const Duration(milliseconds: 200));

      // screenShots Files에 파일을 usbFolderList에 복사
      Logger.msg('### Copy ScreenShot File');
      for (int i = 0; i < screenShotsFiles.length; i++) {
        for (int j = 0; j < screenShotsFiles[i].length; j++) {
          File sourceFile = screenShotsFiles[i][j];
          String usbFolderPath = usbFolderList[i][3]; // screenShotsFolder path
          String destinationPath = '$usbFolderPath/${sourceFile.uri.pathSegments.last}';
          await sourceFile.copy(destinationPath);
          fileProgressValueOperate();
        }
      }
      // Alarm Files에 .db to .csv 변환하여 usbFolderList에 복사
      Logger.msg('### Alarm DB to CSV Conversion');
      await _copyFilesToUsb(alarmFiles, usbFolderList, 0, _convertAlarmDbToCsv);

      // Graph Files에 .db to .csv 변환하여 usbFolderList에 복사
      Logger.msg('### Graph DB to CSV Conversion');
      await _copyFilesToUsb(graphFiles, usbFolderList, 1, _convertGraphDbToCsv);

      // Log Files에 .db to .csv 변환하여 usbFolderList에 복사
      Logger.msg('### Log DB to CSV Conversion');
      await _copyFilesToUsb(logFiles, usbFolderList, 2, _convertLogDbToCsv);
    }
  }
  /*****************************************************************
   *            선택된 폴더의 파일 목록을 가져오는 함수
   *
   *  @ output variable
   *      : alarmFiles, graphFiles, logFiles, screenShotsFiles
   *****************************************************************////
  Future<int> getFolderFileList(
      List<String> subFolderList,
      String startPath,
      String endPath,
      List<List<File>> alarmFiles,
      List<List<File>> graphFiles,
      List<List<File>> logFiles,
      List<List<File>> screenShotsFiles) async{
    String? defaultPath = FileCtrl.defaultPath;
    int total = 0;

    if(defaultPath !=  null){
      int startPathNum = subFolderList.indexOf(startPath);
      int endPathNum = subFolderList.indexOf(endPath);

      for(int i = startPathNum, j = 0; i <= endPathNum; i++, j++){
        final directory = Directory('$defaultPath/${subFolderList[i]}');

        if(await directory.exists()){
          // 하위 디렉토리 목록을 가져옵니다
          final fileDir = directory.listSync(recursive: true);

          // 파일만 필터링하고, .db와 .png 확장자를 가진 파일만 남깁니다.
          final filteredFiles = fileDir.whereType<File>().where((file) {
            String extension = file.path.split('.').last.toLowerCase();
            return extension == 'db' || extension == 'png';
          }).toList();

          int count = filteredFiles.whereType<File>().length;
          total += count;

          // 각 폴더별 파일을 저장할 리스트 초기화
          alarmFiles.add([]);
          graphFiles.add([]);
          logFiles.add([]);
          screenShotsFiles.add([]);

          // 각 폴더별 파일을 저장
          for(var file in filteredFiles){
            if(file.path.contains(alarmFolder)){
              alarmFiles[j].add(file);
            }
            else if(file.path.contains(graphFolder)){
              graphFiles[j].add(file);
            }
            else if(file.path.contains(logFolder)){
              logFiles[j].add(file);
            }
            else if(file.path.contains(screenShotsFolder)){
              screenShotsFiles[j].add(file);
            }
          }
        }
      }
    }
    else{
      return -1;
    }

    return total;
  }
  /*****************************************************************
   *            USB 메모리에 선택된 항목의 폴더를 생성하는 함수
   *
   *  @ output variable
   *      : outFolderList
   *****************************************************************////
  Future<void> _createUSBFolder(
      List<String> subFolderList,
      String startPath,
      String endPath,
      String usbPath,
      List<List<String>> outFolderList
      ) async{
    int startPathNum = subFolderList.indexOf(startPath);
    int endPathNum = subFolderList.indexOf(endPath);
    String tmpDate = DateFormat('yyyyMMdd').format(DateTime.now());
    final usbDirectory = Directory('$usbPath/${logDefaultFolder}_$tmpDate');

    await deleteDirectoryRecursive(usbDirectory);

    await usbDirectory.create(recursive: true);

    for(int i = startPathNum, j = 0; i <= endPathNum; i++, j++){
      final alarmDir = Directory('${usbDirectory.path}/${subFolderList[i]}/$alarmFolder');
      final graphDir = Directory('${usbDirectory.path}/${subFolderList[i]}/$graphFolder');
      final logDir = Directory('${usbDirectory.path}/${subFolderList[i]}/$logFolder');
      final screenShotsDir = Directory('${usbDirectory.path}/${subFolderList[i]}/$screenShotsFolder');

      await alarmDir.create(recursive: true);
      await graphDir.create(recursive: true);
      await logDir.create(recursive: true);
      await screenShotsDir.create(recursive: true);

      outFolderList.add([]);
      outFolderList[j].add(alarmDir.path);
      outFolderList[j].add(graphDir.path);
      outFolderList[j].add(logDir.path);
      outFolderList[j].add(screenShotsDir.path);
    }

    Logger.msg('### Create USB Folder List');
    for (var folderList in outFolderList) {
      for(var list in folderList){
        Logger.msg(' -> ${list.toString()}');
      }
    }
  }
  /*****************************************************************************
   *          USB메모리 내 동일한 폴더 삭제 함수
   *****************************************************************************////
  Future<void> deleteDirectoryRecursive(Directory dir) async {
    if (await dir.exists()) {
      try {
        final contents = dir.list(recursive: false);
        await for (var entity in contents) {
          try {
            if (entity is File) {
              await entity.delete();
            } else if (entity is Directory) {
              await deleteDirectoryRecursive(entity);
            }
          } catch (e) {
            Logger.msg("$e", tag: "ERROR");
          }
        }
        await dir.delete();
        Logger.msg('Delete USB Directory : ${dir.path}');
      } catch (e) {
        Logger.msg("$e", tag: "ERROR");
      }
    }
  }
  /*****************************************************************************
   *          DB를 CSV로 변환된 파일을 USB에 저장하는 함수
   *****************************************************************************////
  Future<void> _copyFilesToUsb(
      List<List<File>> fileGroups,
      List<List<String>> usbFolderList,
      int usbFolderIndex,
      Future<String> Function(File) convertToCsv) async {

    String? downloadDirPath = FileCtrl.defaultPath;
    for (int i = 0; i < fileGroups.length; i++) {
      for (int j = 0; j < fileGroups[i].length; j++) {
        File dbFile = fileGroups[i][j];
        String csvPath = await convertToCsv(dbFile);
        await Future.delayed(const Duration(milliseconds: 100));
        String usbFolderPath = usbFolderList[i][usbFolderIndex];
        File source = File(csvPath);

        try{
          await source.copy('$usbFolderPath/${source.uri.pathSegments.last}');
        }
        catch(e) {
          Logger.msg("$e", tag: "ERROR");
        }
        finally{
          fileProgressValueOperate();
          double fileSize = await source.length() / 1024.0;
          Logger.msg("@@@ Copy CSV[$_fileCount/$_totalFileCount]: ${source.path.substring(downloadDirPath!.length)}(${fileSize.toStringAsFixed(3)} KByte)");
          await source.delete();
        }
      }
    }
  }
  /*****************************************************************************
   *          Alarm DB를 CSV 파일로 변환하는 함수
   *****************************************************************************////
  Future<String> _convertAlarmDbToCsv(File dbFile) async {
    String csvHeader = 'ID,Channel,HotPAD,Code,Descriptions,DateTime';
    List<String> columns = ['id', 'channel', 'hotPad', 'code', 'descriptions', 'dateTime'];
    return _convertDbToCsv(dbFile, 'alarm', columns, csvHeader);
  }
  /*****************************************************************************
   *          Graph DB를 CSV 파일로 변환하는 함수
   *****************************************************************************////
  Future<String> _convertGraphDbToCsv(File dbFile) async {
    String csvHeader = 'Time,Status01,Status02,Status03,Status04,Status05,Status06,Status07,Status08,Status09,Status10,'
        'Temp01,Temp02,Temp03,Temp04,Temp05,Temp06,Temp07,Temp08,Temp09,Temp10';
    List<String> columns = ['time', 'status', 'rtd'];
    return _convertDbToCsv(dbFile, 'graph', columns, csvHeader);
  }
  /*****************************************************************************
   *          Log DB를 CSV 파일로 변환하는 함수
   *****************************************************************************////
  Future<String> _convertLogDbToCsv(File dbFile) async {
    String csvHeader = 'Time,Live,'
        'Mode01,Mode02,Mode03,Mode04,Mode05,Mode06,Mode07,Mode08,Mode09,Mode10,'
        'Status01,Status02,Status03,Status04,Status05,Status06,Status07,Status08,Status09,Status10,'
        'Temp01,Temp02,Temp03,Temp04,Temp05,Temp06,Temp07,Temp08,Temp09,Temp10,'
        'Crnt01,Crnt02,Crnt03,Crnt04,Crnt05,Crnt06,Crnt07,Crnt08,Crnt09,Crnt10,'
        'Cmd01,Cmd02,Cmd03,Cmd04,Cmd05,Cmd06,Cmd07,Cmd08,Cmd09,Cmd10,'
        'Ohm01,Ohm02,Ohm03,Ohm04,Ohm05,Ohm06,Ohm07,Ohm08,Ohm09,Ohm10,'
        'ACVtg,DCVtg,DCCrnt,IntTemp';
    List<String> columns = ['time', 'live', 'mode', 'heatingStatus', 'rtd', 'crnt', 'cmd', 'ohm', 'acVtg', 'dcVtg', 'dcCrnt', 'intTemp'];
    return _convertDbToCsv(dbFile, 'log', columns, csvHeader);
  }
  /*****************************************************************************
   *          DB를 CSV 변환하는 함수
   *****************************************************************************////
  Future<String> _convertDbToCsv(File dbFile, String tableName, List<String> columns, String csvHeader) async {
    String csvData = '\uFEFF$csvHeader\n';

    if (!await dbFile.exists()) {
      return '';
    }

    String? downloadDirPath = FileCtrl.defaultPath;
    Database db = await openReadOnlyDatabase(dbFile.path);
    await Future.delayed(const Duration(milliseconds: 100));
    File csvFile = File('${dbFile.path.split('.').first}.csv');
    IOSink sink = csvFile.openWrite(mode: FileMode.write);
    sink.write(csvData);

    const int chunkSize = 100; // 한 번에 읽을 행 개수
    int offset = 0;

    try {
      while (true) {
        List<Map<String, dynamic>> result = await db.query(
          tableName,
          columns: columns,
          limit: chunkSize,
          offset: offset,
        );

        if (result.isEmpty) {
          if(offset == 0){
            Logger.msg("@@@ Empty Load DB path: ${dbFile.path.substring(downloadDirPath!.length)}");
          }
          await Future.delayed(const Duration(microseconds: 100));
          break;
        }

        for (Map<String, dynamic> row in result) {
          List<String> values = columns.map((col) => '${row[col]}').toList();
          sink.writeln(values.join(','));
        }

        offset += chunkSize; // 다음 청크로 이동
      }
    } catch (e) {
      Logger.msg("$e", tag: "ERROR");
    } finally {
      await db.close();
      await sink.flush();
      await sink.close();
    }

    return csvFile.path;
  }

    @override
  void dispose() {
    // TODO: implement dispose
    _isolate?.kill(priority: Isolate.immediate);
    super.dispose();
  }
}