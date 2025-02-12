import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../constant/user_style.dart';
import '../devices/config_file_ctrl.dart';

class LanguageProvider with ChangeNotifier {
  Map<String, String> _localizedStrings = {};
  Map<String, String> _statusStrings = {};
  Map<String, String> _messageStrings = {};

  Map<String, String> get localizedStrings => _localizedStrings;
  Map<String, String> get statusStrings => _statusStrings;
  Map<String, String> get messageStrings => _messageStrings;

  /***********************************************************************
   *          장치 설정에서 언어를 설정하는 함수
   ***********************************************************************////
  Future<void> setLanguageFromDeviceConfig() async {
    // 장치 설정에서 언어를 가져옴
    String language = ConfigFileCtrl.deviceConfigLanguage;
    String jsonString = await rootBundle.loadString(languagePath);
    String jsonStatusString = await rootBundle.loadString(statusLanguagePath);
    String jsonMessageString = await rootBundle.loadString(messagePath);
    // JSON 문자열을 파싱하여 맵으로 변환
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    Map<String, dynamic> jsonStatusMap = json.decode(jsonStatusString);
    Map<String, dynamic> jsonMessageMap = json.decode(jsonMessageString);

    // 로컬라이즈된 문자열 맵을 초기화
    _localizedStrings = (jsonMap[language] as Map<String, dynamic>).map((key, value) {
      return MapEntry(key, value.toString());
    });
    // 상태 문자열 맵을 초기화
    _statusStrings = (jsonStatusMap[language] as Map<String, dynamic>).map((key, value) {
      return MapEntry(key, value.toString());
    });
    // 메시지 문자열 맵을 초기화
    _messageStrings = (jsonMessageMap[language] as Map<String, dynamic>).map((key, value) {
      return MapEntry(key, value.toString());
    });

    notifyListeners();
  }

  /***********************************************************************
   *          언어를 설정하는 함수
   ***********************************************************************////
  Future<void> setLanguage(String language) async {
    String jsonString = await rootBundle.loadString(languagePath);
    String jsonStatusString = await rootBundle.loadString(statusLanguagePath);
    String jsonMessageString = await rootBundle.loadString(messagePath);
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    Map<String, dynamic> jsonStatusMap = json.decode(jsonStatusString);
    Map<String, dynamic> jsonMessageMap = json.decode(jsonMessageString);

    // 로컬라이즈된 문자열 맵을 초기화
    _localizedStrings = (jsonMap[language] as Map<String, dynamic>).map((key, value) {
      return MapEntry(key, value.toString());
    });
    // 상태 문자열 맵을 초기화
    _statusStrings = (jsonStatusMap[language] as Map<String, dynamic>).map((key, value) {
      return MapEntry(key, value.toString());
    });
    // 메시지 문자열 맵을 초기화
    _messageStrings = (jsonMessageMap[language] as Map<String, dynamic>).map((key, value) {
      return MapEntry(key, value.toString());
    });

    notifyListeners();
  }

  /***********************************************************************
   *          주어진 키에 해당하는 로컬라이즈된 문자열을 반환하는 함수
   ***********************************************************************////
  String getLanguageTransValue(String key) {
    return _localizedStrings[key] ?? key;
  }

  /***********************************************************************
   *          주어진 키에 해당하는 상태 문자열을 반환하는 함수
   ***********************************************************************////
  String getStatusLanguageTransValue(String key) {
    return _statusStrings[key] ?? key;
  }

  /***********************************************************************
   *          주어진 키에 해당하는 메시지 문자열을 반환하는 함수
   ***********************************************************************////
  String getMessageTransValue(String key) {
    return _messageStrings[key] ?? key;
  }
}