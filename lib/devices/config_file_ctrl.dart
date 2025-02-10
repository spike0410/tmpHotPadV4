import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../constant/user_style.dart';
import '../providers/language_provider.dart';

class ConfigFileCtrl {
  static const String _isPU45EnableKey = 'isPU45Enable';
  static const String _heatingStepStatusKey = 'heatingStepStatus';
  static const String _isHeatingBtnKey = 'isHeatingBtn';
  static const String _isPreheatingBtnKey = 'isPreheatingBtn';
  static const String _padIDKey = 'padIDKey';

  static const String _versionKey = 'version';
  static const String _languageKey = 'Language';
  static const String _deviceConfigKey = 'deviceConfig';
  static const String _modeProfileConfigKey = 'modeProfileConfig';
  static const String _tempCalConfigKey = 'tempCalConfig';
  static const String _diagnosisConfigKey = 'diagnosisConfig';
  static const String _isTempCalDataKey = 'isTempCalData';
  static const String _tempCalDataKey = 'tempCalData';
  static const String _isACCalDataKey = 'isACCalData';
  static const String _acVoltCalDataKey = 'acVoltCalData';
  static const String _acCurrentOffsetCalDataKey = 'acCurrentOffsetCalData';
  static const String _acCurrentGainCalDataKey = 'acCurrentGainCalData';

  static const String _currentVersion = swVersion;

  // LanguageProvider 인스턴스를 추가합니다.
  static late LanguageProvider languageProvider;

  /*******************************************************************
   *                  Home Page Status Variable
   *******************************************************************////
  static List<bool> isPU45EnableList = List.filled(totalChannel, true);
  static List<HeatingStepStatus> heatingStepStatusList = List.filled(totalChannel, HeatingStepStatus.step1);
  static List<bool> isStartBtnList = List.filled(totalChannel, false);
  static List<bool> isPreheatingBtnList = List.filled(totalChannel, false);
  static List<String>  padIDList = List.filled(totalChannel, '');

  /*******************************************************************
   *                  Language Variable
   *******************************************************************////
  static String deviceConfigLanguage = '';

  /*******************************************************************
   *               Device Configuration Variable
   *******************************************************************////
  static int deviceConfigNumber = 0;
  static String deviceConfigUserPassword = '0000';
  static String deviceConfigAdminPassword = '00000';
  static double deviceConfigFANStartTemp = 0;
  static double deviceConfigFANDeltaTemp = 0;

  /*******************************************************************
   *          Mode Profile Configuration Variable
   *******************************************************************////
  static int preheatingTime = 0;
  static double pu15TargetTemp = 0;
  static int pu15HoldTime = 0;
  static double pu45Target1stTemp = 0;
  static double pu45Target2ndTemp = 0;
  static int pu45Ramp1stTime = 0;
  static int pu45Ramp2ndTime = 0;
  static int pu45Hold1stTime = 0;
  static int pu45Hold2ndTime = 0;

  /*******************************************************************
   *          Temp. Calibration Configuration Variable
   *******************************************************************////
  static int tempCalOhm = 0;
  static int tempCalTime = 0;
  static int tempCalGain = 0;
  static bool isTempCal = false;
  static List<double> tempCalData = [];

  /*******************************************************************
   *          Diagnosis Configuration Variable
   *******************************************************************////
  static double acVoltLow = 0;
  static double acVoltHigh = 0;
  static double acCurrentLow = 0;
  static double acCurrentHigh = 0;
  static double dcVoltLow = 0;
  static double dcVoltHigh = 0;
  static double dcCurrentHigh = 0;
  static double intTemp = 0;
  static int pu15Rising1stDelay = 0;
  static double pu15Rising1stDeltaTemp = 0;
  static int pu15RisingStopDelay = 0;
  static int pu15RisingRampTime = 0;
  static int pu15Over1stDelay = 0;
  static double pu15Over1stDeltaTemp = 0;
  static int pu15OverStopDelay = 0;
  static int pu45Rising1stDelay = 0;
  static double pu45Rising1stDeltaTemp = 0;
  static int pu45Rising2ndDelay = 0;
  static double pu45Rising2ndDeltaTemp = 0;
  static int pu45RisingStopDelay = 0;
  static int pu45Over1stDelay = 0;
  static double pu45Over1stDeltaTemp = 0;
  static int pu45Over2ndDelay = 0;
  static double pu45Over2ndDeltaTemp = 0;
  static int pu45OverStopDelay = 0;

  /*******************************************************************
   *          AC Power Calibration Configuration Variable
   *******************************************************************////
  static double acVoltCalOffset = 0;
  static double acVoltCalGain = 0;
  static bool isACPwrCal = false;
  static List<double> acCurrentOffsetCalData = [];
  static List<double> acCurrentGainCalData = [];

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getString(_versionKey);

    debugPrint("Saved SW Version : $storedVersion");

    if (storedVersion == null || (storedVersion != _currentVersion && !_isExemptVersion(storedVersion))) {
      await _saveDefaults(prefs);
    }
    // await _saveDefaults(prefs);     // <---!@# Test
    await _loadData(prefs);
  }

  static bool _isExemptVersion(String version) {
    return ['4.0.1', swVersion].contains(version);
  }

  static Future<void> _saveDefaults(SharedPreferences prefs) async {
    debugPrint("_saveDefaults");

    final isTempCal = prefs.getBool(_isTempCalDataKey);
    final isACPwrCal = prefs.getBool(_isACCalDataKey);

    await prefs.setString(_languageKey, 'Kor');
    await prefs.setString(_isPU45EnableKey, jsonEncode(isPU45EnableList));
    List<String> stringList = heatingStepStatusList.map((status) => status.toString()).toList();
    await prefs.setString(_heatingStepStatusKey, jsonEncode(stringList));
    await prefs.setString(_isHeatingBtnKey, jsonEncode(isStartBtnList));
    await prefs.setString(_isPreheatingBtnKey, jsonEncode(isPreheatingBtnList));
    await prefs.setString(_padIDKey, jsonEncode(padIDList));

    await prefs.setString(_versionKey, _currentVersion);
    await prefs.setString(_deviceConfigKey, jsonEncode(_defaultDeviceConfig));
    await prefs.setString(_modeProfileConfigKey, jsonEncode(_defaultModeProfileConfig));
    await prefs.setString(_tempCalConfigKey, jsonEncode(_defaultTempCalConfig));
    await prefs.setString(_diagnosisConfigKey, jsonEncode(_defaultDiagnosisConfig));

    if(isTempCal == null || !isTempCal) {
      await prefs.setString(_tempCalDataKey, jsonEncode(_defaultTempCalData));
    }

    if(isACPwrCal == null || !isACPwrCal) {
      await prefs.setString(_acVoltCalDataKey, jsonEncode(_defaultACVoltCalData));
      await prefs.setString(_acCurrentOffsetCalDataKey,jsonEncode(_defaultACCurrentOffsetCalData));
      await prefs.setString(_acCurrentGainCalDataKey, jsonEncode(_defaultACCurrentGainCalData));
    }
  }

  static Future<void> _loadData(SharedPreferences prefs) async {
    await _getLanguageData(prefs);
    await _getHomePageStatusData(prefs);
    await _getDeviceConfigData(prefs);
    await _getModeProfileConfigData(prefs);
    await _getTempCalConfigData(prefs);
    await _getDiagnosisConfigData(prefs);
    await _getACPowerConfigData(prefs);
  }

  /*******************************************************************
   *               get Home Page Status
   *******************************************************************////
  static Future<void> _getHomePageStatusData(SharedPreferences prefs) async {
    final String? jPU45Enable = prefs.getString(_isPU45EnableKey);
    final String? jHeatingStepStatus = prefs.getString(_heatingStepStatusKey);
    final String? jHeatingBtn = prefs.getString(_isHeatingBtnKey);
    final String? jPreheatingBtn = prefs.getString(_isPreheatingBtnKey);
    final String? jPadID = prefs.getString(_padIDKey);

    if (jPU45Enable != null) {
      isPU45EnableList = List<bool>.from(jsonDecode(jPU45Enable));
    }

    if(jHeatingStepStatus != null){
      List<dynamic> stringList = jsonDecode(jHeatingStepStatus);
      heatingStepStatusList = stringList.map((status) => HeatingStepStatus.values.firstWhere((e) => e.toString() == status)).toList();
    }

    if (jHeatingBtn != null) {
      isStartBtnList = List<bool>.from(jsonDecode(jHeatingBtn));
    }

    if (jPreheatingBtn != null) {
      isPreheatingBtnList = List<bool>.from(jsonDecode(jPreheatingBtn));
    }

    if (jPadID != null) {
      padIDList = List<String>.from(jsonDecode(jPadID));
    }

    debugPrint("### HomePageStatusData[isPU45Enable]###\n$isPU45EnableList");
    debugPrint("### HomePageStatusData[heatingStepStatus]###\n$heatingStepStatusList");
    debugPrint("### HomePageStatusData[isHeatingBtn]###\n$isStartBtnList");
    debugPrint("### HomePageStatusData[isPreheatingBtn]###\n$isPreheatingBtnList");
    debugPrint("### HomePageStatusData[padID]###\n$padIDList");
  }

  /*******************************************************************
   *               get Device Configuration
   *******************************************************************////
  static Future<void> _getLanguageData(SharedPreferences prefs) async {
    deviceConfigLanguage = prefs.getString(_languageKey)!;

    debugPrint("### LanguageData###\n$deviceConfigLanguage");
  }

  /*******************************************************************
   *               get Device Configuration
   *******************************************************************////
  static Future<void> _getDeviceConfigData(SharedPreferences prefs) async {
    List<Map<String, dynamic>> deviceConfig = [];
    deviceConfig = List<Map<String, dynamic>>.from(jsonDecode(prefs.getString(_deviceConfigKey) ?? '[]'));

    debugPrint("### DeviceConfigData###\n${deviceConfig.map((map) => map.toString()).join(',\n')}");

    deviceConfigNumber = deviceConfig.firstWhere((map) => map.containsKey('DeviceNumber'), orElse: () => {},)['DeviceNumber'];
    deviceConfigUserPassword = deviceConfig.firstWhere((map) => map.containsKey('UserPassword'), orElse: () => {},)['UserPassword'];
    deviceConfigAdminPassword = deviceConfig.firstWhere((map) => map.containsKey('AdminPassword'), orElse: () => {},)['AdminPassword'];
    deviceConfigFANStartTemp = deviceConfig.firstWhere((map) => map.containsKey('FANStartTemp'), orElse: () => {},)['FANStartTemp']?.toDouble()?? 0.0;
    deviceConfigFANDeltaTemp = deviceConfig.firstWhere((map) => map.containsKey('FANDeltaTemp'), orElse: () => {},)['FANDeltaTemp']?.toDouble()?? 0.0;
  }

  /*******************************************************************
   *               get Mode Profile Configuration
   *******************************************************************////
  static Future<void> _getModeProfileConfigData(SharedPreferences prefs) async {
    List<Map<String, dynamic>> modeProfileConfig = [];
    modeProfileConfig = List<Map<String, dynamic>>.from(jsonDecode(prefs.getString(_modeProfileConfigKey) ?? '[]'));

    debugPrint("### ModeProfileConfigData ###\n${modeProfileConfig.map((map) => map.toString()).join(',\n')}");

    preheatingTime = modeProfileConfig.firstWhere((map) => map.containsKey('PreheatingTime'), orElse: () => {},)['PreheatingTime'];
    pu15TargetTemp = modeProfileConfig.firstWhere((map) => map.containsKey('PU15TargetTemp'), orElse: () => {},)['PU15TargetTemp']?.toDouble()?? 0.0;
    pu15HoldTime = modeProfileConfig.firstWhere((map) => map.containsKey('PU15HoldTime'), orElse: () => {},)['PU15HoldTime'];
    pu45Target1stTemp = modeProfileConfig.firstWhere((map) => map.containsKey('PU45Target1stTemp'), orElse: () => {},)['PU45Target1stTemp']?.toDouble()?? 0.0;
    pu45Target2ndTemp = modeProfileConfig.firstWhere((map) => map.containsKey('PU45Target2ndTemp'), orElse: () => {},)['PU45Target2ndTemp']?.toDouble()?? 0.0;
    pu45Ramp1stTime = modeProfileConfig.firstWhere((map) => map.containsKey('PU45Ramp1stTime'), orElse: () => {},)['PU45Ramp1stTime'];
    pu45Ramp2ndTime = modeProfileConfig.firstWhere((map) => map.containsKey('PU45Ramp2ndTime'), orElse: () => {},)['PU45Ramp2ndTime'];
    pu45Hold1stTime = modeProfileConfig.firstWhere((map) => map.containsKey('PU45Hold1stTime'), orElse: () => {},)['PU45Hold1stTime'];
    pu45Hold2ndTime = modeProfileConfig.firstWhere((map) => map.containsKey('PU45Hold2ndTime'), orElse: () => {},)['PU45Hold2ndTime'];
  }

  /*******************************************************************
   *               get Temp. Calibration Configuration
   *******************************************************************////
  static Future<void> _getTempCalConfigData(SharedPreferences prefs) async {
    List<Map<String, dynamic>> tempCalConfig = [];
    tempCalConfig = List<Map<String, dynamic>>.from(jsonDecode(prefs.getString(_tempCalConfigKey) ?? '[]'));

    debugPrint("### TempCalConfigData ###\n${tempCalConfig.map((map) => map.toString()).join(',\n')}");

    tempCalOhm = tempCalConfig.firstWhere((map) => map.containsKey('TargetOhm'), orElse: () => {},)['TargetOhm'];
    tempCalTime = tempCalConfig.firstWhere((map) => map.containsKey('Time'), orElse: () => {},)['Time'];
    tempCalGain = tempCalConfig.firstWhere((map) => map.containsKey('Gain'), orElse: () => {},)['Gain'];
    isTempCal = prefs.getBool(_isTempCalDataKey)?? false;
    tempCalData = List<double>.from(jsonDecode(prefs.getString(_tempCalDataKey) ?? '[]'));
  }

  /*******************************************************************
   *               get Diagnosis Configuration
   *******************************************************************////
  static Future<void> _getDiagnosisConfigData(SharedPreferences prefs) async {
    List<Map<String, dynamic>> diagnosisConfig = [];
    diagnosisConfig = List<Map<String, dynamic>>.from(jsonDecode(prefs.getString(_diagnosisConfigKey) ?? '[]'));

    debugPrint("### DiagnosisConfigData ###\n${diagnosisConfig.map((map) => map.toString()).join(',\n')}");

    /// ### AC/DC Power Configuration ###
    acVoltLow = diagnosisConfig.firstWhere((map) => map.containsKey('ACVoltLow'), orElse: () => {},)['ACVoltLow']?.toDouble()?? 0.0;
    acVoltHigh = diagnosisConfig.firstWhere((map) => map.containsKey('ACVoltHigh'), orElse: () => {},)['ACVoltHigh']?.toDouble()?? 0.0;
    acCurrentLow = diagnosisConfig.firstWhere((map) => map.containsKey('ACCurrentLow'), orElse: () => {},)['ACCurrentLow']?.toDouble()?? 0.0;
    acCurrentHigh = diagnosisConfig.firstWhere((map) => map.containsKey('ACCurrentHigh'), orElse: () => {},)['ACCurrentHigh']?.toDouble()?? 0.0;
    dcVoltLow = diagnosisConfig.firstWhere((map) => map.containsKey('DCVoltLow'), orElse: () => {},)['DCVoltLow']?.toDouble()?? 0.0;
    dcVoltHigh = diagnosisConfig.firstWhere((map) => map.containsKey('DCVoltHigh'), orElse: () => {},)['DCVoltHigh']?.toDouble()?? 0.0;
    dcCurrentHigh = diagnosisConfig.firstWhere((map) => map.containsKey('DCCurrentHigh'), orElse: () => {},)['DCCurrentHigh']?.toDouble()?? 0.0;
    intTemp = diagnosisConfig.firstWhere((map) => map.containsKey('IntTemp'), orElse: () => {},)['IntTemp']?.toDouble()?? 0.0;
    /// ### PU15 Diagnosis Configuration ###
    pu15Rising1stDelay = diagnosisConfig.firstWhere((map) => map.containsKey('PU15Rising1stDelay'), orElse: () => {},)['PU15Rising1stDelay'];
    pu15Rising1stDeltaTemp = diagnosisConfig.firstWhere((map) => map.containsKey('PU15Rising1stDeltaTemp'), orElse: () => {},)['PU15Rising1stDeltaTemp']?.toDouble()?? 0.0;
    pu15RisingStopDelay = diagnosisConfig.firstWhere((map) => map.containsKey('PU15RisingStopDelay'), orElse: () => {},)['PU15RisingStopDelay'];
    pu15RisingRampTime = diagnosisConfig.firstWhere((map) => map.containsKey('PU15RisingRampTime'), orElse: () => {},)['PU15RisingRampTime'];
    pu15Over1stDelay = diagnosisConfig.firstWhere((map) => map.containsKey('PU15Over1stDelay'), orElse: () => {},)['PU15Over1stDelay'];
    pu15Over1stDeltaTemp = diagnosisConfig.firstWhere((map) => map.containsKey('PU15Over1stDeltaTemp'), orElse: () => {},)['PU15Over1stDeltaTemp']?.toDouble()?? 0.0;
    pu15OverStopDelay = diagnosisConfig.firstWhere((map) => map.containsKey('PU15OverStopDelay'), orElse: () => {},)['PU15OverStopDelay'];
    /// ### PU45 Diagnosis Configuration ###
    pu45Rising1stDelay = diagnosisConfig.firstWhere((map) => map.containsKey('PU45Rising1stDelay'), orElse: () => {},)['PU45Rising1stDelay'];
    pu45Rising1stDeltaTemp = diagnosisConfig.firstWhere((map) => map.containsKey('PU45Rising1stDeltaTemp'), orElse: () => {},)['PU45Rising1stDeltaTemp']?.toDouble()?? 0.0;
    pu45Rising2ndDelay = diagnosisConfig.firstWhere((map) => map.containsKey('PU45Rising2ndDelay'), orElse: () => {},)['PU45Rising2ndDelay'];
    pu45Rising2ndDeltaTemp = diagnosisConfig.firstWhere((map) => map.containsKey('PU45Rising2ndDeltaTemp'), orElse: () => {},)['PU45Rising2ndDeltaTemp']?.toDouble()?? 0.0;
    pu45RisingStopDelay = diagnosisConfig.firstWhere((map) => map.containsKey('PU45RisingStopDelay'), orElse: () => {},)['PU45RisingStopDelay'];
    pu45Over1stDelay = diagnosisConfig.firstWhere((map) => map.containsKey('PU45Over1stDelay'), orElse: () => {},)['PU45Over1stDelay'];
    pu45Over1stDeltaTemp = diagnosisConfig.firstWhere((map) => map.containsKey('PU45Over1stDeltaTemp'), orElse: () => {},)['PU45Over1stDeltaTemp']?.toDouble()?? 0.0;
    pu45Over2ndDelay = diagnosisConfig.firstWhere((map) => map.containsKey('PU45Over2ndDelay'), orElse: () => {},)['PU45Over2ndDelay'];
    pu45Over2ndDeltaTemp = diagnosisConfig.firstWhere((map) => map.containsKey('PU45Over2ndDeltaTemp'), orElse: () => {},)['PU45Over2ndDeltaTemp']?.toDouble()?? 0.0;
    pu45OverStopDelay = diagnosisConfig.firstWhere((map) => map.containsKey('PU45OverStopDelay'), orElse: () => {},)['PU45OverStopDelay'];

  }

  /*******************************************************************
   *               get AC Power Configuration
   *******************************************************************////
  static Future<void> _getACPowerConfigData(SharedPreferences prefs) async {
    List<Map<String, dynamic>> acVoltCalData = [];
    acVoltCalData = List<Map<String, dynamic>>.from(jsonDecode(prefs.getString(_acVoltCalDataKey) ?? '[]'));

    debugPrint("### ACPowerConfigData ###\n${acVoltCalData.map((map) => map.toString()).join(',\n')}");

    acCurrentOffsetCalData = List<double>.from(jsonDecode(prefs.getString(_acCurrentOffsetCalDataKey) ?? '[]'));
    acCurrentGainCalData = List<double>.from(jsonDecode(prefs.getString(_acCurrentGainCalDataKey) ?? '[]'));

    isACPwrCal = prefs.getBool(_isACCalDataKey)?? false;
    acVoltCalOffset = acVoltCalData.firstWhere((map) => map.containsKey('Offset'), orElse: () => {},)['Offset']?.toDouble()?? 0.0;
    acVoltCalGain = acVoltCalData.firstWhere((map) => map.containsKey('Gain'), orElse: () => {},)['Gain']?.toDouble()?? 0.0;

  }

  /*******************************************************************
   *               set Home Page Status
   *******************************************************************////
  static Future<void> setHomePageStatusData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_isPU45EnableKey, jsonEncode(isPU45EnableList));
    List<String> stringList = heatingStepStatusList.map((status) => status.toString()).toList();
    await prefs.setString(_heatingStepStatusKey, jsonEncode(stringList));
    await prefs.setString(_isHeatingBtnKey, jsonEncode(isStartBtnList));
    await prefs.setString(_isPreheatingBtnKey, jsonEncode(isPreheatingBtnList));
    await prefs.setString(_padIDKey, jsonEncode(padIDList));

    debugPrint("#1 setHomePageStatusData[isPU45Enable]\n$isPU45EnableList");
    debugPrint("#2 setHomePageStatusData[heatingStepStatus]\n$heatingStepStatusList");
    debugPrint("#3 setHomePageStatusData[isStartBtn]\n$isStartBtnList");
    debugPrint("#4 setHomePageStatusData[isPreheatingBtn]\n$isPreheatingBtnList");
    debugPrint("#5 setHomePageStatusData[padID]\n$padIDList");
  }

  /*******************************************************************
   *               set Language
   *******************************************************************////
  static Future<void> setLanguageData(BuildContext context) async{
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_languageKey, deviceConfigLanguage);

    debugPrint("setLanguageData]\n$deviceConfigLanguage");

    // 언어 변경 시 LanguageProvider의 setLanguage 호출
    await Provider.of<LanguageProvider>(context, listen: false).setLanguage(deviceConfigLanguage);

  }

  /*******************************************************************
   *               set Device Configuration
   *******************************************************************////
  static Future<void> setDeviceConfigData() async{
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> deviceConfig = [];
    deviceConfig.add({'Language': deviceConfigLanguage});
    deviceConfig.add({'DeviceNumber': deviceConfigNumber});
    deviceConfig.add({'UserPassword': deviceConfigUserPassword});
    deviceConfig.add({'AdminPassword': deviceConfigAdminPassword});
    deviceConfig.add({'FANStartTemp': deviceConfigFANStartTemp});
    deviceConfig.add({'FANDeltaTemp': deviceConfigFANDeltaTemp});

    debugPrint("setDeviceConfigData]\n${deviceConfig.map((map) => map.toString()).join(',\n')}");

    await prefs.setString(_deviceConfigKey, jsonEncode(deviceConfig));
  }

  /*******************************************************************
   *               set Mode Profile Configuration
   *******************************************************************////
  static Future<void> setModeProfileConfigData() async{
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> modeProfileConfig = [];

    modeProfileConfig.add({'PreheatingTime': preheatingTime});
    modeProfileConfig.add({'PU15TargetTemp': pu15TargetTemp});
    modeProfileConfig.add({'PU15HoldTime': pu15HoldTime});
    modeProfileConfig.add({'PU45Target1stTemp': pu45Target1stTemp});
    modeProfileConfig.add({'PU45Target2ndTemp': pu45Target2ndTemp});
    modeProfileConfig.add({'PU45Ramp1stTime': pu45Ramp1stTime});
    modeProfileConfig.add({'PU45Ramp2ndTime': pu45Ramp2ndTime});
    modeProfileConfig.add({'PU45Hold1stTime': pu45Hold1stTime});
    modeProfileConfig.add({'PU45Hold2ndTime': pu45Hold2ndTime});

    debugPrint("setModeProfileConfigData]\n${modeProfileConfig.map((map) => map.toString()).join(',\n')}");

    await prefs.setString(_modeProfileConfigKey, jsonEncode(modeProfileConfig));
  }

  /*******************************************************************
   *               set Temp. Calibration Configuration
   *******************************************************************////
  static Future<void> setTempCalConfigData() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> tempCalConfig = [];

    tempCalConfig.add({'TargetOhm': tempCalOhm});
    tempCalConfig.add({'Time': tempCalTime});
    tempCalConfig.add({'Gain': tempCalGain});

    // tempCalData = List<double>.from(jsonDecode(prefs.getString(_tempCalDataKey) ?? '[]'));

    debugPrint("setTempCalConfigData]\n${tempCalConfig.map((map) => map.toString()).join(',\n')}");

    await prefs.setString(_tempCalConfigKey, jsonEncode(tempCalConfig));
  }

  /*******************************************************************
   *               set Diagnosis Configuration
   *******************************************************************////
  static Future<void> setDiagnosisConfigData() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> diagnosisConfig = [];

    diagnosisConfig.add({'ACVoltLow': acVoltLow});
    diagnosisConfig.add({'ACVoltHigh': acVoltHigh});
    diagnosisConfig.add({'ACCurrentLow': acCurrentLow});
    diagnosisConfig.add({'ACCurrentHigh': acCurrentHigh});
    diagnosisConfig.add({'DCVoltLow': dcVoltLow});
    diagnosisConfig.add({'DCVoltHigh': dcVoltHigh});
    diagnosisConfig.add({'DCCurrentHigh': dcCurrentHigh});
    diagnosisConfig.add({'IntTemp': intTemp});

    diagnosisConfig.add({'PU15Rising1stDelay': pu15Rising1stDelay});
    diagnosisConfig.add({'PU15Rising1stDeltaTemp': pu15Rising1stDeltaTemp});
    diagnosisConfig.add({'PU15RisingStopDelay': pu15RisingStopDelay});
    diagnosisConfig.add({'PU15RisingRampTime': pu15RisingRampTime});
    diagnosisConfig.add({'PU15Over1stDelay': pu15Over1stDelay});
    diagnosisConfig.add({'PU15Over1stDeltaTemp': pu15Over1stDeltaTemp});
    diagnosisConfig.add({'PU15OverStopDelay': pu15OverStopDelay});

    diagnosisConfig.add({'PU45Rising1stDelay': pu45Rising1stDelay});
    diagnosisConfig.add({'PU45Rising1stDeltaTemp': pu45Rising1stDeltaTemp});
    diagnosisConfig.add({'PU45Rising2ndDelay': pu45Rising2ndDelay});
    diagnosisConfig.add({'PU45Rising2ndDeltaTemp': pu45Rising2ndDeltaTemp});
    diagnosisConfig.add({'PU45RisingStopDelay': pu45RisingStopDelay});
    diagnosisConfig.add({'PU45Over1stDelay': pu45Over1stDelay});
    diagnosisConfig.add({'PU45Over1stDeltaTemp': pu45Over1stDeltaTemp});
    diagnosisConfig.add({'PU45Over2ndDelay': pu45Over2ndDelay});
    diagnosisConfig.add({'PU45Over2ndDeltaTemp': pu45Over2ndDeltaTemp});
    diagnosisConfig.add({'PU45OverStopDelay': pu45OverStopDelay});

    debugPrint("setDiagnosisConfigData]\n${diagnosisConfig.map((map) => map.toString()).join(',\n')}");

    await prefs.setString(_diagnosisConfigKey, jsonEncode(diagnosisConfig));
  }

  /*******************************************************************
   *               set AC Power Configuration
   *******************************************************************////
  static Future<void> setACPowerConfigData() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> acVoltCalData = [];

    acVoltCalData.add({'Offset': acVoltCalOffset});
    acVoltCalData.add({'Gain': acVoltCalGain});

    debugPrint("setACPowerConfigData]\n${acVoltCalData.map((map) => map.toString()).join(',\n')}");

    // acCurrentOffsetCalData = List<double>.from(jsonDecode(prefs.getString(_acCurrentOffsetCalDataKey) ?? '[]'));
    // acCurrentGainCalData = List<double>.from(jsonDecode(prefs.getString(_acCurrentGainCalDataKey) ?? '[]'));
    //
    // isACPwrCal = prefs.getBool(_isACCalDataKey)?? false;

    await prefs.setString(_acVoltCalDataKey, jsonEncode(acVoltCalData));
  }

  /*******************************************************************
   *                Configuration Default Data
   *******************************************************************////
  static const List<Map<String, dynamic>> _defaultDeviceConfig = [
    {'DeviceNumber': 400},
    {'UserPassword': '0000'},
    {'AdminPassword': '54321'},
    {'FANStartTemp': 30.0},
    {'FANDeltaTemp': 1.0},
  ];

  static const List<Map<String, dynamic>> _defaultModeProfileConfig = [
    {'PreheatingTime': 180},
    {'PU15TargetTemp': 73.0},
    {'PU15HoldTime': 60},
    {'PU45Target1stTemp': 57.0},
    {'PU45Target2ndTemp': 78.0},
    {'PU45Ramp1stTime': 40},
    {'PU45Ramp2ndTime': 40},
    {'PU45Hold1stTime': 80},
    {'PU45Hold2ndTime': 60},
  ];

  static const List<Map<String, dynamic>> _defaultTempCalConfig = [
    {'TargetOhm': 110},
    {'Time': 30},
    {'Gain': 1000},
  ];

  static const List<Map<String, dynamic>> _defaultDiagnosisConfig = [
    {'ACVoltLow': 190},
    {'ACVoltHigh': 250},
    {'ACCurrentLow': 0.1},
    {'ACCurrentHigh': 3.3},
    {'DCVoltLow': 11},
    {'DCVoltHigh': 13},
    {'DCCurrentHigh': 2},
    {'IntTemp': 40},
    {'PU15Rising1stDelay': 20},
    {'PU15Rising1stDeltaTemp': 5},
    {'PU15RisingStopDelay': 5},
    {'PU15RisingRampTime': 20},
    {'PU15Over1stDelay': 5},
    {'PU15Over1stDeltaTemp': 5},
    {'PU15OverStopDelay': 5},
    {'PU45Rising1stDelay': 10},
    {'PU45Rising1stDeltaTemp': 5},
    {'PU45Rising2ndDelay': 10},
    {'PU45Rising2ndDeltaTemp': 5},
    {'PU45RisingStopDelay': 5},
    {'PU45Over1stDelay': 10},
    {'PU45Over1stDeltaTemp': 5},
    {'PU45Over2ndDelay': 10},
    {'PU45Over2ndDeltaTemp': 5},
    {'PU45OverStopDelay': 5},
  ];

  static const List<double> _defaultTempCalData = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  static const List<Map<String, double>> _defaultACVoltCalData = [
    {'Offset': 0},
    {'Gain': 1},
  ];
  static const List<double> _defaultACCurrentOffsetCalData = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  static const List<double> _defaultACCurrentGainCalData = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
}