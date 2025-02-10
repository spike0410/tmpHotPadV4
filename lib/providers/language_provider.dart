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

  Future<void> setLanguageFromDeviceConfig() async {
    String language = ConfigFileCtrl.deviceConfigLanguage;
    String jsonString = await rootBundle.loadString(languagePath);
    String jsonStatusString = await rootBundle.loadString(statusLanguagePath);
    String jsonMessageString = await rootBundle.loadString(messagePath);
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    Map<String, dynamic> jsonStatusMap = json.decode(jsonStatusString);
    Map<String, dynamic> jsonMessageMap = json.decode(jsonMessageString);

    _localizedStrings = (jsonMap[language] as Map<String, dynamic>).map((key, value) {
      return MapEntry(key, value.toString());
    });

    _statusStrings = (jsonStatusMap[language] as Map<String, dynamic>).map((key, value) {
      return MapEntry(key, value.toString());
    });

    _messageStrings = (jsonMessageMap[language] as Map<String, dynamic>).map((key, value) {
      return MapEntry(key, value.toString());
    });

    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    String jsonString = await rootBundle.loadString(languagePath);
    String jsonStatusString = await rootBundle.loadString(statusLanguagePath);
    String jsonMessageString = await rootBundle.loadString(messagePath);
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    Map<String, dynamic> jsonStatusMap = json.decode(jsonStatusString);
    Map<String, dynamic> jsonMessageMap = json.decode(jsonMessageString);

    _localizedStrings = (jsonMap[language] as Map<String, dynamic>).map((key, value) {
      return MapEntry(key, value.toString());
    });

    _statusStrings = (jsonStatusMap[language] as Map<String, dynamic>).map((key, value) {
      return MapEntry(key, value.toString());
    });

    _messageStrings = (jsonMessageMap[language] as Map<String, dynamic>).map((key, value) {
      return MapEntry(key, value.toString());
    });

    notifyListeners();
  }

  String getLanguageTransValue(String key) {
    return _localizedStrings[key] ?? key;
  }

  String getStatusLanguageTransValue(String key) {
    return _statusStrings[key] ?? key;
  }

  String getMessageTransValue(String key) {
    return _messageStrings[key] ?? key;
  }
}