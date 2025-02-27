import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart'; // 플랫폼 채널 사용을 위해 추가
import '../devices/hotpad_ctrl.dart';
import '../devices/file_ctrl.dart';
import '../devices/usb_copy_ctrl.dart';
import '../providers/language_provider.dart';
import '../constant/user_style.dart';
import '../devices/logger.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  BackupPageState createState() => BackupPageState();
}

class BackupPageState extends State<BackupPage> {
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
      Logger.msg("${e.message}", tag: "ERROR");
    }
  }
  /***********************************************************************
   *          USB 안전 제거 함수
   ***********************************************************************////
  Future<void> _ejectUSB() async {
    try {
      final String result = await platform.invokeMethod('ejectUSB');
      Logger.msg(result);
      setState(() {
        isUSBConnect = false;
        usbProgressValue = 0;
        usbPath = '';
      });
    } on PlatformException catch (e) {
      Logger.msg("${e.message}", tag: 'ERROR');
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

    final List<DropdownMenuEntry<String>> startItems =
      subFolderList.map((String value) =>
      DropdownMenuEntry<String>(value: value, label: value))
      .toList();

    final List<DropdownMenuEntry<String>> endItems =
      subFolderList.map((String value) =>
      DropdownMenuEntry<String>(value: value, label: value))
      .toList();
    final TextEditingController startTextCtrl = TextEditingController();
    final TextEditingController endTextCtrl = TextEditingController();

    startTextCtrl.text = selectedStartItem;
    endTextCtrl.text = selectedEndItem;

    const double textSize = (defaultFontSize + 6);

    final usbCopyCtrlProvider = Provider.of<UsbCopyCtrl>(context, listen:false);

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
                    builder: (context, hotpadCtrlProvider, _) {
                      return Text(
                        '${languageProvider.getLanguageTransValue('Total')} : ${numberFormat.format(hotpadCtrlProvider.totalStorage.round())}MB'
                            ' / ${languageProvider.getLanguageTransValue('Usage')} : ${numberFormat.format(hotpadCtrlProvider.usedStorage.round())}MB'
                            ' / ${languageProvider.getLanguageTransValue('Remain')} : ${numberFormat.format((hotpadCtrlProvider.totalStorage - hotpadCtrlProvider.usedStorage).round())}MB',
                        style: TextStyle(color: Colors.black,fontSize: (textSize - 4)),
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
                    style: TextStyle(color: Colors.black,fontSize: (textSize - 4)),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Consumer<HotpadCtrl>(
            builder: (context, hotpadCtrlProvider, _) {
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
                          value: hotpadCtrlProvider.storageProgressValue,
                          backgroundColor: Colors.white,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006400)),
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            '${(hotpadCtrlProvider.storageProgressValue * 100).toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold),
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
                            style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold),
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
              border: Border.all(color: Colors.black, width: 1),
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
                        style: TextStyle(color: isUSBConnect ? Colors.black : Colors.black45,
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
                        Consumer<UsbCopyCtrl>(
                          builder: (context, usbCopyCtrlProvider, child){
                            return Stack(
                              children: [
                                SizedBox(
                                  width: halfWidth,
                                  height: 30,
                                  child: LinearProgressIndicator(
                                    value: usbCopyCtrlProvider.copyProgressValue,
                                    backgroundColor: Colors.white,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006400)),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Center(
                                    child: Text('${(usbCopyCtrlProvider.copyProgressValue * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: (textSize - 4),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
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
                      fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                          if (states.contains(WidgetState.disabled)) {
                            return Colors.grey;
                          }
                          return Colors.white;
                        }),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      side: const BorderSide(color: Colors.black,width: 1),
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
                          ? () async{
                          if((selectedStartItem == '') || (selectedEndItem == '')){
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(languageProvider.getLanguageTransValue('There are no selected items'),
                                  textAlign: TextAlign.center),
                              duration: Duration(seconds: 3),
                            ));
                          }
                          else{
                            if(usbFreeStorage < (selectedSize + 10)){
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(languageProvider.getLanguageTransValue('The USB storage has insufficient capacity.'),
                                      textAlign: TextAlign.center),
                                  duration: Duration(seconds: 3),
                                ));
                            }
                            else{
                              usbCopyCtrlProvider.startUsbCopy(
                                  selectedStartItem,
                                  selectedEndItem,
                                  usbPath,
                                  isEjectCheckBox,
                                  _ejectUSB);
                            }
                          }
                        }
                        : null,
                      style: btnStyle1,
                      child: Text(languageProvider.getLanguageTransValue('Copy to USB'),
                        style: TextStyle(color: isUSBConnect ? Colors.black : Colors.black45,
                          fontWeight: FontWeight.bold,
                          fontSize: (textSize - 4),
                        ),
                      ),
                    ),
                    SizedBox(width: 55),
                    /// ### USB 안전 제거 Button
                    ElevatedButton(
                      onPressed: isUSBConnect
                          ? (isEjectCheckBox
                          ? null
                          : () async{
                              await _ejectUSB();
                              usbCopyCtrlProvider.copyProgressValue = 0;
                            })
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
                onPressed: () {_intDataDelete(context, languageProvider);},
                style: btnStyle,
                child: Text(languageProvider.getLanguageTransValue('Delete Int. Data'),
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: (textSize - 4)),
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
    final hotpadCtrlProvider = Provider.of<HotpadCtrl>(context, listen: false);

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
              style: TextStyle(fontSize: defaultFontSize + 10, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: Text(
                '${languageProvider.getLanguageTransValue('Do you really want to delete the file/folder?')}\n'
                '[${startTextCtrl.text} ~ ${endTextCtrl.text}]',
                style: TextStyle(fontSize: defaultFontSize + 4),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {Navigator.of(context).pop();},
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.deepPurpleAccent),
                  fixedSize: WidgetStateProperty.all<Size>(Size.fromWidth(120)),
                ),
                child: Text(
                  languageProvider.getLanguageTransValue('Cancel'),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              /// ### 삭제 2차 확인 버튼
              ElevatedButton(
                onPressed: () async {
                  for(int i = startIndex; i <= endIndex; i++){
                    FileCtrl.deleteFolder(deleteSubFolder[i]);
                  }
                  await hotpadCtrlProvider.updateStorageUsage();

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
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.deepPurpleAccent),
                  fixedSize: WidgetStateProperty.all<Size>(Size.fromWidth(120)),
                ),
                child: Text(languageProvider.getLanguageTransValue('OK'),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              title: Text(languageProvider.getLanguageTransValue('Delete Internal Data'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: defaultFontSize + 10, fontWeight: FontWeight.bold)),
              content: SizedBox(
                // width: MediaQuery.of(context).size.width / 2,
                height: MediaQuery.of(context).size.height / 3 + 20,
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    /// ### 삭제 시작 항목
                    SizedBox(
                      width: 300,
                      child: Text(languageProvider.getLanguageTransValue('Delete start item'),
                        style: TextStyle(fontSize: defaultFontSize + 4, fontWeight: FontWeight.bold)),
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
                        style: TextStyle(fontSize: defaultFontSize + 4, fontWeight: FontWeight.bold)),
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
                      hintText: languageProvider.getLanguageTransValue('select...'),
                    ),
                    SizedBox(height: 10),
                    Text(deleteMsg, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              actions: [
                /// ### 최대 선택 버튼
                ElevatedButton(
                  onPressed: () { maxItemRange(setState); },
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.deepPurpleAccent),
                    fixedSize: WidgetStateProperty.all<Size>(Size.fromWidth(180)),
                  ),
                  child: Text(languageProvider.getLanguageTransValue('Select Maximum'),
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.deepPurpleAccent),
                    fixedSize: WidgetStateProperty.all<Size>(Size.fromWidth(120)),
                  ),
                  child: Text(languageProvider.getLanguageTransValue('Cancel'),
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                /// ### 삭제 1차 확인 버튼
                ElevatedButton(
                  onPressed: () {
                    if ((startTextCtrl.text != '') && (endTextCtrl.text != '')) {
                      runDelete(setState);
                    } else {
                      showDeleteMsg(setState, "There are no selected items");
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.deepPurpleAccent),
                    fixedSize: WidgetStateProperty.all<Size>(Size.fromWidth(120)),
                  ),
                  child: Text(languageProvider.getLanguageTransValue('OK'),
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
}
