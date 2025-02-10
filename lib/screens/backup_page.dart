import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart'; // 플랫폼 채널 사용을 위해 추가
import '../providers/language_provider.dart';
import '../constant/user_style.dart';

class BackupPage extends StatefulWidget {
  final double progressStorageValue;
  final double totalStorage;
  final double usedStorage;

  const BackupPage({
    super.key,
    required this.progressStorageValue,
    required this.totalStorage,
    required this.usedStorage,
  });

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

  @override
  void initState() {
    super.initState();
    _getUSBStorageInfo();

    // USB 마운트 이벤트 처리
    platform.setMethodCallHandler((call) async {
      if (call.method == "onUSBMounted") {
        _getUSBStorageInfo();
      }
    });
  }

  Future<void> _getUSBStorageInfo() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getUSBStorageInfo');
      setState(() {
        isUSBConnect = true;
        usbTotalStorage = result[0] / (1024 * 1024); // MB 단위로 변환
        usbUsedStorage = result[1] / (1024 * 1024); // MB 단위로 변환
        usbFreeStorage = result[2] / (1024 * 1024); // MB 단위로 변환
        usbProgressValue = usbUsedStorage / usbTotalStorage;

        debugPrint("USB storage info: $usbTotalStorage / $usbUsedStorage / $usbFreeStorage");
      });
    } on PlatformException catch (e) {
      setState(() {
        isUSBConnect = false;
        usbProgressValue = 0;
      });
      debugPrint("Failed to get USB storage info: '${e.message}'.");
    }
  }

  Future<void> _ejectUSB() async {
    try {
      final String result = await platform.invokeMethod('ejectUSB');
      debugPrint(result);
      setState(() {
        isUSBConnect = false;
        usbProgressValue = 0;
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to eject USB storage: '${e.message}'.");
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
    );

    final List<DropdownMenuEntry<String>> startItems = <String>[
      '2025/01 - 100.0MB',
      '2024/12 - 0.0MB',
      '2024/11 - 0.0MB',
      '2024/10 - 0.0MB',
    ].map((String value) => DropdownMenuEntry<String>(value: value, label: value)).toList();

    final List<DropdownMenuEntry<String>> endItems = <String>[
      '2025/01 - 0.0MB',
      '2024/12 - 0.0MB',
      '2024/11 - 0.0MB',
      '2024/10 - 0.0MB',
    ].map((String value) => DropdownMenuEntry<String>(value: value, label: value)).toList();

    const double textSize = (defaultFontSize + 6);

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 40),
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
                      gtextBarColor,
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
              Container(
                width: halfWidth,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      textBarColor,
                      gtextBarColor,
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
                  child: Text(
                    '${languageProvider.getLanguageTransValue('Total')} : ${numberFormat.format(widget.totalStorage.round())}MB'
                        ' / ${languageProvider.getLanguageTransValue('Usage')} : ${numberFormat.format(widget.usedStorage.round())}MB'
                        ' / ${languageProvider.getLanguageTransValue('Remain')} : ${numberFormat.format((widget.totalStorage - widget.usedStorage).round())}MB',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: (textSize - 4),
                    ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Stack(
                children: [
                  SizedBox(
                    width: halfWidth,
                    height: 35,
                    child: LinearProgressIndicator(
                      value: widget.progressStorageValue,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006400)),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        '${(widget.progressStorageValue * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: textSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                      child: Text(
                        isUSBConnect == true
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
          ),
          SizedBox(height: 40),
          Container(
            margin: EdgeInsets.only(left: 30, right: 30),
            padding: EdgeInsets.only(left: 50, top: 20, right: 30, bottom: 20),
            width: screenWidth,
            height: 300,
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
                  // mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                      width: 200,
                      child: Text(
                        languageProvider.getLanguageTransValue('Copy start item'),
                        style: TextStyle(
                          fontSize: textSize,
                        ),
                      ),
                    ),
                    // SizedBox(width: 10),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      child: DropdownMenu(
                        width: 250,
                        initialSelection: startItems.first.value,
                        onSelected: (_) {},
                        dropdownMenuEntries: startItems,
                      ),
                    ),
                    SizedBox(width: 55),
                    ElevatedButton(
                      onPressed: isUSBConnect ? () {} : null,
                      style: btnStyle,
                      child: Text(
                        languageProvider.getLanguageTransValue('Select Maximum'),
                        style: TextStyle(
                          fontSize: (textSize - 4),
                        ),
                      ),
                    ),
                    SizedBox(width: 150),
                  ],
                ),
                SizedBox(width: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: 505),
                    Text(
                      isUSBConnect ? '${languageProvider.getLanguageTransValue('Selected')}: 1000.0MB'
                          : '${languageProvider.getLanguageTransValue('Selected')}: 0.0MB',
                      style: TextStyle(
                        fontSize: textSize,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 10),
                Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                      width: 200,
                      child:  Text(
                        languageProvider.getLanguageTransValue('Copy last item'),
                        style: TextStyle(
                          fontSize: textSize,
                        ),
                      ),
                    ),
                    // SizedBox(width: 10),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      child: DropdownMenu(
                        width: 250,
                        initialSelection: endItems.first.value,
                        onSelected: (_) {},
                        dropdownMenuEntries: endItems,
                      ),
                    ),
                    SizedBox(width: 40),
                    Checkbox(
                      value: true,
                      onChanged: (_) {},
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
                    Text(
                      languageProvider.getLanguageTransValue('Eject USB after copying is complete.'),
                      style: TextStyle(
                        fontSize: textSize,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 10),
                Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          languageProvider.getLanguageTransValue('Process Progress'),
                          style: TextStyle(
                            fontSize: (textSize - 4),
                          ),
                        ),
                        SizedBox(height: 5),
                        Stack(
                          children: [
                            SizedBox(
                              width: halfWidth,
                              height: 30,
                              child: LinearProgressIndicator(
                                value: 0,
                                backgroundColor: Colors.white,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006400)),
                              ),
                            ),
                            Positioned.fill(
                              child: Center(
                                child: Text(
                                  '0%',
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
                    SizedBox(width: 53),
                    ElevatedButton(
                      onPressed: isUSBConnect ? () {} : null,
                      style: btnStyle,
                      child: Text(
                        languageProvider.getLanguageTransValue('Copy to USB'),
                        style: TextStyle(
                          fontSize: (textSize - 4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: isUSBConnect ? () {} : null,
                style: btnStyle,
                child: Text(
                  languageProvider.getLanguageTransValue('Delete USB Data'),
                  style: TextStyle(
                    fontSize: (textSize - 4),
                  ),
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: isUSBConnect ? _ejectUSB : null,
                style: btnStyle,
                child: Text(
                  languageProvider.getLanguageTransValue('Eject USB'),
                  style: TextStyle(
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
}