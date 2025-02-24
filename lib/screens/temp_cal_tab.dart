import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constant/user_style.dart';
import '../devices/config_file_ctrl.dart';
import '../devices/hotpad_ctrl.dart';
import '../providers/language_provider.dart';

class TempCalTab extends StatefulWidget {
  const TempCalTab({super.key});

  @override
  _TempCalTabState createState() => _TempCalTabState();
}

class _TempCalTabState extends State<TempCalTab> with WidgetsBindingObserver {
  // 채널 선택 여부를 저장하는 리스트
  final List<bool> _isChannelChecked = List<bool>.filled(10, true);

  // 스크롤 컨트롤러 생성
  final ScrollController _scrollController = ScrollController();

  // TextEditingController와 FocusNode 생성
  final List<TextEditingController> _textEditCtrl =
      List.generate(3, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(3, (_) => FocusNode());

  // 설정 값을 저장하는 리스트
  final List<dynamic> _configValue =
      List<dynamic>.filled(3, null, growable: false);

  String _strRefTemp = '';
  double _calProgressValue = 0;

  @override
  void initState() {
    super.initState();
    // 키보드 상태 감지를 위해 observer 등록
    WidgetsBinding.instance.addObserver(this);
    final hotpadCtrlProvider = Provider.of<HotpadCtrl>(context, listen: false);

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
          _onFocusLost(i, hotpadCtrlProvider);
        }
      });
      _textEditCtrl[i].text = _configValue[i].toString();
    }

    _strRefTemp = hotpadCtrlProvider.serialCtrl.rxPackage
        .ohmToTemp(_configValue[0].toDouble())
        .toStringAsFixed(1);
    _calProgressValue = 0;
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
  void _onFocusLost(int index, HotpadCtrl hotpadCtrlProvider) async {
    String tmpStr = '';

    tmpStr = _configValue[index].toString();
    _textEditCtrl[index].text = tmpStr;

    if (index == 0) {
      setState(() {
        _strRefTemp = hotpadCtrlProvider.serialCtrl.rxPackage
            .ohmToTemp(_configValue[0].toDouble())
            .toStringAsFixed(1);
      });
    }

    // 변경된 설정 값을 ConfigFileCtrl에 저장 후 SharedPreferences에 저장
    ConfigFileCtrl.tempCalOhm = _configValue[0];
    ConfigFileCtrl.tempCalTime = _configValue[1];
    ConfigFileCtrl.tempCalGain = _configValue[2];

    await ConfigFileCtrl.setTempCalConfigData();
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
            image: (ConfigFileCtrl.deviceConfigLanguage == 'Kor')
                ? AssetImage(setupTempCalPathKor)
                : AssetImage(setupTempCalPath),
            fit: BoxFit.cover,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 85),
            Column(
              children: [
                SizedBox(height: 13),
                /*************************************
                 *      Calibration DataTable
                 *************************************/
                DataTable(
                  // border: TableBorder.all(color: Colors.red),    // 모양 확인용.
                  headingRowHeight: 65,
                  dataRowHeight: 48.4,

                  /// ### Header Text
                  columns: <DataColumn>[
                    // DataColumn(label: Text('')),
                    DataColumn(
                      label: SizedBox(
                        width: 120,
                        height: 40,
                        child: FilledButton(
                          onPressed: (){},
                          onLongPress: (){
                            setState(() {
                              for(int i = 0; i < totalChannel; i++){
                                _isChannelChecked[i] = !_isChannelChecked[i];
                              }
                            });
                          },
                          style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.transparent)),
                          child: null,
                        ),
                      ),
                    ),
                    const DataColumn(label: Text('')),
                    const DataColumn(label: Text('')),
                  ],

                  /// ### Cell Text
                  rows: List<DataRow>.generate(
                    totalChannel,
                    (index) => DataRow(
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
                        DataCell(Consumer<HotpadCtrl>(
                          builder: (context, hotpadCtrlProvider, _) {
                            return SizedBox(
                              width: 120,
                              child: Text(hotpadCtrlProvider.serialCtrl.rxPackage.rtdTemp[index],
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        )),
                        DataCell(
                          SizedBox(
                            width: 120,
                            child: Text(
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
                      onPressed: () {_runCalData();},
                      style: btnStyle,
                      child: Text(languageProvider.getLanguageTransValue('Start Calibration'),
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
                      onPressed: () {
                        _initCalData(context, languageProvider);
                      },
                      style: btnStyle,
                      child: Text(languageProvider.getLanguageTransValue('Reset Calibration'),
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
  Widget _setPositionTextField(
      {required int index,
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
  /***********************************************************************
   *          온도 교정 함수
   ***********************************************************************////
  void _runCalData() async{
    int count = 0;
    int defaultCalOhm = ConfigFileCtrl.tempCalOhm;
    List<double> tmpCalList = List.filled(totalChannel, 0.0);
    HotpadCtrl hotpadCtrlProvider = Provider.of<HotpadCtrl>(context, listen: false);
    _calProgressValue = 0;
    hotpadCtrlProvider.isIndicator = true;

    /// ### 이전 캘리브레이션 데이터 값을 초기화
    setState(() {
      for(int i = 0; i < totalChannel; i++){
        ConfigFileCtrl.tempCalData[i] = 0;
      }
    });
    await Future.delayed(Duration(seconds: 2));

    /// ### 1초 간격으로 캘리브레이션 시작
    Timer.periodic(Duration(seconds: 1), (timer){
      count++;
      setState(() {
        _calProgressValue = count.toDouble() / ConfigFileCtrl.tempCalTime.toDouble();
      });
      for(int i = 0; i < totalChannel; i++){
        if(_isChannelChecked[i] == true){
          double tmpCal = defaultCalOhm - hotpadCtrlProvider.serialCtrl.rxPackage.rtdOhm[i];
          tmpCalList[i] += tmpCal;
        }
      }

      /// ### 캘리브레이션 데이터를 적용 및 저장
      if(count == ConfigFileCtrl.tempCalTime){
        // count = ConfigFileCtrl.tempCalTime;
        timer.cancel();
        setState(() {
          for(int i = 0; i < totalChannel; i++){
            ConfigFileCtrl.tempCalData[i] = tmpCalList[i] / ConfigFileCtrl.tempCalTime;
          }
        });
        hotpadCtrlProvider.isIndicator = false;
        ConfigFileCtrl.setTempCalData();
      }
    });

  }
  /***********************************************************************
   *          온도 교정 초기화 ShowDialog 함수
   ***********************************************************************////
  Future<void> _initCalData(BuildContext context, LanguageProvider languageProvider) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            languageProvider.getLanguageTransValue('Reset Calibration'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: defaultFontSize + 10, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width / 2,
            child: Text(languageProvider.getLanguageTransValue('Are you sure you want to reset the temperature calibration values?')),
          ),
          actions: [
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.deepPurpleAccent)),
                child: Text(
                  languageProvider.getLanguageTransValue('Cancel'),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    for(int i = 0; i < totalChannel; i++){
                      ConfigFileCtrl.tempCalData[i] = 0;
                    }
                  });
                  ConfigFileCtrl.setTempCalData();
                  Navigator.of(context).pop();
                },
                style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.deepPurpleAccent)),
                child: Text(
                  languageProvider.getLanguageTransValue('OK'),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
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
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
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
