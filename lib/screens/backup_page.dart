import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart'; // 플랫폼 채널 사용을 위해 추가
import 'package:sqflite/sqflite.dart';
import '../devices/hotpad_ctrl.dart';
import '../devices/file_ctrl.dart';
import '../providers/language_provider.dart';
import '../constant/user_style.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  _BackupPageState createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  static const platform = MethodChannel('usb_storage');
  bool isUSBConnect = false;
  double usbProgressValue = 0;
  late double usbTotalStorage;
  late double usbUsedStorage;
  late double usbFreeStorage;
  String usbPath = '';

  String selectedStartItem = '';
  String selectedEndItem = '';
  double selectedSize = 0;
  late bool isEjectCheckBox;
  double copyProgressValue = 0.0;
  int fileCount = 0;

  @override
  void initState() {
    super.initState();
    _getUSBStorageInfo();

    isEjectCheckBox = true;
    selectedStartItem = '';
    selectedEndItem = '';
    copyProgressValue = 0.0;
    fileCount = 0;

    // USB 마운트 이벤트 처리
    platform.setMethodCallHandler((call) async {
      if (call.method == "onUSBMounted") {
        _getUSBStorageInfo();
      }
    });
  }

  /***********************************************************************
   *          USB Storage 용량 확인 함수
   ***********************************************************************////
  Future<void> _getUSBStorageInfo() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getUSBStorageInfo');
      setState(() {
        isUSBConnect = true;
        usbTotalStorage = result[0] / (1024 * 1024); // MB 단위로 변환
        usbUsedStorage = result[1] / (1024 * 1024); // MB 단위로 변환
        usbFreeStorage = result[2] / (1024 * 1024); // MB 단위로 변환
        usbPath = result[3];
        usbProgressValue = usbUsedStorage / usbTotalStorage;
      });
    } on PlatformException catch (e) {
      setState(() {
        isUSBConnect = false;
        usbProgressValue = 0;
      });
      debugPrint("Failed to get USB storage info: '${e.message}'.");
    }
  }

  /***********************************************************************
   *          USB 안전 제거 함수
   ***********************************************************************////
  Future<void> _ejectUSB() async {
    try {
      final String result = await platform.invokeMethod('ejectUSB');
      debugPrint(result);
      setState(() {
        isUSBConnect = false;
        usbProgressValue = 0;
        usbPath = '';
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to eject USB storage: '${e.message}'.");
    }
  }

  /*****************************************************************************
   *          DropDownMenu에 선택된 항목으로 파일 크기를 계산하는 함수
   *****************************************************************************////
  void _calculateSelectedSize() {
    if (selectedStartItem != '' && selectedEndItem != '') {
      List<String> subFolderList = FileCtrl.searchSubFolder();
      int startIndex = subFolderList.indexOf(selectedStartItem);
      int endIndex = subFolderList.indexOf(selectedEndItem);

      if (startIndex != -1 && endIndex != -1 && startIndex <= endIndex) {
        double totalSize = 0;
        for (int i = startIndex; i <= endIndex; i++) {
          totalSize += FileCtrl.getFolderSize(subFolderList[i]);
        }
        setState(() {
          selectedSize = totalSize / (1024 * 1024); // MB 단위로 변환
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double halfWidth = (screenWidth / 2) - 60;
    final numberFormat = NumberFormat('#,##0');
    final ButtonStyle btnStyle = ElevatedButton.styleFrom(
      foregroundColor: isUSBConnect ? Colors.black : Colors.black38,
      minimumSize: Size(200, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    );

    final ButtonStyle btnStyle1 = ElevatedButton.styleFrom(
      foregroundColor: isUSBConnect ? Colors.black : Colors.black38,
      minimumSize: Size(170, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    );

    List<String> subFolderList = FileCtrl.searchSubFolder();

    final List<DropdownMenuEntry<String>> startItems
      = subFolderList.map((String value) =>
        DropdownMenuEntry<String>(value: value, label: value))
        .toList();

    final List<DropdownMenuEntry<String>> endItems
      = subFolderList.map((String value) =>
        DropdownMenuEntry<String>(value: value, label: value))
        .toList();
    final TextEditingController startTextCtrl = TextEditingController();
    final TextEditingController endTextCtrl = TextEditingController();

    startTextCtrl.text = selectedStartItem;
    endTextCtrl.text = selectedEndItem;

    const double textSize = (defaultFontSize + 6);

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 40),
          /// ### 내부 용량 확인 Text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                width: halfWidth,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      textBarColor,
                      gTextBarColor,
                      textBarColor,
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    languageProvider.getLanguageTransValue('Internal Storage'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: textSize,
                    ),
                  ),
                ),
              ),
              /// ### USB 용량 확인 Text
              Container(
                width: halfWidth,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      textBarColor,
                      gTextBarColor,
                      textBarColor,
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    languageProvider.getLanguageTransValue('USB Memory'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: textSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                width: halfWidth,
                height: 50,
                child: Align(
                  alignment: Alignment.center,
                  child: Consumer<HotpadCtrl>(
                    builder: (context, hotpadCtrl, _) {
                      return Text(
                        '${languageProvider.getLanguageTransValue('Total')} : ${numberFormat.format(hotpadCtrl.totalStorage.round())}MB'
                        ' / ${languageProvider.getLanguageTransValue('Usage')} : ${numberFormat.format(hotpadCtrl.usedStorage.round())}MB'
                        ' / ${languageProvider.getLanguageTransValue('Remain')} : ${numberFormat.format((hotpadCtrl.totalStorage - hotpadCtrl.usedStorage).round())}MB',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: (textSize - 4),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(
                width: halfWidth,
                height: 50,
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    isUSBConnect == true
                      ? '${languageProvider.getLanguageTransValue('Total')} : ${numberFormat.format(usbTotalStorage.round())}MB'
                          ' / ${languageProvider.getLanguageTransValue('Usage')} : ${numberFormat.format(usbUsedStorage.round())}MB'
                          ' / ${languageProvider.getLanguageTransValue('Remain')} : ${numberFormat.format(usbFreeStorage.round())}MB'
                      : languageProvider.getLanguageTransValue('Empty'),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: (textSize - 4),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Consumer<HotpadCtrl>(
            builder: (context, hotpadCtrl, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  /// ### 내부 용량 ProgressBar
                  Stack(
                    children: [
                      SizedBox(
                        width: halfWidth,
                        height: 35,
                        child: LinearProgressIndicator(
                          value: hotpadCtrl.storageProgressValue,
                          backgroundColor: Colors.white,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF006400)),
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            '${(hotpadCtrl.storageProgressValue * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: textSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  /// ### USB 용량 ProgressBar
                  Stack(
                    children: [
                      SizedBox(
                        width: halfWidth,
                        height: 35,
                        child: LinearProgressIndicator(
                          value: usbProgressValue,
                          backgroundColor: Colors.white,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006400)),
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Text(isUSBConnect == true
                              ? '${(usbProgressValue * 100).toStringAsFixed(1)}%'
                              : '',
                            style: TextStyle(
                              fontSize: textSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 30),
          Container(
            margin: EdgeInsets.only(left: 30, right: 30),
            padding: EdgeInsets.only(left: 30, top: 20, right: 30, bottom: 20),
            width: screenWidth,
            height: 320,
            decoration: BoxDecoration(
              color: Color(0xFFE7E7E7),
              border: Border.all(
                color: Colors.black,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    /// ### 복사 시작 항목 DropDownMenu
                    SizedBox(
                      width: 200,
                      child: Text(languageProvider.getLanguageTransValue('Copy start item'),
                      style: TextStyle(fontSize: textSize)),
                    ),
                    // SizedBox(width: 10),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      child: DropdownMenu(
                        width: 250,
                        enabled: isUSBConnect,
                        controller: startTextCtrl,
                        hintText: languageProvider.getLanguageTransValue('select...'),
                        onSelected: (value) {
                          if(endTextCtrl.text != ''){
                            if((subFolderList.indexOf(value!) <= subFolderList.indexOf(endTextCtrl.text))){
                              selectedStartItem = value;
                            }
                            else {
                              selectedStartItem = '';
                            }
                          }
                          else{
                            selectedStartItem = value!;
                          }
                          setState(() {
                            startTextCtrl.text = selectedStartItem;
                            endTextCtrl.text = selectedEndItem;
                            // 새 항목을 선택하면 파일 크기를 다시 계산합니다.
                            _calculateSelectedSize();
                          });
                        },
                        dropdownMenuEntries: startItems,
                      ),
                    ),
                    SizedBox(width: 55),
                    /// ### 최대 선택 Button
                    ElevatedButton(
                      onPressed: isUSBConnect
                        ? () {
                          setState(() {
                            selectedStartItem = startItems.first.value;
                            selectedEndItem = endItems.last.value;
                            startTextCtrl.text = selectedStartItem;
                            endTextCtrl.text = selectedEndItem;
                            // 새 항목을 선택하면 파일 크기를 다시 계산합니다.
                            _calculateSelectedSize();
                          });
                        }
                        : null,
                      style: btnStyle,
                      child: Text(languageProvider.getLanguageTransValue('Select Maximum'),
                        style: TextStyle(
                          color: isUSBConnect ? Colors.black : Colors.black45,
                          fontWeight: FontWeight.bold,
                          fontSize: (textSize - 4),
                        ),
                      ),
                    ),
                    SizedBox(width: 150),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    /// ### 복사 마지막 항목 DropDownMenu
                    SizedBox(
                      width: 200,
                      child: Text(languageProvider.getLanguageTransValue('Copy last item'),
                        style: TextStyle(fontSize: textSize),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      child: DropdownMenu(
                        width: 250,
                        enabled: isUSBConnect,
                        controller: endTextCtrl,
                        hintText: languageProvider.getLanguageTransValue('select...'),
                        onSelected: (value) {
                          if(startTextCtrl.text != ''){
                            if((subFolderList.indexOf(value!) >= subFolderList.indexOf(startTextCtrl.text))){
                              selectedEndItem = value;
                            }
                            else {
                              selectedEndItem = '';
                            }
                          }
                          else{
                            selectedEndItem = value!;
                          }
                          setState(() {
                            startTextCtrl.text = selectedStartItem;
                            endTextCtrl.text = selectedEndItem;
                            // 새 항목을 선택하면 파일 크기를 다시 계산합니다.
                            _calculateSelectedSize();
                          });
                        },
                        dropdownMenuEntries: endItems,
                      ),
                    ),
                    SizedBox(width: 55),
                    /// ### 복사 시작 항목 - 복사 마지막 항목 총 용량
                    Text('${languageProvider.getLanguageTransValue('Selected')}: ${selectedSize.toStringAsFixed(1)}MB',
                      style: TextStyle(fontSize: textSize),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        /// ### 복사 진행 ProgressBar
                        Text(languageProvider.getLanguageTransValue('Process Progress'),
                          style: TextStyle(fontSize: (textSize - 4)),
                        ),
                        SizedBox(height: 5),
                        Stack(
                          children: [
                            SizedBox(
                              width: halfWidth,
                              height: 30,
                              child: LinearProgressIndicator(
                                value: copyProgressValue,
                                backgroundColor: Colors.white,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006400)),
                              ),
                            ),
                            Positioned.fill(
                              child: Center(
                                child: Text('${(copyProgressValue * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: (textSize - 4),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(width: 40),
                    /// ### 복사 완료 후 USB 꺼내기 CheckBox
                    Checkbox(
                      value: isEjectCheckBox,
                      onChanged: (value) {
                        setState(() {
                          isEjectCheckBox = value!;
                        });
                      },
                      checkColor: Colors.black,
                      fillColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                        if (states.contains(WidgetState.disabled)) {
                          return Colors.grey;
                        }
                        return Colors.white;
                      }),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      side: const BorderSide(
                        color: Colors.black,
                        width: 1,
                      ),
                    ),
                    Text(languageProvider.getLanguageTransValue('Eject USB after copying is complete.'),
                      style: TextStyle(fontSize: textSize),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    /// ### USB로 데이터 복사 Button
                    ElevatedButton(
                      onPressed: isUSBConnect
                        ? () async {
                        if((selectedStartItem == '') || (selectedEndItem == '')){
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(languageProvider.getLanguageTransValue('There are no selected items'),
                              textAlign: TextAlign.center),
                            duration: Duration(seconds: 3),
                          ));
                        }
                        else{
                          if(!await _copyDataToUsb(selectedStartItem, selectedEndItem, usbPath)){
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(languageProvider.getLanguageTransValue('The file path is incorrect'),
                                  textAlign: TextAlign.center),
                              duration: Duration(seconds: 3),
                            ));
                          }
                        }
                      }
                      : null,
                      style: btnStyle1,
                      child: Text(languageProvider.getLanguageTransValue('Copy to USB'),
                        style: TextStyle(
                          color: isUSBConnect ? Colors.black : Colors.black45,
                          fontWeight: FontWeight.bold,
                          fontSize: (textSize - 4),
                        ),
                      ),
                    ),
                    SizedBox(width: 55),
                    /// ### USB 안전 제거 Button
                    ElevatedButton(
                      onPressed: isUSBConnect
                        ? (isEjectCheckBox ? null : _ejectUSB)
                        : null,
                      style: btnStyle1,
                      child: Text(languageProvider.getLanguageTransValue('Eject USB'),
                        style: TextStyle(
                          color: isUSBConnect
                            ? (isEjectCheckBox
                              ? Colors.black45
                              : Colors.black)
                            : Colors.black45,
                          fontWeight: FontWeight.bold,
                          fontSize: (textSize - 4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              /// ### 내부 저장 Data 삭제 Button
              ElevatedButton(
                onPressed: () {
                  _intDataDelete(context, languageProvider);
                },
                style: btnStyle,
                child: Text(languageProvider.getLanguageTransValue('Delete Int. Data'),
                  style: TextStyle(
                    color: isUSBConnect ? Colors.black : Colors.black45,
                    fontWeight: FontWeight.bold,
                    fontSize: (textSize - 4),
                  ),
                ),
              ),
              SizedBox(width: 30),
            ],
          ),
        ],
      ),
    );
  }

  /*****************************************************************************
   *          내부 저장 데이터 삭제 다이얼로그 함수
   *****************************************************************************////
  Future<void> _intDataDelete( BuildContext context, LanguageProvider languageProvider) async {
    List<String> deleteSubFolder = FileCtrl.searchSubFolder();
    deleteSubFolder.removeWhere((value) => value == DateFormat('yyyyMM').format(DateTime.now()));
    final hotpadCtrl = Provider.of<HotpadCtrl>(context, listen: false);

    final TextEditingController startTextCtrl = TextEditingController();
    final TextEditingController endTextCtrl = TextEditingController();

    String deleteMsg = '';

    startTextCtrl.text = '';
    endTextCtrl.text = '';

    /// ### message Text 출력 함수
    void showDeleteMsg(StateSetter setState, String msg) async{
      setState(() {
        deleteMsg = languageProvider.getLanguageTransValue(msg);
      });
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        startTextCtrl.text = '';
        endTextCtrl.text = '';
        deleteMsg = '';
      });
    }
    /// ### item 선택 범위를 최대 선택 함수
    void maxItemRange(StateSetter setState){
      setState((){
        startTextCtrl.text = deleteSubFolder.first;
        endTextCtrl.text = deleteSubFolder.last;
      });
    }
    /// ### item 선택 확인 함수
    void checkItemRange(StateSetter setState){
      setState((){
        if((startTextCtrl.text != '') && (endTextCtrl.text != '')){
          if(deleteSubFolder.indexOf(startTextCtrl.text) > deleteSubFolder.indexOf(endTextCtrl.text)){
            showDeleteMsg(setState, "The selection is incorrect.");
          }
        }
      });
    }
    /// ### 선택된 item항목 삭제 함수
    void runDelete(StateSetter setState) {
      int startIndex = deleteSubFolder.indexOf(startTextCtrl.text);
      int endIndex = deleteSubFolder.indexOf(endTextCtrl.text);

      if(startIndex > endIndex) {
        return;
      }
      /// ### 삭제 재확인 다이얼로그 출력
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              languageProvider.getLanguageTransValue('Check Delete'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: defaultFontSize + 10,
                  fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: Text(
                '${languageProvider.getLanguageTransValue('Do you really want to delete the file/folder?')}\n'
                '[${startTextCtrl.text} ~ ${endTextCtrl.text}]',
                style: TextStyle(fontSize: defaultFontSize + 4),
              ),
            ),
            actions: [
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(languageProvider.getLanguageTransValue('Cancel'),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              /// ### 삭제 2차 확인 버튼
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: () async {
                    for(int i = startIndex; i <= endIndex; i++){
                      FileCtrl.deleteFolder(deleteSubFolder[i]);
                    }
                    await hotpadCtrl.updateStorageUsage();

                    setState(() {
                      startTextCtrl.text = '';
                      endTextCtrl.text = '';

                      deleteSubFolder.clear();
                      deleteSubFolder = FileCtrl.searchSubFolder();
                      deleteSubFolder.removeWhere((value) => value == DateFormat('yyyyMM').format(DateTime.now()));

                      Navigator.of(context).pop();
                    });
                    showDeleteMsg(setState, "The file/folder has been deleted.");
                  },
                  child: Text(
                    languageProvider.getLanguageTransValue('OK'),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
    /// ### 삭제 항목 선택 다이얼로그 출력
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                languageProvider.getLanguageTransValue('Delete Internal Data'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: defaultFontSize + 10,
                    fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width / 3,
                height: MediaQuery.of(context).size.height / 3 + 20,
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    /// ### 삭제 시작 항목
                    SizedBox(
                      width: 300,
                      child: Text(languageProvider.getLanguageTransValue('Delete start item'),
                        style: TextStyle(
                            fontSize: defaultFontSize + 4,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 10),
                    DropdownMenu(
                      width: 300,
                      onSelected: (value) {
                        startTextCtrl.text = value!;
                        checkItemRange(setState);
                      },
                      controller: startTextCtrl,
                      dropdownMenuEntries: deleteSubFolder
                        .map((String value) => DropdownMenuEntry<String>(value: value, label: value))
                        .toList(),
                      hintText: languageProvider.getLanguageTransValue('select...'),
                    ),
                    SizedBox(height: 30),
                    /// ### 삭제 마지막 항목
                    SizedBox(
                      width: 300,
                      child: Text(languageProvider.getLanguageTransValue('Delete last item'),
                        style: TextStyle(
                            fontSize: defaultFontSize + 4,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 10),
                    DropdownMenu(
                      width: 300,
                      onSelected: (value) {
                        endTextCtrl.text = value!;
                        checkItemRange(setState);
                      },
                      controller: endTextCtrl,
                      dropdownMenuEntries: deleteSubFolder
                        .map((String value) => DropdownMenuEntry<String>(value: value, label: value))
                        .toList(),
                      hintText:
                          languageProvider.getLanguageTransValue('select...'),
                    ),
                    SizedBox(height: 10),
                    Text(deleteMsg,
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              actions: [
                SizedBox(
                  width: 180,
                  /// ### 최대 선택 버튼
                  child: ElevatedButton(
                    onPressed: () { maxItemRange(setState); },
                    child: Text(languageProvider.getLanguageTransValue('Select Maximum'),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  /// ### 삭제 1차 확인 버튼
                  child: ElevatedButton(
                    onPressed: () {
                      if ((startTextCtrl.text != '') && (endTextCtrl.text != '')) {
                        runDelete(setState);
                      } else {
                        showDeleteMsg(setState, "There are no selected items");
                      }
                    },
                    child: Text(languageProvider.getLanguageTransValue('OK'),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_){
      setState(() {});
    });
  }
  /*****************************************************************************
   *          선택된 항목의 데이터를 USB로 복사를 제어하는 함수
   *****************************************************************************////
  Future<bool> _copyDataToUsb(String startPath, String endPath, String usbPath) async{
    List<String> subFolderList = FileCtrl.searchSubFolder();
    int totalFileCount = 0;

    fileCount = 0;
    List<List<String>> usbFolderList = [];
    List<List<File>> alarmFiles = [];
    List<List<File>> graphFiles = [];
    List<List<File>> logFiles = [];
    List<List<File>> screenShotsFiles = [];

    totalFileCount = await getFolderFileList(
      subFolderList,
      startPath,
      endPath,
      alarmFiles,
      graphFiles,
      logFiles,
      screenShotsFiles);

    if(totalFileCount >= 0){
      await _createUSBFolder(subFolderList, startPath, endPath, usbFolderList);
      await Future.delayed(const Duration(milliseconds: 200));

      // screenShots Files에 파일을 usbFolderList에 복사
      for (int i = 0; i < screenShotsFiles.length; i++) {
        for (int j = 0; j < screenShotsFiles[i].length; j++) {
          File sourceFile = screenShotsFiles[i][j];
          String usbFolderPath = usbFolderList[i][3]; // screenShotsFolder path
          String destinationPath = '$usbFolderPath/${sourceFile.uri.pathSegments.last}';
          await sourceFile.copy(destinationPath);
          // await Future.delayed(const Duration(milliseconds: 10));
          fileCount++;

          // Copy Progress 동작
          setState(() {
            copyProgressValue = fileCount / totalFileCount;
          });
        }
      }
      // Alarm Files에 .db to .csv 변환하여 usbFolderList에 복사
      await _copyFilesToUsb(alarmFiles, usbFolderList, 0, totalFileCount, _convertAlarmDbToCsv);
      // Graph Files에 .db to .csv 변환하여 usbFolderList에 복사
      await _copyFilesToUsb(graphFiles, usbFolderList, 1, totalFileCount, _convertGraphDbToCsv);
      // Log Files에 .db to .csv 변환하여 usbFolderList에 복사
      await _copyFilesToUsb(logFiles, usbFolderList, 2, totalFileCount, _convertLogDbToCsv);
    }
    else{
      return false;
    }
    return true;
  }
  /*****************************************************************************
   *          DB를 CSV로 변환된 파일을 USB에 저장하는 함수
   *****************************************************************************////
  Future<void> _copyFilesToUsb(
      List<List<File>> fileGroups,
      List<List<String>> usbFolderList,
      int usbFolderIndex,
      int totalFileCount,
      Future<String> Function(File) convertToCsv) async {

    for (int i = 0; i < fileGroups.length; i++) {
      for (int j = 0; j < fileGroups[i].length; j++) {
        File dbFile = fileGroups[i][j];
        String csvData = await convertToCsv(dbFile);
        String usbFolderPath = usbFolderList[i][usbFolderIndex];
        String csvFileName = '${dbFile.uri.pathSegments.last.split('.').first}.csv';
        String destinationPath = '$usbFolderPath/$csvFileName';
        File csvFile = File(destinationPath);

        await csvFile.writeAsString(csvData);
        debugPrint('###### Copy USB Data');

        fileCount++;

        // Copy Progress 동작
        setState(() {
          copyProgressValue = fileCount / totalFileCount;
        });
      }
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

    debugPrint('###### Create USB Folder List');
    for (var folderList in outFolderList) {
      for(var list in folderList){
        debugPrint('###### ${list.toString()}');
      }
    }
  }
  /*****************************************************************************
   *          USB메모리 내 동일한 폴더 삭제 함수
   *****************************************************************************////
  Future<void> deleteDirectoryRecursive(Directory dir) async {
    if (await dir.exists()) {
      try {
        final contents = dir.list(recursive: true);
        await for (var entity in contents) {
          try {
            if (entity is File) {
              await entity.delete();
            } else if (entity is Directory) {
              await deleteDirectoryRecursive(entity);
            }
          } catch (e) {
            debugPrint('###### $e');
          }
        }
        await dir.delete();
        debugPrint('###### Directory deleted: ${dir.path}');
      } catch (e) {
        debugPrint('###### $e');
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
    // DB 파일 존재 여부 확인
    if (dbFile.existsSync()) {
      Database db = await openDatabase(dbFile.path);
      try {
        List<Map<String, dynamic>> result = await db.query(tableName);
        for (Map<String, dynamic> row in result) {
          List<String> values = columns.map((col) => '${row[col]}').toList();
          csvData += '${values.join(',')}\n';
        }
      }
      catch (e) {
        debugPrint('###### $e');
        return '';
      }
      finally {
        await db.close();
      }
    }
    return csvData;
  }
}

