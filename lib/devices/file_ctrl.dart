import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constant/user_style.dart';
import '../providers/language_provider.dart';
import '../providers/message_provider.dart';
import 'package:path/path.dart' as p;

class FileCtrl {
  static late String? _defaultPath;
  static late String? _alarmPath;
  static late String? _graphPath;
  static late String? _logPath;
  static late String? _screenShotPath;
  static Database? _alarmDatabase;
  static Database? _graphDatabase;
  static Database? _logDatabase;

  /***********************************************************************
   *          폴더를 확인하고 필요한 파일을 생성하는 함수
   ***********************************************************************////
  static Future<String?> checkFolder(MessageProvider messageProvider) async {
    // 저장소 권한을 요청하고, 권한이 승인된 경우 폴더를 생성
    if (await Permission.storage.request().isGranted) {
      Directory downloadDir = await getDownloadDirectory();

      if (downloadDir.path.isNotEmpty) {
        final Directory newFolder = Directory('${downloadDir.path}/$logDefaultFolder');
        _defaultPath = newFolder.path.toString();

        await _createSubFolder(messageProvider);        // 서브 폴더를 생성
      }
    } else {
      _defaultPath = null;
      debugPrint('Storage permission denied');
      SystemNavigator.pop();
    }

    return _defaultPath;
  }

  /***********************************************************************
   *          서브 폴더를 생성하는 함수
   ***********************************************************************////
  static Future<void> _createSubFolder(MessageProvider messageProvider) async {
    DateTime dateTime = DateTime.now();
    String strDatePath = DateFormat('yyyyMM').format(DateTime.now());

    _alarmPath = '$_defaultPath/$alarmFolder/$strDatePath';
    _logPath = '$_defaultPath/$logFolder/$strDatePath';
    _graphPath = '$_defaultPath/$graphFolder/$strDatePath';
    _screenShotPath = '$_defaultPath/$screenShotsFolder/$strDatePath';

    final Directory tmpAlarmPath = Directory('$_alarmPath');
    final Directory tmpLogPath = Directory('$_logPath');
    final Directory tmpGraphPath = Directory('$_graphPath');
    final Directory tmpScreenShotsPath = Directory('$_screenShotPath');

    if (!await tmpAlarmPath.exists()) {
      await tmpAlarmPath.create(recursive: true);
      debugPrint('Alarm Folder Create ${tmpAlarmPath.path}');
    }
    if (!await tmpLogPath.exists()) {
      await tmpLogPath.create(recursive: true);
      debugPrint('Log Folder Create ${tmpLogPath.path}');
    }
    if (!await tmpGraphPath.exists()) {
      await tmpGraphPath.create(recursive: true);
      debugPrint('ScreenShots Folder Create ${tmpGraphPath.path}');
    }
    if (!await tmpScreenShotsPath.exists()) {
      await tmpScreenShotsPath.create(recursive: true);
      debugPrint('ScreenShots Folder Create ${tmpScreenShotsPath.path}');
    }

    await _createAlarmFile(messageProvider, dateTime);  // 알람 파일을 생성
    await _createGraphFile(dateTime);                   // 그래프 파일을 생성
    await _createLogFile(dateTime);                     // 로그 파일을 생성
  }

  /*****************************************************************************
   *          ScreenShot 함수
   *****************************************************************************////
  static Future<String> screenShotsSave(Uint8List pngBytes) async {
    if (_defaultPath != null) {
      String fileName = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String filePath = '$_screenShotPath/$fileName.png';
      final File imgFile = File(filePath);

      await imgFile.writeAsBytes(pngBytes);
      debugPrint('Screenshot saved to $filePath');
      return ('$fileName.png');
    } else {
      debugPrint('Log default folder path is not set');
      return '';
    }
  }

  /*****************************************************************************
   *          알람 파일을 생성하는 함수
   *****************************************************************************////
  static Future<void> _createAlarmFile(MessageProvider messageProvider, DateTime now) async {
    String dbName = 'ALARM_${DateFormat('yyyyMMdd').format(now)}.db';
    String dbPath = '$_alarmPath/$dbName';
    bool dbExists = await databaseExists(dbPath);

    _alarmDatabase = await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE alarm (
          id TEXT,
          channel TEXT,
          hotPad TEXT,
          code TEXT,
          descriptions TEXT,
          dateTime TEXT
        )
      ''');
    });

    if (dbExists) {
      List<Map<String, dynamic>> result = await _alarmDatabase!.query('alarm');
      messageProvider.loadData(result);
    }
  }

  /*****************************************************************************
   *          알람 메시지를 저장하는 함수
   *****************************************************************************////
  static Future<void> saveAlarmMessage(BuildContext context, List<String> dataList) async {
    if (_alarmDatabase != null) {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

      await _alarmDatabase!.insert('alarm', {
        'id': dataList[0],
        'channel': dataList[1],
        'hotPad': dataList[2],
        'code': dataList[3],
        'descriptions': languageProvider.getMessageTransValue(dataList[3]),
        'dateTime': dataList[4],
      });
    } else {
      debugPrint('Database is not initialized');
    }
  }

  /*****************************************************************************
   *          Graph File을 생성하는 함수
   *****************************************************************************////
  static Future<void> _createGraphFile(DateTime now) async {
    String dbName = 'GRAPH_${DateFormat('yyyyMMdd_HHmmss').format(now)}.db';
    String dbPath = '$_graphPath/$dbName';
    bool dbExists = await databaseExists(dbPath);

    _graphDatabase = await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE graph (
          time TEXT,
          status TEXT,
          rtd TEXT
        )
      ''');
    });

    if (dbExists) {
      // Load existing graph data if needed
      // List<Map<String, dynamic>> result = await _graphDatabase!.query('graph');
      // Do something with the result
    }
  }

  /*****************************************************************************
   *          Graph Data를 저장하는 함수
   *****************************************************************************////
  static Future<void> saveGraphData(DateTime time, List<String> statusList, List<String> rtdList) async {
    if (_graphDatabase != null) {
      await _graphDatabase!.insert('graph', {
        'time': time.toString(),
        'status': statusList.join(','),
        'rtd': rtdList.join(','),
      });
    } else {
      debugPrint('Database is not initialized');
    }
  }

  /*****************************************************************************
   *          Graph Data 폴더 내 하위(Date) 폴더명 모두를 불러오는 함수
   *****************************************************************************////
  static List<String> searchGraphDate() {
    try {
      final directoryList = Directory('$_defaultPath/$graphFolder')
          .listSync()
          .whereType<Directory>()
          .map((e) => p.basename(e.path))
          .toList();

      directoryList.sort();

      return directoryList.toList();
    }
    catch(e){
      debugPrint("Error Search Graph Date List.");
      return [];
    }
  }

  /*****************************************************************************
   *          Graph Data 폴더 내 선택된 폴더의 모든 파일을 불러오는 함수
   *****************************************************************************////
  static List<String> searchGraphFileList(String subPath) {
    try {
      final fileList = Directory('$_defaultPath/$graphFolder/$subPath')
          .listSync()
          .whereType<File>()
          .map((e) => p.basename(e.path))
          .where((fileName) => fileName.endsWith('.db'))
          .toList();

      fileList.sort();

      return fileList.toList();
    }
    catch(e){
      debugPrint("Error Search Graph File List.");
      return [];
    }
  }

  /*****************************************************************************
   *          LogFile을 생성하는 함수
   *****************************************************************************////
  static Future<void> _createLogFile(DateTime now) async {
    String dbName = 'LOG_${DateFormat('yyyyMMdd_HHmmss').format(now)}.db';
    String dbPath = '$_logPath/$dbName';
    bool dbExists = await databaseExists(dbPath);

    _logDatabase = await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE log (
          time TEXT,
          mode TEXT,
          heatingStatus TEXT,
          rtd TEXT,
          crnt TEXT,
          cmd TEXT,
          ohm TEXT,
          acVtg TEXT,
          dcVtg TEXT,
          dcCrnt TEXT,
          intTemp TEXT
        )
      ''');
    });

    if (dbExists) {
      // Load existing graph data if needed
      // List<Map<String, dynamic>> result = await _graphDatabase!.query('graph');
      // Do something with the result
    }
  }

  /*****************************************************************************
   *          Graph Data를 저장하는 함수
   *****************************************************************************////
   static Future<void> saveLogData(List<String> data) async {
    if (_logDatabase != null) {
      await _logDatabase!.insert('log', {
        'time': data[0],
        'mode': data[1],
        'heatingStatus': data[2],
        'rtd': data[3],
        'crnt': data[4],
        'cmd': data[5],
        'ohm': data[6],
        'acVtg': data[7],
        'dcVtg': data[8],
        'dcCrnt': data[9],
        'intTemp': data[10]
      });
    }
    else {
      debugPrint('Database is not initialized');
    }
  }
}
