import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constant/user_style.dart';
import '../providers/language_provider.dart';
import '../devices/config_file_ctrl.dart';

class CtrlVCControl extends StatefulWidget {
  const CtrlVCControl({super.key});

  @override
  State<CtrlVCControl> createState() => _CtrlVCControlState();
}

class _CtrlVCControlState extends State<CtrlVCControl> with WidgetsBindingObserver {
  final List<TextEditingController> _textEditCtrl = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final List<dynamic> _configValue = List<dynamic>.filled(4, null, growable: false);

  final ScrollController _scrollController = ScrollController();

  double acVoltApplied = 0;
  double acCurrentApplied = 0;

  @override
  void initState() {
    super.initState();
    // 키보드 상태 감지를 위해 observer 등록
    WidgetsBinding.instance.addObserver(this);

    // 저장되어 있는 설정 값을 _configValue에 저장
    _configValue[0] = acVoltApplied;
    _configValue[1] = ConfigFileCtrl.acVoltCalOffset;
    _configValue[2] = ConfigFileCtrl.acVoltCalGain;
    _configValue[3] = acCurrentApplied;

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
    }

    _textEditCtrl[0].text = '';
    _textEditCtrl[1].text = _configValue[1].toStringAsFixed(2);
    _textEditCtrl[2].text = _configValue[2].toStringAsFixed(3);
    _textEditCtrl[3].text = '';
  }
  /***********************************************************************
   *          설정 값을 업데이트하는 함수
   ***********************************************************************////
  void _updateConfig(int index, String value) {
    _configValue[index] = double.tryParse(value) ?? 0.0;
  }
  /***********************************************************************
   *          Focus를 잃었을 때 호출되는 함수
   ***********************************************************************////
  void _onFocusLost(int index) async{
    String tmpStr ='';

    if(index == 1){
      tmpStr = _configValue[index].toStringAsFixed(2);
    } else if(index == 2){
      tmpStr = _configValue[index].toStringAsFixed(3);
    } else{
      tmpStr = _configValue[index].toStringAsFixed(1);
    }

    _textEditCtrl[index].text = tmpStr;

    // 변경된 설정 값을 ConfigFileCtrl에 저장 후 SharedPreferences에 저장
    ConfigFileCtrl.acVoltCalOffset = _configValue[1];
    ConfigFileCtrl.acVoltCalGain = _configValue[2];

    await ConfigFileCtrl.setACPowerConfigData();
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
    final languageProvider = Provider.of<LanguageProvider>(context);
    // 화면의 너비를 가져오기 위해 MediaQuery를 사용
    final double screenWidth = MediaQuery.of(context).size.width;
    final double halfWidth = (screenWidth / 2) - 60;
    const double textSize = (defaultFontSize + 6);

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.vertical,
      child: Padding(
        padding: EdgeInsets.only(top: 100),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ### Voltage Calibration ###
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
                    child: Text(languageProvider.getLanguageTransValue('Voltage Calibration'),
                      style: TextStyle(color: Colors.white,fontSize: textSize),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(width: 30),
                    _rowItem(
                        name: '${languageProvider.getLanguageTransValue('Applied V')}(V)',
                        fontSize: 16,
                        child: _setPositionTextField(index: 0, width: 100, height: 40, maxRange: 999)),
                    SizedBox(width: 40),
                    _rowItem(
                      name: '${languageProvider.getLanguageTransValue('Measured V')}(V) :',
                      fontSize: 16,
                      child: _textItem(text: '214.2', width: 60),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    (ConfigFileCtrl.deviceConfigLanguage == 'Kor') ? SizedBox(width: 83) : SizedBox(width: 63),
                    _rowItem(
                        name: languageProvider.getLanguageTransValue('Offset'),
                        fontSize: 16,
                        child: _setPositionTextField(index: 1, width: 100, height: 40, maxRange: 999)),
                    SizedBox(width: 40),
                    _rowItem(
                        name: languageProvider.getLanguageTransValue('Gain'),
                        fontSize: 16,
                        child: _setPositionTextField(index: 2, width: 100, height: 40, maxRange: 999)),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(width: 5),
                    _btnTextItem(text: languageProvider.getLanguageTransValue('Add'), color: Color(0xFF7B68EE)),
                    SizedBox(width: 10),
                    _btnTextItem(text: languageProvider.getLanguageTransValue('Del'), color: Color(0xFF7B68EE)),
                    SizedBox(width: 10),
                    _btnTextItem(text: languageProvider.getLanguageTransValue('Reset'), color: Color(0xFFFF60FF)),
                    SizedBox(width: 10),
                    _btnTextItem(text: languageProvider.getLanguageTransValue('Call'), color: Color(0xFF7B68EE)),
                    SizedBox(width: 10),
                    _btnTextItem(text: languageProvider.getLanguageTransValue('Apply'), color: Color(0xFF7B68EE)),
                  ],
                ),
                SizedBox(height: 20),
                _textItem(text: languageProvider.getLanguageTransValue('Add...')),
                SizedBox(height: 20),
                _textItem(text: languageProvider.getLanguageTransValue('Add...')),
              ],
            ),
            Column(
              children: [
                /// ### Current Calibration ###
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
                      languageProvider.getLanguageTransValue('Current Calibration'),
                      style: TextStyle(color: Colors.white, fontSize: textSize),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(width: 10),
                    _rowItem(
                        name: '${languageProvider.getLanguageTransValue('Applied A')}[0.5~4.0A]',
                        fontSize: 16,
                        child: _setPositionTextField(index: 3, width: 100, height: 40, maxRange: 999)),
                    SizedBox(width: 20),
                    _rowItem(
                      name: '${languageProvider.getLanguageTransValue('Measured A')}(A) :',
                      fontSize: 16,
                      child: _textItem(text: '214.2', width: 60),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  width: halfWidth,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(),
                    color: Colors.white,
                  ),
                  child: DataTable(
                    headingRowHeight: 20,
                    horizontalMargin: 10,
                    headingRowColor: WidgetStatePropertyAll(homeHeaderColor),
                    border: TableBorder.all(color: Colors.black),
                    columns: [
                      DataColumn(
                          label: Text(languageProvider.getLanguageTransValue('CH'),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12))),
                      DataColumn(
                          label: Text('${languageProvider.getLanguageTransValue('Applied A')}(A)',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12))),
                      DataColumn(
                          label: Text('${languageProvider.getLanguageTransValue('Measured A')}(A)',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12))),
                      DataColumn(
                          label: Text(languageProvider.getLanguageTransValue('Offset'),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12))),
                      DataColumn(
                          label: Text(languageProvider.getLanguageTransValue('Gain'),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12))),
                    ],
                    rows: [],
                  ),
                ),

                SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(width: 5),
                    _btnTextItem(text: languageProvider.getLanguageTransValue('Add'), color: Color(0xFF7B68EE)),
                    SizedBox(width: 10),
                    _btnTextItem(text: languageProvider.getLanguageTransValue('Del'), color: Color(0xFF7B68EE)),
                    SizedBox(width: 10),
                    _btnTextItem(text: languageProvider.getLanguageTransValue('Reset'), color: Color(0xFFFF60FF)),
                    SizedBox(width: 10),
                    _btnTextItem(text: languageProvider.getLanguageTransValue('Call'), color: Color(0xFF7B68EE)),
                    SizedBox(width: 10),
                    _btnTextItem(text: languageProvider.getLanguageTransValue('Apply'), color: Color(0xFF7B68EE)),
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
   *          행 항목을 생성하는 함수
   ***********************************************************************////
  Widget _rowItem({
    required String name,
    required Widget child,
    double fontSize = defaultFontSize,
  }) {
    return Row(
      children: [
        Text(
          name,
          textAlign: TextAlign.end,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 10),
        child,
      ],
    );
  }
  /***********************************************************************
   *          TextField를 생성하는 함수
   ***********************************************************************////
  Widget _setPositionTextField(
      {required int index,
      bool enable = true,
      double width = 70,
      double height = 30,
      double maxRange = 120}) {
    return SizedBox(
      width: width,
      height: height,
      child: TextField(
        controller: _textEditCtrl[index],
        focusNode: _focusNodes[index],
        enabled: enable,
        enableInteractiveSelection: enable,
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
          filled: true,
          fillColor: Colors.white,
        ),
        inputFormatters: [
          LengthLimitingTextInputFormatter(5),
          _CustomRangeTextInputFormatter(max: maxRange),
        ],
        style: TextStyle(
          fontSize: defaultFontSize,
          color: enable ? Colors.black : homeHeaderColor,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.top,
        keyboardType: TextInputType.number,
      ),
    );
  }
  /***********************************************************************
   *          사용자 TextItem을 생성하는 함수
   ***********************************************************************////
  Widget _textItem({
    required String text,
    double size = defaultFontSize,
    double width = 100,
    double height = 30,
  }) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      child: Text(text,
        style: TextStyle(fontSize: size, fontWeight: FontWeight.bold),
      ),
    );
  }
  /***********************************************************************
   *          사용자 BtnTextItem을 생성하는 함수
   ***********************************************************************////
  Widget _btnTextItem({
    required String text,
    required Color color,
    double width = 80,
  }) {
    return SizedBox(
      width: width,
      child: TextButton(
        onPressed: () {},
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(color),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.black, width: 1),
            ),
          ),
        ),
        child: Text(text,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
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
