import 'package:flutter/material.dart';

const swVersion = '4.0.0';

/*****************************************************************
 *                       Color Style
 *****************************************************************////
const backgroundColor = Color(0xFFC0C0C0);    // Background Color
const barBackgroundColor = Color(0xFFF0F0F0);   // Gradient Color
const gbarBackgroundColor = Color(0xFF808080);   // Gradient Color
const textBarColor = Color(0xFF000080);
const gtextBarColor = Color(0xFF006DC6);
const tabSelectedColor = backgroundColor;
const tabUnselectedColor = Color(0xFFFFFFFF);
const homeHeaderColor = Color(0xFFA5A5A5);
const pu45SelectColor = Color(0xFF3060FF);      // Home Page - PU45 Select Color
const gpu45SelectColor = Color(0xFF002070);     // Home Page - PU45 Select Gradient Color

/*****************************************************************
 *                       Text Style
 *****************************************************************////
const titleTextColor = Color(0xFF004DA5);         // Title Text Color
const double defaultFontSize = 14.0;              // Default Font Size

/*****************************************************************
 *                    Constant Variable
 *****************************************************************////
const int totalChannel = 10;
const double barHeight = 70.0;                    // AppBar & BottomAppBar Height
const double tabBarHeight = 45.0;                 // TabBar Height

const double menuBtnHeight = barHeight - 20.0;    // Menu Button Height
const double menuBtnWidth = barHeight - 20.0;     // Menu Button Width

const double zoomBtnHeight = barHeight - 30.0;    // Zoom Button Height
const double zoomBtnWidth = barHeight - 30.0;     // Zoom Button Width

/*****************************************************************
 *                        Image Path
 *****************************************************************////
const String iconHomePath = 'asset/img/settings.png';
const String iconGraphPath = 'asset/img/trends.png';
const String iconSetupPath = 'asset/img/tools.png';
const String iconAlarmPath = 'asset/img/caution.png';
const String iconBackupPath = 'asset/img/memorycard.png';
const String iconCapturePath = 'asset/img/camera.png';
const String iconLanguagePath = 'asset/img/LangSel.png';
const String iconZoomInPath = 'asset/img/zoomin.png';
const String iconZoomOutPath = 'asset/img/zoomout.png';
const String iconZoomZeroPath = 'asset/img/zoomzero.png';
const String iconPowerPath = 'asset/img/buttonShutdown.png';
const String iconLEDGreyPath = 'asset/img/LED_Gray.png';
const String iconLEDGreenPath = 'asset/img/LED_Green.png';
const String iconLEDRedPath = 'asset/img/LED_Red.png';
const String iconCloseBtnPath = 'asset/img/btnClose.png';

const String shiLogPath = 'asset/img/SamsungFooter-eng.png';
const String shiLogPath_kor = 'asset/img/SamsungFooter.png';

const String diskPath = 'asset/img/Disk.png';

const String homeBackgroundPath = 'asset/img/MainBackground.png';
const String LanguageBackgroundPath = 'asset/img/backLangSel.png';
const String setupTempSettingPath_kor = 'asset/img/TempSettings.png';
const String setupTempSettingPath = 'asset/img/TempSettings-eng.png';
const String setupTempCalPath_kor = 'asset/img/TempCal.png';
const String setupTempCalPath = 'asset/img/TempCal-eng.png';
const String setupSystemPath = 'asset/img/System-eng.png';
const String setupSystemPath_kor = 'asset/img/System.png';
const String ctrlFaultPath = 'asset/img/ctrl_FaultDiagnosis-eng.png';
const String ctrlFaultPath_kor = 'asset/img/ctrl_FaultDiagnosis.png';

const String viewBackupPath = 'asset/img/backupView.png';

/*****************************************************************
 *                        Enum Variable
 *****************************************************************////
enum StatusChannel {ready,  start, error}
enum HeatingStatus {stop, rising1st, holding1st, rising2nd, holding2nd, preheatRising, preheatHolding, error}

/*****************************************************************
 *                        Language Path
 *****************************************************************////
const String languagePath = 'asset/language/strings.json';
const String statusLanguagePath = 'asset/language/operate_status_strings.json';
const String messagePath = 'asset/language/message_strings.json';

/*****************************************************************
 *                        Log File Path
 *****************************************************************////
const String logDefaultFolder = 'HotpadData';
const String alarmFolder = 'Alarm';
const String logFolder = 'Log';
const String graphFolder = 'Graph';
const String screenShotsFolder = 'ScreenShots';
