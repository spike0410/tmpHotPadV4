import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constant/user_style.dart';
import '../devices/config_file_ctrl.dart';
import '../providers/language_provider.dart';
import '../providers/authentication_provider.dart';

class TempSettingsTab extends StatefulWidget {
  const TempSettingsTab({super.key});

  @override
  State<TempSettingsTab> createState() => _TempSettingsTabState();
}

class _TempSettingsTabState extends State<TempSettingsTab> with WidgetsBindingObserver {
  // 9개의 TextEditingController와 FocusNode 생성
  final List<TextEditingController> _textEditCtrl = List.generate(9, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(9, (_) => FocusNode());
  final List<dynamic> _configValue = List<dynamic>.filled(9, null, growable: false);

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 키보드 상태 감지를 위해 observer 등록
    WidgetsBinding.instance.addObserver(this);

    // 저장되어 있는 설정 값을 _configValue에 저장
    _configValue[0] = ConfigFileCtrl.preheatingTime;
    _configValue[1] = ConfigFileCtrl.pu15TargetTemp;
    _configValue[2] = ConfigFileCtrl.pu15HoldTime;
    _configValue[3] = ConfigFileCtrl.pu45Target1stTemp;
    _configValue[4] = ConfigFileCtrl.pu45Target2ndTemp;
    _configValue[5] = ConfigFileCtrl.pu45Ramp1stTime;
    _configValue[6] = ConfigFileCtrl.pu45Hold1stTime;
    _configValue[7] = ConfigFileCtrl.pu45Ramp2ndTime;
    _configValue[8] = ConfigFileCtrl.pu45Hold2ndTime;

    // TextField와 FocusLost에 Listener 추가
    for (var i = 0; i < _textEditCtrl.length; i++) {
      _textEditCtrl[i].addListener(() {
        _updateConfig(i, _textEditCtrl[i].text);
      });
      _focusNodes[i].addListener(() {
        if (!_focusNodes[i].hasFocus) {
          _onFocusLost(i);
        }
      });

      if ((i == 1) || (i == 3) || (i == 4)) {
        _textEditCtrl[i].text = _configValue[i].toStringAsFixed(1);
      } else {
        _textEditCtrl[i].text = _configValue[i].toString();
      }
    }
  }

  /***********************************************************************
   *          설정 값을 업데이트하는 함수
   ***********************************************************************////
  void _updateConfig(int index, String value) {
    if ((index == 1) || (index == 3) || (index == 4)) {
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

    if ((index == 1) || (index == 3) || (index == 4)) {
      tmpStr = _configValue[index].toStringAsFixed(1);
    } else {
      tmpStr = _configValue[index].toString();
    }
    _textEditCtrl[index].text = tmpStr;

    // 변경된 설정 값을 ConfigFileCtrl에 저장 후 SharedPreferences에 저장
    ConfigFileCtrl.preheatingTime = _configValue[0];
    ConfigFileCtrl.pu15TargetTemp = _configValue[1];
    ConfigFileCtrl.pu15HoldTime = _configValue[2];
    ConfigFileCtrl.pu45Target1stTemp = _configValue[3];
    ConfigFileCtrl.pu45Target2ndTemp = _configValue[4];
    ConfigFileCtrl.pu45Ramp1stTime = _configValue[5];
    ConfigFileCtrl.pu45Hold1stTime = _configValue[6];
    ConfigFileCtrl.pu45Ramp2ndTime = _configValue[7];
    ConfigFileCtrl.pu45Hold2ndTime = _configValue[8];

    await ConfigFileCtrl.setModeProfileConfigData();
  }

  @override
  void dispose() {
    // observer 제거
    WidgetsBinding.instance.removeObserver(this);
    // TextEditingController 해제
    for (var controller in _textEditCtrl) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final ButtonStyle btnStyle = ElevatedButton.styleFrom(
      foregroundColor: Colors.black,
      minimumSize: Size(150, 45),
      // 텍스트 색상 설정
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
    );
    final languageProvider = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthenticationProvider>(context);

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.vertical,
      child: Container(
        width: 1024,
        height: (screenHeight - barHeight * 2 - tabBarHeight),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: (ConfigFileCtrl.deviceConfigLanguage == 'Kor')
                ? AssetImage(setupTempSettingPathKor)
                : AssetImage(setupTempSettingPath),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            /************************************************
             *      PU15 Temperature Setting
             *    @ index : 0(Preheatting) 1,2(PU15)
             *    @ Caution : Fixed Position
             *************************************************/
            SizedBox(height: 65),
            Row(
              children: [
                SizedBox(width: 183),

                /// ### Temp1
                _setPositionTextField(index: 1, maxRange: 999, isEnabled: authProvider.isAuthenticated),
                SizedBox(width: 530),
                ElevatedButton(
                  onPressed: authProvider.isAuthenticated ? null : () {
                    authProvider.showPasswordPrompt(context, languageProvider, ConfigFileCtrl.deviceConfigUserPassword);
                  },
                  style: btnStyle,
                  child: Text(
                    languageProvider.getLanguageTransValue('Change Setting'),
                    style: TextStyle(
                      fontSize: (defaultFontSize + 2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 46),
            Row(
              children: [
                SizedBox(width: 856),

                /// ### Preheat Time
                _setPositionTextField(index: 0, width: 84, maxRange: 999, isEnabled: authProvider.isAuthenticated),
              ],
            ),
            SizedBox(height: 5),
            Row(
              children: [
                SizedBox(width: 495),

                /// ### Hold Time1
                _setPositionTextField(index: 2, width: 84, maxRange: 999, isEnabled: authProvider.isAuthenticated),
              ],
            ),
            /************************************************
             *      PU45 Temperature Setting
             *    @ index : 3(PU45)
             *    @ Caution : Fixed Position
             *************************************************/
            SizedBox(height: 72),
            Row(
              children: [
                SizedBox(width: 183),

                /// ### Temp2
                _setPositionTextField(index: 4, maxRange: 999, isEnabled: authProvider.isAuthenticated),
              ],
            ),
            SizedBox(height: 62),
            Row(
              children: [
                SizedBox(width: 183),

                /// ### Temp1
                _setPositionTextField(index: 3, maxRange: 999, isEnabled: authProvider.isAuthenticated),
              ],
            ),
            SizedBox(height: 95),
            Row(
              children: [
                SizedBox(width: 321),

                /// ### Step Rising1
                _setPositionTextField(index: 5, width: 80, maxRange: 999, isEnabled: authProvider.isAuthenticated),
                SizedBox(width: 86),

                /// ### Step Holding1
                _setPositionTextField(index: 6, width: 80, maxRange: 999, isEnabled: authProvider.isAuthenticated),
                SizedBox(width: 90),

                /// ### Step Rising2
                _setPositionTextField(index: 7, width: 80, maxRange: 999, isEnabled: authProvider.isAuthenticated),
                SizedBox(width: 91),

                /// ### Step Holding2
                _setPositionTextField(index: 8, width: 80, maxRange: 999, isEnabled: authProvider.isAuthenticated),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /***********************************************************************
   *          TextField를 생성하는 함수
   ***********************************************************************////
  Widget _setPositionTextField(
      {required int index,
      double width = 70,
      double height = 35,
      double maxRange = 120,
        required bool isEnabled,
      }) {
    return SizedBox(
      width: width,
      height: height,
      child: TextField(
        controller: _textEditCtrl[index],
        focusNode: _focusNodes[index],
        enabled: isEnabled,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: isEnabled ? Colors.grey[300] : Colors.grey,
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
