import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constant/user_style.dart';
import '../devices/config_file_ctrl.dart';
import '../providers/language_provider.dart';

class TempCalTab extends StatefulWidget {
  const TempCalTab({super.key});

  @override
  _TempCalTabState createState() => _TempCalTabState();
}

class _TempCalTabState extends State<TempCalTab> with WidgetsBindingObserver{
  // 채널 선택 여부를 저장하는 리스트
  final List<bool> _isChannelChecked = List<bool>.filled(10, false);
  // 스크롤 컨트롤러 생성
  final ScrollController _scrollController = ScrollController();
  // TextEditingController와 FocusNode 생성
  final List<TextEditingController> _textEditCtrl =
  List.generate(3, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(3, (_) => FocusNode());
  // 설정 값을 저장하는 리스트
  final List<dynamic> _configValue = List<dynamic>.filled(3, null, growable: false);

  String _strRefTemp = '';
  double _calProgressValue = 0;

  @override
  void initState(){
    super.initState();
    // 키보드 상태 감지를 위해 observer 등록
    WidgetsBinding.instance.addObserver(this);

    // 저장된 설정 값을 _configValue에 저장
    _configValue[0] = ConfigFileCtrl.tempCalOhm;
    _configValue[1] = ConfigFileCtrl.tempCalTime;
    _configValue[2] = ConfigFileCtrl.tempCalGain;

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
      _textEditCtrl[i].text = _configValue[i].toString();
    }

    _strRefTemp = ohmToTemp(_configValue[0]);
    _calProgressValue = 0.10;
  }

  /***********************************************************************
   *          설정 값을 업데이트하는 함수
   ***********************************************************************////
  void _updateConfig(int index, String value) {
    _configValue[index] = int.tryParse(value) ?? 0;
  }

  /***********************************************************************
   *          Focus를 잃었을 때 호출되는 함수
   ***********************************************************************////
  void _onFocusLost(int index) async{
    String tmpStr ='';

    tmpStr = _configValue[index].toString();
    _textEditCtrl[index].text = tmpStr;

    if(index == 0){
      setState(() {
        _strRefTemp = ohmToTemp(_configValue[0]);
      });
    }

    // 변경된 설정 값을 ConfigFileCtrl에 저장 후 SharedPreferences에 저장
    ConfigFileCtrl.tempCalOhm = _configValue[0];
    ConfigFileCtrl.tempCalTime = _configValue[1];
    ConfigFileCtrl.tempCalGain = _configValue[2];

    await ConfigFileCtrl.setTempCalConfigData();
  }

  /***********************************************************************
   *          저항 값을 온도로 변환하는 함수
   ***********************************************************************////
  String ohmToTemp(int resistance) {
    const double R0 = 100.0; // PT100의 0°C에서의 저항값
    const double A = 3.9083e-3;
    const double B = -5.775e-7;
    const double C = -4.183e-12; // 0°C 이하에서만 사용
    double t = 0;

    if (resistance >= R0) {
      // 0°C 이상
      t = (-A + sqrt(A * A - 4 * B * (1 - resistance / R0))) / (2 * B);
    } else {
      // 0°C 이하
      t = -200.0; // 초기 추정값
      double delta;
      do {
        final double R_t = R0 * (1 + A * t + B * t * t + C * (t - 100) * t * t);
        final double dR_dt = R0 * (A + 2 * B * t + C * (3 * t * t - 200 * t));
        delta = (resistance - R_t) / dR_dt;
        t += delta;
      } while (delta.abs() > 0.0001); // 수렴 조건
    }
    return t.toStringAsFixed(1);
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
    final ButtonStyle btnStyle = ElevatedButton.styleFrom(
      foregroundColor: Colors.black,
      minimumSize: Size(250, 45),
      // 텍스트 색상 설정
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
    );

    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.vertical,
      child: Container(
        height: (screenHeight - barHeight * 2 - tabBarHeight),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: (ConfigFileCtrl.deviceConfigLanguage == 'Kor') ? AssetImage(setupTempCalPathKor) : AssetImage(setupTempCalPath),
            fit: BoxFit.cover,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 85),
            Column(
              children: [
                SizedBox(height: 70),
                /*************************************
                 *      Calibration DataTable
                 *************************************/
                DataTable(
                  // border: TableBorder.all(color: Colors.red),    // 모양 확인용.
                  headingRowHeight: 7,
                  dataRowHeight: 48.4,
                  /// ### Header Text
                  columns: const <DataColumn>[
                    DataColumn(label: Text('')),
                    DataColumn(label: Text('')),
                    DataColumn(label: Text('')),
                  ],
                  /// ### Cell Text
                  rows: List<DataRow>.generate(totalChannel, (index) =>
                    DataRow(
                      cells: <DataCell>[
                        DataCell(
                          SizedBox(
                            width: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Checkbox(
                                  value: _isChannelChecked[index],
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _isChannelChecked[index] = value ?? false;
                                    });
                                  },
                                ),
                                Text(
                                  'CH ${(index + 1).toString().padLeft(2, '0')}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 120,
                            child: Text(
                              'Temp ${index + 1}',textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 120,
                            child: Text(
                              // 'CalValue ${index + 1}',
                              ConfigFileCtrl.tempCalData[index].toStringAsFixed(2),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            /*************************************
             *      Calibration Data Setup
             *************************************/
            Column(
              children: [
                SizedBox(height: 90),
                Row(
                  children: [
                    SizedBox(width: 155),
                    /// ### Ref.Resistance
                    _setPositionTextField(index: 0, maxRange: 9999),
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    SizedBox(width: 155),
                    /// ### Ref.temp
                    Text(
                      _strRefTemp,
                      style: TextStyle(
                        fontSize: (defaultFontSize + 4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(width: 155),
                    /// ### Cal.time
                    _setPositionTextField(index: 1),
                  ],
                ),
                SizedBox(height: 25),
                Row(
                  children: [
                    SizedBox(width: 193),
                    /// ### Gain
                    _setPositionTextField(index: 2, width: 130, maxRange: 9999),
                  ],
                ),
                SizedBox(height: 90),
                Row(
                  children: [
                    SizedBox(width: 60),
                    /// ### Calibration ProgressBar
                    Stack(
                      children: [
                        SizedBox(
                          width: 170,
                          height: 30,
                          child: LinearProgressIndicator(
                            // value: progressStorageValue,
                            value: _calProgressValue,
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E90FF)),
                          ),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: Text(
                              '${(_calProgressValue * 100).round()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 30),
                /*************************************
                 *              Button
                 *************************************/
                Row(
                  children: [
                    SizedBox(width: 60),
                    ElevatedButton(
                      onPressed: (){},      // <---!@#
                      style: btnStyle,
                      child: Text(
                        languageProvider.getLanguageTransValue('Start Calibration'),
                        style: TextStyle(
                          fontSize: (defaultFontSize + 6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(width: 60),
                    ElevatedButton(
                      onPressed: (){},      // <---!@#
                      style: btnStyle,
                      child: Text(
                        languageProvider.getLanguageTransValue('Reset Calibration'),
                        style: TextStyle(
                          fontSize: (defaultFontSize + 6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  /***********************************************************************
   *          기본 TextField를 생성하는 함수
   ***********************************************************************////
  Widget _setPositionTextField({
    required int index,
    double width = 90,
    double height = 35,
    int maxRange = 120}) {
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
          FilteringTextInputFormatter.digitsOnly,
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
  final int max;

  _CustomRangeTextInputFormatter({required this.max});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue,
      TextEditingValue newValue,) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final int? value = int.tryParse(newValue.text);
    if (value == null || value > max) {
      return oldValue;
    }

    return newValue;
  }
}
