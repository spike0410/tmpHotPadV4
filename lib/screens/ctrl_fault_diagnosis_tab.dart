import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constant/user_style.dart';
import '../devices/config_file_ctrl.dart';

class CtrlFaultDiagnosisTab extends StatefulWidget {
  const CtrlFaultDiagnosisTab({super.key});

  @override
  State<CtrlFaultDiagnosisTab> createState() => _CtrlFaultDiagnosisTabState();
}

class _CtrlFaultDiagnosisTabState extends State<CtrlFaultDiagnosisTab> with WidgetsBindingObserver {
  final List<TextEditingController> _textEditCtrl = List.generate(25, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(25, (_) => FocusNode());
  final List<dynamic> _configValue = List<dynamic>.filled(25, null, growable: false);

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // 키보드 상태 감지를 위해 observer 등록
    WidgetsBinding.instance.addObserver(this);

    // 저장되어 있는 설정 값을 _configValue에 저장
    _configValue[0] = ConfigFileCtrl.acVoltLow;
    _configValue[1] = ConfigFileCtrl.acVoltHigh;
    _configValue[2] = ConfigFileCtrl.acCurrentLow;
    _configValue[3] = ConfigFileCtrl.acCurrentHigh;
    _configValue[4] = ConfigFileCtrl.dcVoltLow;
    _configValue[5] = ConfigFileCtrl.dcVoltHigh;
    _configValue[6] = ConfigFileCtrl.dcCurrentHigh;
    _configValue[7] = ConfigFileCtrl.intTemp;

    _configValue[8] = ConfigFileCtrl.pu15Rising1stDelay;
    _configValue[9] = ConfigFileCtrl.pu15Rising1stDeltaTemp;
    _configValue[10] = ConfigFileCtrl.pu15RisingStopDelay;
    _configValue[11] = ConfigFileCtrl.pu15RisingRampTime;
    _configValue[12] = ConfigFileCtrl.pu45Rising1stDelay;
    _configValue[13] = ConfigFileCtrl.pu45Rising1stDeltaTemp;
    _configValue[14] = ConfigFileCtrl.pu45Rising2ndDelay;
    _configValue[15] = ConfigFileCtrl.pu45Rising2ndDeltaTemp;
    _configValue[16] = ConfigFileCtrl.pu45RisingStopDelay;

    _configValue[17] = ConfigFileCtrl.pu15Over1stDelay;
    _configValue[18] = ConfigFileCtrl.pu15Over1stDeltaTemp;
    _configValue[19] = ConfigFileCtrl.pu15OverStopDelay;
    _configValue[20] = ConfigFileCtrl.pu45Over1stDelay;
    _configValue[21] = ConfigFileCtrl.pu45Over1stDeltaTemp;
    _configValue[22] = ConfigFileCtrl.pu45Over2ndDelay;
    _configValue[23] = ConfigFileCtrl.pu45Over2ndDeltaTemp;
    _configValue[24] = ConfigFileCtrl.pu45OverStopDelay;

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
      if((i == 0) || (i == 1) || (i == 4) || (i == 5) || (i == 6) || (i == 7) || (i == 9)
          || (i == 13) || (i == 15) || (i == 18) || (i == 21) || (i == 23)){
        _textEditCtrl[i].text = _configValue[i].toStringAsFixed(1);
      } else if((i == 2) || (i == 3)) {
        _textEditCtrl[i].text = _configValue[i].toStringAsFixed(2);
      } else{
        _textEditCtrl[i].text = _configValue[i].toString();
      }
    }
  }
  /***********************************************************************
   *          설정 값을 업데이트하는 함수
   ***********************************************************************////
  void _updateConfig(int index, String value) {
    if((index == 0) || (index == 1) || (index == 2) || (index == 3) || (index == 4) || (index == 5) || (index == 6)
        || (index == 7) || (index == 9) || (index == 13) || (index == 15) || (index == 18) || (index == 21)
        || (index == 23)){
      _configValue[index] = double.tryParse(value) ?? 0.0;
    } else{
      _configValue[index] = int.tryParse(value) ?? 0;
    }
  }
  /***********************************************************************
   *          Focus를 잃었을 때 호출되는 함수
   ***********************************************************************////
  void _onFocusLost(int index) async{
    String tmpStr ='';

    if((index == 0) || (index == 1) || (index == 4) || (index == 5) || (index == 6) || (index == 7) || (index == 9)
        || (index == 13) || (index == 15) || (index == 18) || (index == 21) || (index == 23)){
      tmpStr = _configValue[index].toStringAsFixed(1);
    } else if((index == 2) || (index == 3)) {
      tmpStr = _configValue[index].toStringAsFixed(2);
    } else{
      tmpStr = _configValue[index].toString();
    }
    _textEditCtrl[index].text = tmpStr;

    // 변경된 설정 값을 ConfigFileCtrl에 저장 후 SharedPreferences에 저장
    ConfigFileCtrl.acVoltLow = _configValue[0];
    ConfigFileCtrl.acVoltHigh = _configValue[1];
    ConfigFileCtrl.acCurrentLow = _configValue[2];
    ConfigFileCtrl.acCurrentHigh = _configValue[3];
    ConfigFileCtrl.dcVoltLow = _configValue[4];
    ConfigFileCtrl.dcVoltHigh = _configValue[5];
    ConfigFileCtrl.dcCurrentHigh = _configValue[6];
    ConfigFileCtrl.intTemp = _configValue[7];

    ConfigFileCtrl.pu15Rising1stDelay = _configValue[8];
    ConfigFileCtrl.pu15Rising1stDeltaTemp = _configValue[9];
    ConfigFileCtrl.pu15RisingStopDelay = _configValue[10];
    ConfigFileCtrl.pu15RisingRampTime = _configValue[11];
    ConfigFileCtrl.pu45Rising1stDelay = _configValue[12];
    ConfigFileCtrl.pu45Rising1stDeltaTemp = _configValue[13];
    ConfigFileCtrl.pu45Rising2ndDelay = _configValue[14];
    ConfigFileCtrl.pu45Rising2ndDeltaTemp = _configValue[15];
    ConfigFileCtrl.pu45RisingStopDelay = _configValue[16];

    ConfigFileCtrl.pu15Over1stDelay = _configValue[17];
    ConfigFileCtrl.pu15Over1stDeltaTemp = _configValue[18];
    ConfigFileCtrl.pu15OverStopDelay = _configValue[19];
    ConfigFileCtrl.pu45Over1stDelay = _configValue[20];
    ConfigFileCtrl.pu45Over1stDeltaTemp = _configValue[21];
    ConfigFileCtrl.pu45Over2ndDelay = _configValue[22];
    ConfigFileCtrl.pu45Over2ndDeltaTemp = _configValue[23];
    ConfigFileCtrl.pu45OverStopDelay = _configValue[24];

    await ConfigFileCtrl.setDiagnosisConfigData();
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

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.vertical,
      child: Container(
        width: 1024,
        height: (screenHeight - barHeight * 2 - tabBarHeight),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: (ConfigFileCtrl.deviceConfigLanguage == 'Kor') ? AssetImage(ctrlFaultPathKor) : AssetImage(ctrlFaultPath),
            fit: BoxFit.cover,
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 243),
            Column(
              children: [
                /// ### AC Heater Voltage(RMS) ###
                SizedBox(height: 84),
                _setPositionTextField(index: 0, maxRange: 999),
                SizedBox(height: 6),
                _setPositionTextField(index: 1, maxRange: 999),
                /// ### Heater Current(RMS) ###
                SizedBox(height: 90),
                _setPositionTextField(index: 2, maxRange: 999),
                SizedBox(height: 6),
                _setPositionTextField(index: 3, maxRange: 999),
                /// ### Internal Power/Temp. ###
                SizedBox(height: 90),
                _setPositionTextField(index: 4, maxRange: 999),
                SizedBox(height: 6),
                _setPositionTextField(index: 5, maxRange: 999),
                SizedBox(height: 6),
                _setPositionTextField(index: 6, maxRange: 999),
                SizedBox(height: 6),
                _setPositionTextField(index: 7, maxRange: 999),
              ],
            ),
            SizedBox(width: 253),
            Column(
              children: [
                /// ### PU15 Temp.Rising Delay ###
                SizedBox(height: 84),
                _setPositionTextField(index: 8, maxRange: 999),
                SizedBox(height: 6),
                _setPositionTextField(index: 9, maxRange: 999),
                SizedBox(height: 6),
                _setPositionTextField(index: 10, maxRange: 999),
                SizedBox(height: 6),
                _setPositionTextField(index: 11, maxRange: 999),
                /// ### PU45 Temp.Rising Delay ###
                SizedBox(height: 105),
                _setPositionTextField(index: 12, maxRange: 999),
                SizedBox(height: 6),
                _setPositionTextField(index: 13, maxRange: 999),
                SizedBox(height: 6),
                _setPositionTextField(index: 14, maxRange: 999),
                SizedBox(height: 6),
                _setPositionTextField(index: 15, maxRange: 999),
                SizedBox(height: 6),
                _setPositionTextField(index: 16, maxRange: 999),
              ],
            ),

            SizedBox(width: 253),
            Column(
              children: [
                /// ### PU15 Temp.Over Run ###
                SizedBox(height: 84),
                _setPositionTextField(index: 17, maxRange: 999),
                SizedBox(height: 6),
                _setPositionTextField(index: 18, maxRange: 999),
                SizedBox(height: 6),
                _setPositionTextField(index: 19, maxRange: 999),

                /// ### PU45 Temp.Over Run ###
                SizedBox(height: 141),
                _setPositionTextField(index: 20, maxRange: 999),
                SizedBox(height: 6),
                _setPositionTextField(index: 21, maxRange: 999),
                SizedBox(height: 6),
                _setPositionTextField(index: 22, maxRange: 999),
                SizedBox(height: 6),
                _setPositionTextField(index: 23, maxRange: 999),
                SizedBox(height: 6),
                _setPositionTextField(index: 24, maxRange: 999),
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
  Widget _setPositionTextField({
    required int index,
    double width = 70,
    double height = 30,
    double maxRange = 120}) {
    return SizedBox(
      width: width,
      height: height,
      child: TextField(
        controller: _textEditCtrl[index],
        focusNode: _focusNodes[index],
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
            // borderSide: BorderSide(color: Colors.black),     // <--!@# 크기 확인용
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
          ),
        ),
        inputFormatters: [
          // FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(5),
          _CustomRangeTextInputFormatter(max: maxRange),
        ],
        style: TextStyle(fontSize: defaultFontSize, color: Colors.black, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
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
  TextEditingValue formatEditUpdate(TextEditingValue oldValue,
      TextEditingValue newValue,) {
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
