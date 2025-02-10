import 'package:flutter/material.dart';
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
  final ScrollController _scrollController = ScrollController();
  final List<TextEditingController> _textEditCtrl =
  List.generate(totalChannel, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(totalChannel, (_) => FocusNode());

  late HotpadCtrl hotpadCtrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 키보드 상태 감지를 위해 observer 등록
    hotpadCtrl = Provider.of<HotpadCtrl>(context, listen: false);

    for (var i = 0; i < _textEditCtrl.length; i++) {
      _focusNodes[i].addListener(() {
        if (!_focusNodes[i].hasFocus) {
          _onFocusLost(i);
        }
      });

      _textEditCtrl[i].text = hotpadCtrl.getPadIDText(i);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // observer 제거
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
          _headerRowItem(languageProvider, hotpadCtrl),
          ...List.generate(
            totalChannel,
                (index) => Column(
              children: [
                SizedBox(height: 5),
                _dataRowItem(
                  index: index,
                  statusCh: StatusChannel.ready,
                  strChannel: (index + 1).toString().padLeft(2, '0'),
                  currentTempValue: double.tryParse(hotpadCtrl.serialCtrl.rxPackage.rtd[index]) ?? 0.0,
                  setTemp: _settingTempSelect(hotpadCtrl.getIsPU45Enable(index), hotpadCtrl.getHeatingStepStatus(index)),
                  remainTimeValue: 39,
                  textEditCtrl: _textEditCtrl[index],
                  currentValue: double.tryParse(hotpadCtrl.serialCtrl.rxPackage.padCurrent[index]) ?? 0.0,
                  strPADOhm: hotpadCtrl.serialCtrl.rxPackage.padOhm[index],
                  strPADStatus: hotpadCtrl.getHeatingStatus(languageProvider, HeatingStatus.stop),
                  isHighlighted: hotpadCtrl.getIsPU45Enable(index),
                  focusNode: _focusNodes[index],
                  languageProvider: languageProvider,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerRowItem(LanguageProvider languageProvider, HotpadCtrl hotpadCtrl) {
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
                  hotpadCtrl.togglePU45Enable(i);
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
                    hotpadCtrl.setPadID(i, _textEditCtrl[i].text);
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
                      value: _progressConvert(double.tryParse(hotpadCtrl.serialCtrl.rxPackage.acVolt)?? 0.0, 0, ConfigFileCtrl.acVoltHigh),
                      text: hotpadCtrl.serialCtrl.rxPackage.acVolt,
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
                      value: 0.2,
                      text: '2201W',
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

  Widget _dataRowItem({
    required int index,
    required StatusChannel statusCh,
    required String strChannel,
    required double currentTempValue,
    required String setTemp,
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
              hotpadCtrl.togglePU45Enable(index);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (statusCh == StatusChannel.ready)
                  Image.asset(
                    width: 20,
                    height: 20,
                    iconLEDGreyPath,
                  )
                else if (statusCh == StatusChannel.start)
                  Image.asset(
                    width: 20,
                    height: 20,
                    iconLEDGreenPath,
                  )
                else if (statusCh == StatusChannel.error)
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
              value: remainTimeValue,
              width: (cellWidth[1] - 10),
              text: remainTimeValue.toStringAsFixed(1),
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
              text: currentValue.toStringAsFixed(1),
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
          isDisable: hotpadCtrl.getIsPreheatingBtn(index),
          isRedMode: hotpadCtrl.getIsStartBtn(index),
          onPressed: (){
            if (hotpadCtrl.getPadIDText(index).isEmpty) {
              hotpadCtrl.showInstMessage(
                'Warning',
                'CH${(index+1).toString().padLeft(2,'0')}',
                hotpadCtrl.getIsPU45Enable(index) ? 'PU45' : 'PU15',
                'W0001');
            } else {
              hotpadCtrl.startHeating(index);
              hotpadCtrl.showAlarmMessage(
                'CH${(index+1).toString().padLeft(2,'0')}',
                hotpadCtrl.getIsPU45Enable(index) ? 'PU45' : 'PU15',
                'I0002');
            }
          },
        ),
        SizedBox(width: 5),
        /// ### Preheating Button ###
        _ctrlButton(
          width: cellWidth[9], height: cellHeight, text: languageProvider.getLanguageTransValue('Heating'),
          size: (ConfigFileCtrl.deviceConfigLanguage == 'Kor') ? (defaultFontSize + 4) : defaultFontSize,
          isDisable: hotpadCtrl.getIsPU45Enable(index) ? true : hotpadCtrl.getIsStartBtn(index),
          isRedMode: hotpadCtrl.getIsPreheatingBtn(index),
          onPressed: (){
            if (hotpadCtrl.getPadIDText(index).isEmpty) {
              hotpadCtrl.showInstMessage(
                  'Warning',
                  'CH${(index+1).toString().padLeft(2,'0')}',
                  hotpadCtrl.getIsPU45Enable(index) ? 'PU45' : 'PU15',
                  'W0001');
            } else {
              hotpadCtrl.startPreheating(index);
              hotpadCtrl.showAlarmMessage(
                  'CH${(index+1).toString().padLeft(2,'0')}',
                  hotpadCtrl.getIsPU45Enable(index) ? 'PU45' : 'PU15',
                  'I0006');
            }
          },
        ),
        SizedBox(width: 5),
        /// ### Stop Button ###
        _ctrlButton(
          width: cellWidth[10], height: cellHeight, text: languageProvider.getLanguageTransValue('Stop'), size: 18,
          isDisable: false,
          isRedMode: !(hotpadCtrl.getIsStartBtn(index) || hotpadCtrl.getIsPreheatingBtn(index)),
          onPressed: (){
            if(hotpadCtrl.getIsStartBtn(index) || hotpadCtrl.getIsPreheatingBtn(index)) {
              _textEditCtrl[index].text = '';
              hotpadCtrl.stopHeating(index);
              hotpadCtrl.showAlarmMessage(
                  'CH${(index+1).toString().padLeft(2,'0')}',
                  hotpadCtrl.getIsPU45Enable(index) ? 'PU45' : 'PU15',
                  'I0007');
            }
          },
        ),
      ],
    );
  }

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
                value: value,
                backgroundColor: backgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(forwardColor),
              ),
            ),
            if (isProgressText)
              Positioned.fill(
                child: Center(
                  child: Text(
                    '${(value * 100).round()}%',
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

  void _onFocusLost(int index){
    hotpadCtrl.setPadID(index, _textEditCtrl[index].text);
  }

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

  String _settingTempSelect(bool flag, HeatingStepStatus status){
    String strVal = '';

    if(!flag){      // PU15 Setting Temp
      strVal =  ConfigFileCtrl.pu15TargetTemp.toStringAsFixed(1);
    }
    else{           // PU45 Setting Temp
      if(status == HeatingStepStatus.step1){
        strVal =  ConfigFileCtrl.pu45Target1stTemp.toStringAsFixed(1);
      }
      else if(status == HeatingStepStatus.step2){
        strVal =  ConfigFileCtrl.pu45Target2ndTemp.toStringAsFixed(1);
      }
      else{
        strVal =  ConfigFileCtrl.pu45Target1stTemp.toStringAsFixed(1);
      }
    }

    return strVal;
  }
}