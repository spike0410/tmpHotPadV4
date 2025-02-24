import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constant/user_style.dart';
import '../devices/config_file_ctrl.dart';
import '../devices/hotpad_ctrl.dart';
import '../providers/language_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  // ScrollController, TextEditingController, FocusNode를 초기화
  final ScrollController _scrollController = ScrollController();
  final List<TextEditingController> _textEditCtrl = List.generate(totalChannel, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(totalChannel, (_) => FocusNode());

  late HotpadCtrl hotpadCtrlProvider;

  @override
  void initState() {
    super.initState();
    // 키보드 상태 감지를 위해 observer 등록
    WidgetsBinding.instance.addObserver(this);
    hotpadCtrlProvider = Provider.of<HotpadCtrl>(context, listen: false);

    // HotpadCtrl의 콜백 함수 설정.
    hotpadCtrlProvider.onPadIDTextChanged = (index, text) {
      setState(() {
        _textEditCtrl[index].text = text;
      });
    };

    // FocusNode에 Listener 추가
    for (var i = 0; i < _textEditCtrl.length; i++) {
      _focusNodes[i].addListener(() {
        if (!_focusNodes[i].hasFocus) {
          _onFocusLost(i);
        }
      });
      _textEditCtrl[i].text = hotpadCtrlProvider.getPadIDText(i);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (var controller in _textEditCtrl) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.vertical,
      padding: EdgeInsets.all(5),
      child: Column(
        children: [
          Consumer<HotpadCtrl>(
            builder: (context, hotpadCtrlProvider, _) {
              return _headerRowItem(languageProvider, hotpadCtrlProvider);
            },
          ),
          ...List.generate(
            totalChannel,
                (index) => Column(
              children: [
                SizedBox(height: 5),
                Consumer<HotpadCtrl>(
                  builder: (context, hotpadCtrlProvider, _) {
                    return _dataRowItem(
                      index: index,
                      statusCh: hotpadCtrlProvider.getChannelStatus(index),
                      strChannel: (index + 1).toString().padLeft(2, '0'),
                      currentTempValue: double.tryParse(hotpadCtrlProvider.serialCtrl.rxPackage.rtdTemp[index]) ?? 0.0,
                      setTemp: hotpadCtrlProvider.settingTempSelect(index),
                      remainTotalTimeValue: hotpadCtrlProvider.getRemainTotalTime(index),
                      remainTimeValue: hotpadCtrlProvider.getRemainTime(index),
                      textEditCtrl: _textEditCtrl[index],
                      // currentValue: double.tryParse(hotpadCtrlProvider.serialCtrl.rxPackage.padCurrent[index]) ?? 0.0,
                      currentValue: hotpadCtrlProvider.serialCtrl.rxPackage.padCurrent[index],
                      strPADOhm: hotpadCtrlProvider.serialCtrl.rxPackage.padOhm[index],
                      strPADStatus: hotpadCtrlProvider.getHeatingStatusString(languageProvider, hotpadCtrlProvider.getHeatingStatus(index)),
                      isHighlighted: hotpadCtrlProvider.getIsPU45Enable(index),
                      focusNode: _focusNodes[index],
                      languageProvider: languageProvider,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /***********************************************************************
   *          헤더 행 항목을 생성하는 함수
   ***********************************************************************////
  Widget _headerRowItem(LanguageProvider languageProvider, HotpadCtrl hotpadCtrlProvider) {
    const List<double> headerWidth = [110, 90, 90, 100, 75, 90, 90, 90, 114, 114];
    const double headerHeight = 55;

    return Row(
      children: [
        _headerCellItem(
            width: headerWidth[0],
            height: headerHeight,
            child: TextButton(
              onPressed: (){},
              onLongPress: (){
                for (int i = 0; i < totalChannel; i++) {
                  hotpadCtrlProvider.togglePU45Enable(i);
                }
              },
              child: _textDataTable(text: languageProvider.getLanguageTransValue('Channel'),
                  size: (ConfigFileCtrl.deviceConfigLanguage == 'Kor') ? (defaultFontSize + 2) : defaultFontSize,
                  fontWeight: FontWeight.bold))),
        SizedBox(width: 5),
        _headerCellItem(
            width: headerWidth[1],
            height: headerHeight,
            child: _textDataTable(
                text: languageProvider.getLanguageTransValue('Current\nTemp.[℃]'),
                size: (ConfigFileCtrl.deviceConfigLanguage == 'Kor') ? (defaultFontSize + 2) : defaultFontSize,
                fontWeight: FontWeight.bold)),
        SizedBox(width: 5),
        _headerCellItem(
            width: headerWidth[2],
            height: headerHeight,
            child: _textDataTable(
                text: languageProvider.getLanguageTransValue('Setting\nTemp.[℃]'),
                size: (ConfigFileCtrl.deviceConfigLanguage == 'Kor') ? (defaultFontSize + 2) : defaultFontSize,
                fontWeight: FontWeight.bold)),
        SizedBox(width: 5),
        _headerCellItem(
            width: headerWidth[3],
            height: headerHeight,
            child: _textDataTable(
                text: languageProvider.getLanguageTransValue('Remain Time\n[min:sec]'),
                size: (ConfigFileCtrl.deviceConfigLanguage == 'Kor') ? (defaultFontSize + 2) : 12,
                fontWeight: FontWeight.bold)),
        SizedBox(width: 5),
        _headerCellItem(
            width: headerWidth[4],
            height: headerHeight,
            child: TextButton(
                onPressed: (){},
                onLongPress: (){
                  for(int i = 0; i < _textEditCtrl.length; i++){
                    _textEditCtrl[i].text = 'TEST';
                    hotpadCtrlProvider.setPadID(i, _textEditCtrl[i].text);
                  }
                },
                child: _textDataTable(text: languageProvider.getLanguageTransValue('PAD\nID'),
                    size: (ConfigFileCtrl.deviceConfigLanguage == 'Kor') ? (defaultFontSize + 1) : defaultFontSize,
                    fontWeight: FontWeight.bold))),
        SizedBox(width: 5),
        _headerCellItem(
            width: headerWidth[5],
            height: headerHeight,
            child: _textDataTable(
                text: languageProvider.getLanguageTransValue('PAD\nCurrent[A]'),
                size: (ConfigFileCtrl.deviceConfigLanguage == 'Kor') ? (defaultFontSize + 2) : defaultFontSize,
                fontWeight: FontWeight.bold)),
        SizedBox(width: 5),
        _headerCellItem(
            width: headerWidth[6],
            height: headerHeight,
            child: _textDataTable(
                text: languageProvider.getLanguageTransValue('PAD\nResist.[Ω]'),
                size: (ConfigFileCtrl.deviceConfigLanguage == 'Kor') ? (defaultFontSize + 2) : defaultFontSize,
                fontWeight: FontWeight.bold)),
        SizedBox(width: 5),
        _headerCellItem(
            width: headerWidth[7],
            height: headerHeight,
            child: _textDataTable(
                text: languageProvider.getLanguageTransValue('Operation\nStatus'),
                size: (ConfigFileCtrl.deviceConfigLanguage == 'Kor') ? (defaultFontSize + 2) : defaultFontSize,
                fontWeight: FontWeight.bold)),
        SizedBox(width: 6),
        Container(
          width: headerWidth[8],
          height: headerHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                spreadRadius: 1,
                blurRadius: 1,
                offset: Offset(3, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              RotatedBox(
                quarterTurns: 3,
                child: Container(
                  width: 55,
                  height: 20,
                  color: homeHeaderColor,
                  child: _textDataTable(text: languageProvider.getLanguageTransValue('VOLT'), fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 4),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _progressDataTable(
                      value: _progressConvert(hotpadCtrlProvider.serialCtrl.rxPackage.acVoltValue, 0, ConfigFileCtrl.acVoltHigh),
                      text: hotpadCtrlProvider.serialCtrl.rxPackage.acVolt,
                      size: 18,
                      width: headerWidth[8] - 29,
                      forwardColor: Colors.red,
                      backgroundColor: Colors.grey,
                      fontWeight: FontWeight.bold,
                      isProgressText: false),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: 9),
        Container(
          width: headerWidth[9],
          height: headerHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                spreadRadius: 1,
                blurRadius: 1,
                offset: Offset(3, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              RotatedBox(
                quarterTurns: 3,
                child: Container(
                  width: 55,
                  height: 20,
                  color: homeHeaderColor,
                  child: _textDataTable(text: languageProvider.getLanguageTransValue('POWER'),
                      size: (ConfigFileCtrl.deviceConfigLanguage == 'Kor') ? defaultFontSize : (defaultFontSize - 1),
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 4),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _progressDataTable(
                      value: _progressConvert(
                          hotpadCtrlProvider.serialCtrl.rxPackage.acTotalCurrent,
                          0,
                          hotpadCtrlProvider.serialCtrl.rxPackage.acVoltValue*(ConfigFileCtrl.acCurrentHigh * totalChannel)),
                      text: hotpadCtrlProvider.serialCtrl.rxPackage.acTotalCurrent == 0
                          ? '${hotpadCtrlProvider.serialCtrl.rxPackage.acTotalCurrent.toStringAsFixed(1)}W'
                          : hotpadCtrlProvider.serialCtrl.rxPackage.acTotalCurrent > 1 ?
                            '${hotpadCtrlProvider.serialCtrl.rxPackage.acTotalCurrent.toStringAsFixed(1)}W'
                          : '${hotpadCtrlProvider.serialCtrl.rxPackage.acTotalCurrent.toStringAsFixed(3)}W',
                      size: 18,
                      width: headerWidth[8] - 29,
                      forwardColor: Color(0xFFFFD700),
                      backgroundColor: Colors.grey,
                      fontWeight: FontWeight.bold,
                      isProgressText: false),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /***********************************************************************
   *          데이터 행 항목을 생성하는 함수
   ***********************************************************************////
  Widget _dataRowItem({
    required int index,
    required ChannelStatus statusCh,
    required String strChannel,
    required double currentTempValue,
    required String setTemp,
    required double remainTotalTimeValue,
    required double remainTimeValue,
    required TextEditingController textEditCtrl,
    required double currentValue,
    required String strPADOhm,
    required String strPADStatus,
    required bool isHighlighted,
    required FocusNode focusNode,
    required LanguageProvider languageProvider,
  }) {
    const List<double> cellWidth = [110, 90, 90, 100, 75, 90, 90, 90, 76, 76, 76];
    const double cellHeight = 51;

    return Row(
      children: [
        /// ### Channel ###
        _dataCellItem(
          width: cellWidth[0],
          height: cellHeight,
          isHighlighted : isHighlighted,
          child: TextButton(
            onPressed: () {
              hotpadCtrlProvider
.togglePU45Enable(index);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (statusCh == ChannelStatus.stop)
                  Image.asset(
                    width: 20,
                    height: 20,
                    iconLEDGreyPath,
                  )
                else if (statusCh == ChannelStatus.start)
                  Image.asset(
                    width: 20,
                    height: 20,
                    iconLEDGreenPath,
                  )
                else if (statusCh == ChannelStatus.error)
                    Image.asset(
                      width: 20,
                      height: 20,
                      iconLEDRedPath,
                    )
                  else
                    Image.asset(
                      width: 20,
                      height: 20,
                      iconLEDGreyPath,
                    ),
                _textDataTable(
                    text: 'CH$strChannel', fontWeight: FontWeight.bold),
              ],
            ),
          ),
        ),
        SizedBox(width: 5),
        /// ### Current Temperature ###
        _dataCellItem(
          width: cellWidth[1],
          height: cellHeight,
          isHighlighted : isHighlighted,
          child: _progressDataTable(
              value: _progressConvert(currentTempValue, -10, 160),
              width: (cellWidth[1] - 10),
              isProgressText: false,
              text: currentTempValue.toStringAsFixed(1),
              size: 18,
              fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 5),
        /// ### Setting Temperature ###
        _dataCellItem(
          width: cellWidth[2],
          height: cellHeight,
          isHighlighted : isHighlighted,
          child: _textDataTable(
            text: setTemp,
            size: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 5),
        /// ### Remain Time ###
        _dataCellItem(
          width: cellWidth[3],
          height: cellHeight,
          isHighlighted : isHighlighted,
          child: _progressDataTable(
              value: (remainTotalTimeValue == -1)
                  ? 0
                  : (1.0 - remainTimeValue/remainTotalTimeValue),
              width: (cellWidth[1] - 10),
              text: _formatDuration(remainTimeValue),
              size: 18,
              fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 5),
        /// ### PAD ID ###
        _dataCellItem(
          width: cellWidth[4],
          height: cellHeight,
          isHighlighted : isHighlighted,
          child: TextField(
            controller: textEditCtrl,
            focusNode: focusNode,
            maxLength: 6,
            buildCounter: (BuildContext context,
                {int? currentLength, int? maxLength, bool? isFocused}) =>
            null,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              hintText: '---',
              hintStyle: TextStyle(
                color: Colors.black54,
                fontSize: defaultFontSize,
              ),
            ),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: 5),
        /// ### PAD Current ###
        _dataCellItem(
          width: cellWidth[5],
          height: cellHeight,
          isHighlighted : isHighlighted,
          child: _progressDataTable(
              value: _progressConvert(currentValue, 0, ConfigFileCtrl.acCurrentHigh),
              width: (cellWidth[5] - 10),
              text: (currentValue == 0)
                  ? currentValue.toStringAsFixed(1) : ((currentValue > 1)
                  ? currentValue.toStringAsFixed(1) : currentValue.toStringAsFixed(3)),
              size: 18,
              isProgressText: false,
              fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 5),
        /// ### PAD Resistor ###
        _dataCellItem(
          width: cellWidth[6],
          height: cellHeight,
          isHighlighted : isHighlighted,
          child: _textDataTable(
            text: strPADOhm,
            size: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 5),
        /// ### Operation Status ###
        _dataCellItem(
          width: cellWidth[7],
          height: cellHeight,
          isHighlighted : isHighlighted,
          child: _textDataTable(
            text: strPADStatus,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 6),
        /// ### Heating Start Button ###
        _ctrlButton(
          width: cellWidth[8], height: cellHeight, text: languageProvider.getLanguageTransValue('Start'), size: 18,
          isDisable: hotpadCtrlProvider.getIsPreheatingBtn(index),
          isRedMode: hotpadCtrlProvider.getIsStartBtn(index),
          onPressed: (){
            if (hotpadCtrlProvider.getPadIDText(index).isEmpty) {
              hotpadCtrlProvider.showInstMessage(
                'Warning',
                'CH${(index+1).toString().padLeft(2,'0')}',
                hotpadCtrlProvider.getIsPU45Enable(index) ? 'PU45' : 'PU15',
                'W0001');
            } else {
              hotpadCtrlProvider.startHeating(index);
              // hotpadCtrlProvider.showAlarmMessage(
              //   'CH${(index+1).toString().padLeft(2,'0')}',
              //   hotpadCtrlProvider.getIsPU45Enable(index) ? 'PU45' : 'PU15',
              //   'I0002');
            }
          },
        ),
        SizedBox(width: 5),
        /// ### Preheating Button ###
        _ctrlButton(
          width: cellWidth[9], height: cellHeight, text: languageProvider.getLanguageTransValue('Heating'),
          size: (ConfigFileCtrl.deviceConfigLanguage == 'Kor') ? (defaultFontSize + 4) : defaultFontSize,
          isDisable: hotpadCtrlProvider.getIsPU45Enable(index) ? true : hotpadCtrlProvider.getIsStartBtn(index),
          isRedMode: hotpadCtrlProvider.getIsPreheatingBtn(index),
          onPressed: (){
            if (hotpadCtrlProvider.getPadIDText(index).isEmpty) {
              hotpadCtrlProvider.showInstMessage(
                  'Warning',
                  'CH${(index+1).toString().padLeft(2,'0')}',
                  hotpadCtrlProvider.getIsPU45Enable(index) ? 'PU45' : 'PU15',
                  'W0001');
            } else {
              hotpadCtrlProvider.startPreheating(index);
              // hotpadCtrlProvider.showAlarmMessage(
              //     'CH${(index+1).toString().padLeft(2,'0')}',
              //     hotpadCtrlProvider.getIsPU45Enable(index) ? 'PU45' : 'PU15',
              //     'I0006');
            }
          },
        ),
        SizedBox(width: 5),
        /// ### Stop Button ###
        _ctrlButton(
          width: cellWidth[10], height: cellHeight, text: languageProvider.getLanguageTransValue('Stop'), size: 18,
          isDisable: false,
          isRedMode: !(hotpadCtrlProvider.getIsStartBtn(index) || hotpadCtrlProvider.getIsPreheatingBtn(index)),
          onPressed: (){
            if(hotpadCtrlProvider.getIsStartBtn(index) || hotpadCtrlProvider.getIsPreheatingBtn(index)) {
              _textEditCtrl[index].text = '';
              hotpadCtrlProvider.stopHeating(index);
              hotpadCtrlProvider.showAlarmMessage(
                  'CH${(index+1).toString().padLeft(2,'0')}',
                  hotpadCtrlProvider.getIsPU45Enable(index) ? 'PU45' : 'PU15',
                  'I0008');
            }
          },
        ),
      ],
    );
  }

  /***********************************************************************
   *          헤더 아이템 생성하는 함수
   ***********************************************************************////
  Widget _headerCellItem({
    required double width,
    required double height,
    required Widget child,
  }) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: homeHeaderColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            spreadRadius: 1,
            blurRadius: 1,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  /***********************************************************************
   *          데이터 아이템 생성하는 함수
   ***********************************************************************////
  Widget _dataCellItem({
    required double width,
    required double height,
    required Widget child,
    required bool isHighlighted,
  }) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: isHighlighted ?
        LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            pu45SelectColor,
            pu45SelectColor,
            gpu45SelectColor,
          ],
        )
        : LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            barBackgroundColor,
            backgroundColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            spreadRadius: 1,
            blurRadius: 1,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  /***********************************************************************
   *          Heating, Preheating, Stop 기본 버튼 함수
   ***********************************************************************////
  Widget _ctrlButton({
    required double width,
    required double height,
    required String text,
    required bool isDisable,
    required VoidCallback onPressed,
    double size = defaultFontSize,
    bool isRedMode = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: isDisable ? null : _btnGradient(isMode: isRedMode),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            spreadRadius: 1,
            blurRadius: 1,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: TextButton(
        onPressed: isDisable ? null : onPressed,
        style: TextButton.styleFrom(
          fixedSize: Size(width, height),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
        ),
        child: _textDataTable(
          text: text,
          size: size,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /***********************************************************************
   *          Heating, Preheating, Stop 기본 버튼 함수의 그라데이션
   ***********************************************************************////
  LinearGradient _btnGradient({required bool isMode}) {
    if (isMode) {
      return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFF02020),
            Color(0xFFE02020),
            Color(0xFFB02020),
            // Color(0xFFFF5050),
          ]);
    } else {
      return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF00F000),
            Color(0xFF00E000),
            Color(0xFF00C000),
            // Color(0xFF70FF70),
          ]);
    }
  }

  /***********************************************************************
   *          기본 ProgressBar 함수
   ***********************************************************************////
  Widget _progressDataTable({
    required double value,
    required String text,
    required double width,
    bool isProgressText = true,
    Color color = Colors.black,
    Color backgroundColor = Colors.white,
    Color forwardColor = const Color(0xFF006400),
    double size = defaultFontSize,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final validValue = value.isNaN || value.isInfinite ? 0.0 : value.clamp(0.0, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _textDataTable(
            text: text, color: color, size: size, fontWeight: fontWeight),
        Stack(
          children: [
            SizedBox(
              width: width,
              height: 18,
              child: LinearProgressIndicator(
                value: validValue,
                backgroundColor: backgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(forwardColor),
              ),
            ),
            if (isProgressText)
              Positioned.fill(
                child: Center(
                  child: Text(
                    '${(validValue * 100).round()}%',
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
    );
  }

  /***********************************************************************
   *          기본 Text 함수
   ***********************************************************************////
  Widget _textDataTable({
    required String text,
    Color color = Colors.black,
    double size = defaultFontSize,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: fontWeight,
      ),
    );
  }

  /***********************************************************************
   *          TextField에 FocusLost시 동작되는 함수
   ***********************************************************************////
  void _onFocusLost(int index){
    hotpadCtrlProvider.setPadID(index, _textEditCtrl[index].text);
  }

  /***********************************************************************
   *          ProgressBar의 Value 사용되는 데이터로 변환
   ***********************************************************************////
  double _progressConvert(double val, double minVal, double maxVal){
    double tmpVal = 0;
    double totalVal = maxVal - minVal;
    if(totalVal < val){
      tmpVal = 1.0;
    }
    else{
      tmpVal = (val/totalVal);
    }

    return tmpVal;
  }

  /***********************************************************************
   *          RemainTime의 출력 포멧
   ***********************************************************************////
  String _formatDuration(double seconds) {
    // double 값을 Duration으로 변환
    Duration duration = Duration(seconds: seconds.toInt());
    // Duration을 DateTime으로 변환
    DateTime dateTime = DateTime(0).add(duration);

    if(seconds >= 3600.0){
      // 'hh:mm:ss' 포맷으로 변환
      return DateFormat('hh:mm:ss').format(dateTime);
    }
    else{
      // 'mm:ss' 포맷으로 변환
      return DateFormat('mm:ss').format(dateTime);
    }
  }
}