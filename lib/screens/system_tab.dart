import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constant/user_style.dart';
import '../devices/config_file_ctrl.dart';
import '../providers/language_provider.dart';
import '../devices/hotpad_ctrl.dart';

class SystemTab extends StatefulWidget {
  final bool isAdmin;
  const SystemTab({super.key, required this.isAdmin});

  @override
  State<SystemTab> createState() => _SystemTabState();
}

class _SystemTabState extends State<SystemTab> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final List<TextEditingController> _textEditCtrl =
      List.generate(3, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(3, (_) => FocusNode());
  final List<dynamic> _configValue = List<dynamic>.filled(3, null, growable: false);
  Timer? _timer;

  String _strSerialNo = '';
  String _strMAC = '';
  String _strIPAddress = '';
  String _strSWVer = '';
  String _strOSVer = '';
  String _strACFrequency = '';

  static const platform = MethodChannel('system_info');

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // 키보드 상태 감지를 위해 observer 등록
    WidgetsBinding.instance.addObserver(this);

    // 저장된 설정 값을 _configValue에 저장
    _configValue[0] = ConfigFileCtrl.deviceConfigNumber;
    _configValue[1] = ConfigFileCtrl.deviceConfigFANStartTemp;
    _configValue[2] = ConfigFileCtrl.deviceConfigFANDeltaTemp;

    // TextField와 FocusNode에 Listener 추가
    for (var i = 0; i < _textEditCtrl.length; i++) {
      _textEditCtrl[i].addListener(() {
        _updateConfig(i, _textEditCtrl[i].text);
      });
      _focusNodes[i].addListener(() {
        if (!_focusNodes[i].hasFocus) {
          _onFocusLost(i);
        }
      });

      if ((i == 1) || (i == 2)) {
        _textEditCtrl[i].text = _configValue[i].toStringAsFixed(1);
      } else {
        _textEditCtrl[i].text = _configValue[i].toString();
      }
    }

    _strSerialNo = '001';
    _strMAC = '-';
    _strIPAddress = '0.0.0.0';
    _strSWVer = swVersion;
    _strOSVer = '-';
    _strACFrequency = 'AC Frequency : 60 Hz';

    _initializeNetworkInfo();
  }

  @override
  void dispose(){
    // Timer 해제
    _timer?.cancel();
    super.dispose();
  }

  /***********************************************************************
   *          네트워크 정보와 OS 버전을 초기화하는 함수
   ***********************************************************************////
  Future<void> _initializeNetworkInfo() async {
    await _getNetworkInfo();
    await _getOSVersion();
  }

  /***********************************************************************
   *          OS 버전을 가져오는 함수
   ***********************************************************************////
  Future<void> _getOSVersion() async {
    try {
      final String osVersion = await platform.invokeMethod('getOSVersion');
      setState(() {
        _strOSVer = osVersion;
      });
    } on PlatformException catch (e) {
      setState(() {
        _strOSVer = "-";
        debugPrint('OS Version Error] ${e.message}');
      });
    }
  }

  /***********************************************************************
   *          네트워크 정보를 가져오는 함수
   ***********************************************************************////
  Future<void> _getNetworkInfo() async {
    // 네트워크 인터페이스 목록을 가져옵니다.
    List<NetworkInterface> interfaces = await NetworkInterface.list();

    // eth0 인터페이스의 IP 주소를 찾습니다.
    for (var interface in interfaces) {
      if (interface.name == 'eth0') {
        for (var address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4) {
            setState(() {
              _strIPAddress = address.address;
            });
            return;
          }
        }
      }
    }
  }

  /***********************************************************************
   *          설정 값을 업데이트하는 함수
   ***********************************************************************////
  void _updateConfig(int index, String value) {
    if ((index == 1) || (index == 2)) {
      _configValue[index] = double.tryParse(value) ?? 0.0;
    } else {
      _configValue[index] = int.tryParse(value) ?? 0;
    }
  }

  /***********************************************************************
   *          Focus를 잃었을 때 호출되는 함수
   ***********************************************************************////
  void _onFocusLost(int index) async {
    String tmpStr = '';

    if ((index == 1) || (index == 2)) {
      tmpStr = _configValue[index].toStringAsFixed(1);
    } else {
      tmpStr = _configValue[index].toString();
    }
    _textEditCtrl[index].text = tmpStr;

    // 변경된 설정 값을 ConfigFileCtrl에 저장 후 SharedPreferences에 저장
    ConfigFileCtrl.deviceConfigNumber = _configValue[0];
    ConfigFileCtrl.deviceConfigFANStartTemp = _configValue[1];
    ConfigFileCtrl.deviceConfigFANDeltaTemp = _configValue[2];

    await ConfigFileCtrl.setDeviceConfigData();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final TextStyle textStyle = TextStyle(
      fontSize: defaultFontSize,
      fontWeight: FontWeight.bold,
    );
    final ButtonStyle btnStyle = ElevatedButton.styleFrom(
      foregroundColor: Colors.black,
      minimumSize: Size(250, 45),
      // 텍스트 색상 설정
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
    );
    final languageProvider = Provider.of<LanguageProvider>(context);

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.vertical,
      child: Container(
        width: 1024,
        height: (screenHeight - barHeight * 2 - tabBarHeight),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: (ConfigFileCtrl.deviceConfigLanguage == 'Kor')
                ? AssetImage(setupSystemPathKor)
                : AssetImage(setupSystemPath),
            fit: BoxFit.cover,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                /*******************************************
                 *      Controller Information
                 *******************************************/
                SizedBox(height: 95),
                Row(
                  children: [
                    SizedBox(width: 185),

                    /// ### Controller No.
                    _setPositionTextField(index: 0, width: 140, maxRange: 9999),
                  ],
                ),
                SizedBox(height: 17),
                Row(
                  children: [
                    SizedBox(width: 185),

                    /// ### Serial No.
                    Text(_strSerialNo,
                        style: textStyle, textAlign: TextAlign.center),
                  ],
                ),
                SizedBox(height: 22),
                Row(
                  children: [
                    SizedBox(width: 185),

                    /// ### MAC
                    Text(_strMAC,
                        style: textStyle, textAlign: TextAlign.center),
                  ],
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    SizedBox(width: 185),

                    /// ### IP Address
                    Text(_strIPAddress,
                        style: textStyle, textAlign: TextAlign.center),
                  ],
                ),
                /*******************************************
                 *      Version Information
                 *******************************************/
                SizedBox(height: 93),
                Row(
                  children: [
                    SizedBox(width: 185),

                    /// ### FW Version
                    Consumer<HotpadCtrl>(
                      builder: (context, hotpadCtrl, _){
                        return Text(hotpadCtrl.serialCtrl.rxPackage.fwVer,
                            style: textStyle, textAlign: TextAlign.center);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    SizedBox(width: 185),

                    /// ### SW Version
                    Text(_strSWVer,
                        style: textStyle, textAlign: TextAlign.center),
                  ],
                ),
                SizedBox(height: 90),
                Row(
                  children: [
                    SizedBox(width: 60),

                    /// ### AC Frequency
                    Text(_strACFrequency,
                        style: textStyle, textAlign: TextAlign.center),
                  ],
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                /*******************************************
                 *      OS Information
                 *******************************************/
                SizedBox(height: 175),
                Row(
                  children: [
                    SizedBox(width: 135),

                    /// ### OS Version
                    Text(_strOSVer,
                        style: textStyle, textAlign: TextAlign.center),
                  ],
                ),
                /*******************************************
                 *      Cooling Pan Control Settings
                 *******************************************/
                SizedBox(height: 141),
                Row(
                  children: [
                    SizedBox(width: 230),

                    /// ### Fan Start Temp.
                    _setPositionTextField(index: 1, width: 70, maxRange: 999),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(width: 230),

                    /// ### Fan Start Temp.
                    _setPositionTextField(index: 2, width: 70, maxRange: 999),
                  ],
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                /*******************************************
                 *            Etc Buttons
                 *******************************************/
                SizedBox(height: 350),
                Row(
                  children: [
                    SizedBox(width: 85),

                    /// ### Change Password Button.
                    ElevatedButton(
                      onPressed: () => _showChangePasswordDialog(context),
                      style: btnStyle,
                      child: Text(
                        languageProvider
                            .getLanguageTransValue('Change Password'),
                        style: TextStyle(
                          fontSize: (defaultFontSize + 2),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 71),
                Row(
                  children: [
                    SizedBox(width: 132),

                    /// ### System 종료.
                    IconButton(
                      onPressed: () {
                        SystemNavigator.pop();
                      }, // 앱 종료.
                      icon: Image.asset(iconPowerPath, width: 82, height: 82),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /***********************************************************************
   *          기본 TextField를 생성하는 함수
   ***********************************************************************////
  Widget _setPositionTextField(
      {required int index,
      double width = 90,
      double height = 35,
      double maxRange = 120}) {
    return SizedBox(
      width: width,
      height: height,
      child: TextField(
        controller: _textEditCtrl[index],
        focusNode: _focusNodes[index],
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey,
        ),
        inputFormatters: [
          // FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
          LengthLimitingTextInputFormatter(4),
          _CustomRangeTextInputFormatter(max: maxRange),
        ],
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.top,
        keyboardType: TextInputType.number,
      ),
    );
  }

  /***********************************************************************
   *          비밀번호 변경 다이얼로그를 표시하는 함수
   ***********************************************************************////
  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final LanguageProvider languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    String passwordMsg = '';

    void authenticate(StateSetter setState) async {
      String currentPassword = '';
      if(widget.isAdmin){
        currentPassword = ConfigFileCtrl.deviceConfigAdminPassword;
      }
      else{
        currentPassword = ConfigFileCtrl.deviceConfigUserPassword;
      }

      if (currentPasswordController.text == currentPassword) {
        if (newPasswordController.text == confirmPasswordController.text) {
          // Perform password change
          if(widget.isAdmin){
            ConfigFileCtrl.deviceConfigAdminPassword = newPasswordController.text;
          }
          else{
            ConfigFileCtrl.deviceConfigUserPassword = newPasswordController.text;
          }
          await ConfigFileCtrl.setDeviceConfigData();
          setState(() {
            passwordMsg =
                languageProvider.getLanguageTransValue('Saving the password.');
          });
          _timer = Timer(Duration(seconds: 3), () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(); // Close the dialog after 3 seconds
            }
          });
        } else {
          // 새 비밀번호가 일치하지 않을 때의 처리
          setState(() {
            currentPasswordController.clear();
            newPasswordController.clear();
            confirmPasswordController.clear();
            passwordMsg = languageProvider
                .getLanguageTransValue('The new password does not match.');
          });
          _timer = Timer(Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                passwordMsg = ''; // Clear the message after 3 seconds
              });
            }
          });
        }
      } else {
        // 현재 비밀번호가 일치하지 않을 때의 처리
        setState(() {
          currentPasswordController.clear();
          newPasswordController.clear();
          confirmPasswordController.clear();
          passwordMsg = languageProvider
              .getLanguageTransValue('The current password does not match.');
        });
        _timer = Timer(Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              passwordMsg = ''; // Clear the message after 3 seconds
            });
          }
        });
      }
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: widget.isAdmin
                ? Text(languageProvider.getLanguageTransValue('Admin Change Password'))
                : Text(languageProvider.getLanguageTransValue('User Change Password')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    obscureText: true,
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: newPasswordController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    obscureText: true,
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: confirmPasswordController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    obscureText: true,
                    onSubmitted: (_) => authenticate(setState), // 가상 키보드의 확인 버튼을 눌렀을 때
                  ),
                  SizedBox(height: 8),
                  Text(
                    passwordMsg,
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      languageProvider.getLanguageTransValue('Cancel'),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () => authenticate(setState),
                    child: Text(
                      languageProvider.getLanguageTransValue('Change'),
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
      // 다이얼로그가 프로그래밍적으로 닫힐 때 타이머를 취소합니다.
      _timer?.cancel();
    });
  }
}

/***********************************************************************
 *          TextField에 입력된 최대값 설정 클래스
 ***********************************************************************////
class _CustomRangeTextInputFormatter extends TextInputFormatter {
  final double max;

  _CustomRangeTextInputFormatter({required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final double? value = double.tryParse(newValue.text);
    if (value == null || value > max) {
      return oldValue;
    }

    return newValue;
  }
}
