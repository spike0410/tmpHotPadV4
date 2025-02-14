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
  static late String _nowGraphFileName;

  static String get nowGraphFileName => _nowGraphFileName;

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
    }
    else {
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

    _nowGraphFileName = dbName;
    _graphDatabase = await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE graph (
          time TEXT,
          status TEXT,
          rtd TEXT
        )
      ''');
    });
  }

  /*****************************************************************************
   *          Graph Data를 저장하는 함수
   *****************************************************************************////
  static Future<void> saveGraphData(DateTime time, List<HeatingStatus> status,List<String> rtdList) async {
    if (_graphDatabase != null) {
      await _graphDatabase!.insert('graph', {
        'time': time.toString(),
        'status': status.toList().join(',').replaceAll('HeatingStatus.', ''),
        'rtd': rtdList.join(','),
      });
    } else {
      debugPrint('Database is not initialized');
    }
  }

  /*****************************************************************************
   *          Graph Data를 불러오는 함수
   *****************************************************************************////
  static Future<List<Map<String, dynamic>>> loadGraphData(String subPath, String fileName) async {
    String dbPath = '$_defaultPath/$graphFolder/$subPath/$fileName';
    bool dbExists = await databaseExists(dbPath);
    List<Map<String, dynamic>> result = [];

    if(dbExists){
      final database = await openDatabase(dbPath);
      result = await database.query('graph');

      await database.close();
    }

    return result;
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
   *          Log File을 생성하는 함수
   *****************************************************************************////
  static Future<void> _createLogFile(DateTime now) async {
    String dbName = 'LOG_${DateFormat('yyyyMMdd_HHmmss').format(now)}.db';
    String dbPath = '$_logPath/$dbName';

    _logDatabase = await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE log (
          time TEXT,
          live TEXT,
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
  }

  /*****************************************************************************
   *          Log Data를 저장하는 함수
   *****************************************************************************////
   static Future<void> saveLogData(List<String> data) async {
    if (_logDatabase != null) {
      await _logDatabase!.insert('log', {
        'time': data[0],
        'live': data[1],
        'mode': data[2],
        'heatingStatus': data[3],
        'rtd': data[4],
        'crnt': data[5],
        'cmd': data[6],
        'ohm': data[7],
        'acVtg': data[8],
        'dcVtg': data[9],
        'dcCrnt': data[10],
        'intTemp': data[11]
      });
    }
    else {
      debugPrint('Database is not initialized');
    }
  }

  /*****************************************************************************
   *          폴더 내 하위(Date) 폴더명 모두를 불러오는 함수
   *****************************************************************************////
  static List<String> searchSubFolder(String subFolder) {
    try {
      final directoryList = Directory('$_defaultPath/$subFolder')
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
}
