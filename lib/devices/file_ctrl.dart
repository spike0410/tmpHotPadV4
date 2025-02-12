import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constant/user_style.dart';
import '../providers/language_provider.dart';
import '../providers/message_provider.dart';

class FileCtrl {
  static late String? _defaultFolderPath;
  static Database? _alramDatabase;
  static Database? _graphDatabase;
  static Database? _logDatabase;

  /***********************************************************************
   *          폴더를 확인하고 필요한 파일을 생성하는 함수
   ***********************************************************************////
  static Future<String?> checkFolder(MessageProvider messageProvider) async {
    // 저장소 권한을 요청하고, 권한이 승인된 경우 폴더를 생성
    if (await Permission.storage.request().isGranted) {
      DateTime dateTime = DateTime.now();
      String strDatePath = DateFormat('yyyyMM').format(DateTime.now());

      Directory downloadDir = await getDownloadDirectory();

      if (downloadDir.path.isNotEmpty) {
        final Directory newFolder =
            Directory('${downloadDir.path}/$logDefaultFolder/$strDatePath');
        _defaultFolderPath = newFolder.path.toString();

        await _createSubFolder();                           // 서브 폴더를 생성
        await _createAlarmFile(messageProvider, dateTime);  // 알람 파일을 생성
        await _createGraphFile(dateTime);                   // 그래프 파일을 생성
        await _createLogFile(dateTime);                     // 로그 파일을 생성
      }
    } else {
      _defaultFolderPath = null;
      debugPrint('Storage permission denied');
    }

    return _defaultFolderPath;
  }

  /***********************************************************************
   *          서브 폴더를 생성하는 함수
   ***********************************************************************////
  static Future<void> _createSubFolder() async {
    final Directory tmpAlarmPath = Directory('$_defaultFolderPath/$alarmFolder');
    final Directory tmpLogPath = Directory('$_defaultFolderPath/$logFolder');
    final Directory tmpGraphPath = Directory('$_defaultFolderPath/$graphFolder');
    final Directory tmpScreenShotsPath = Directory('$_defaultFolderPath/$screenShotsFolder');

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
  }

  /*****************************************************************************
   *          ScreenShot 함수
   *****************************************************************************////
  static Future<String> screenShotsSave(Uint8List pngBytes) async {
    if (_defaultFolderPath != null) {
      String fileName = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String filePath = '$_defaultFolderPath/$screenShotsFolder/$fileName.png';
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
    String dbPath = '$_defaultFolderPath/$alarmFolder/$dbName';
    bool dbExists = await databaseExists(dbPath);

    _alramDatabase = await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE alarm (
          id INTEGER PRIMARY KEY,
          channel TEXT,
          hotPad TEXT,
          code TEXT,
          descriptions TEXT,
          dateTime TEXT
        )
      ''');
    });

    if (dbExists) {
      List<Map<String, dynamic>> result = await _alramDatabase!.query('alarm');
      messageProvider.loadData(result);
    }
  }

  /*****************************************************************************
   *          알람 메시지를 저장하는 함수
   *****************************************************************************////
  static Future<void> saveAlarmMessage(BuildContext context, List<String> dataList) async {
    if (_alramDatabase != null) {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

      await _alramDatabase!.insert('alarm', {
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
    String dbPath = '$_defaultFolderPath/$graphFolder/$dbName';
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
   *          LogFile을 생성하는 함수
   *****************************************************************************////
  static Future<void> _createLogFile(DateTime now) async {
    String dbName = 'LOG_${DateFormat('yyyyMMdd_HHmmss').format(now)}.db';
    String dbPath = '$_defaultFolderPath/$logFolder/$dbName';
    bool dbExists = await databaseExists(dbPath);

    _logDatabase = await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE graph (
          time TEXT,
          status TEXT,
          rtd TEXT,
          crnt TEXT,
          cmd TEXT,
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
}
