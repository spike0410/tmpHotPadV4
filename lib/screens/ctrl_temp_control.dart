import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:provider/provider.dart';
import '../devices/config_file_ctrl.dart';
import '../providers/language_provider.dart';
import '../constant/user_style.dart';

class CtrlTempControl extends StatefulWidget {
  const CtrlTempControl({super.key});

  @override
  State<CtrlTempControl> createState() => _CtrlTempControlState();
}

enum OutputEnum { auto, manual }

class _CtrlTempControlState extends State<CtrlTempControl> with WidgetsBindingObserver {
  final List<TextEditingController> _textEditCtrl = List.generate(5, (_) => TextEditingController());
  final ScrollController _scrollController = ScrollController();
  OutputEnum _outputEnum = OutputEnum.auto;

  @override
  void initState() {
    super.initState();
    // 키보드 상태 감지를 위해 observer 등록
    WidgetsBinding.instance.addObserver(this);

    // TextField와 FocusLost에 Listener 추가
    for (var controller in _textEditCtrl) {
      controller.addListener(() {
        final String text = controller.text.toString();
        controller.value = controller.value.copyWith(
          text: text,
          selection: TextSelection(baseOffset: text.length, extentOffset: text.length),
          composing: TextRange.empty,
        );
      });
    }
    _textEditCtrl[0].text = '10';     /// <---!@#
    _textEditCtrl[1].text = '10';     /// <---!@#
    _textEditCtrl[2].text = '10';     /// <---!@#
    _textEditCtrl[3].text = '73';     /// <---!@#
    _textEditCtrl[4].text = '2';      /// <---!@#
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
    final double stepHeight = 3;
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.vertical,
      child: Row(
        children: [
          SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(height: stepHeight),
              Container(
                width: 220,
                height: 50,
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
                child: Text(
                  languageProvider.getLanguageTransValue('CH01 PIT Control'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: (defaultFontSize + 4), fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              _rowItem(
                  name: languageProvider.getLanguageTransValue('P Gain'),
                  fontSize: 18,
                  child: _setPositionTextField(index: 0, width: 100, maxRange: 100)),
              SizedBox(height: stepHeight),
              _rowItem(
                  name: languageProvider.getLanguageTransValue('I Gain'),
                  fontSize: 18,
                  child: _setPositionTextField(index: 1, width: 100, maxRange: 100)),
              SizedBox(height: stepHeight),
              _rowItem(
                  name: languageProvider.getLanguageTransValue('T Gain'),
                  fontSize: 18,
                  child: _setPositionTextField(index: 2, width: 100, maxRange: 100)),
              SizedBox(height: stepHeight),
              _rowItem(
                  name: languageProvider.getLanguageTransValue('Target Temp.'),
                  fontSize: (ConfigFileCtrl.deviceConfigLanguage == 'Kor') ? 18 : defaultFontSize,
                  child: _setPositionTextField(index: 3, enable: false, width: 100, maxRange: 100)),
              SizedBox(height: stepHeight),
              _rowItem(
                name: languageProvider.getLanguageTransValue('Current Temp.'),
                fontSize: (ConfigFileCtrl.deviceConfigLanguage == 'Kor') ? 18 : defaultFontSize,
                child: _textItem(text: '26.7'),
              ),
              SizedBox(height: stepHeight),
              _rowItem(name: languageProvider.getLanguageTransValue('Error'),
                fontSize: 18,
                child: _textItem(text: '46.1'),
              ),
              SizedBox(height: stepHeight),
              _rowItem(name: languageProvider.getLanguageTransValue('P Calc.'),
                fontSize: 18,
                child: _textItem(text: '6.0'),
              ),
              SizedBox(height: stepHeight),
              _rowItem(name: languageProvider.getLanguageTransValue('I Calc.'),
                fontSize: 18,
                child: _textItem(text: '62.5'),
              ),
              SizedBox(height: stepHeight),
              _rowItem(name: languageProvider.getLanguageTransValue('T Calc.'),
                fontSize: 18,
                child: _textItem(text: '0.0'),
              ),
              SizedBox(height: stepHeight),
              _rowItem(name: languageProvider.getLanguageTransValue('PIT Calc.'),
                fontSize: 18,
                child: _textItem(text: '2'),
              ),
              SizedBox(height: stepHeight),
              _rowItem(name: languageProvider.getLanguageTransValue('Manual Out'),
                  fontSize: 18,
                  child: _setPositionTextField(
                      index: 4,
                      enable: (_outputEnum == OutputEnum.auto) ? false : true,
                      width: 100,
                      maxRange: 100)),
              SizedBox(height: stepHeight),
              _rowRadioItem(languageProvider),
              SizedBox(height: stepHeight),
              Row(
                children: [
                  _ctrlButton(
                    text: languageProvider.getLanguageTransValue('Start'),
                    size: 16,
                    width: 100,
                    height: 30,
                  ),
                  SizedBox(width: 10),
                  _ctrlButton(
                    text: languageProvider.getLanguageTransValue('Stop'),
                    size: 16,
                    width: 100,
                    height: 30,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(width: 10),
          _tempCharts(),
        ],
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
          style: TextStyle(fontSize: fontSize,fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 10),
        child,
      ],
    );
  }
  /***********************************************************************
   *          Text 항목을 생성하는 함수
   ***********************************************************************////
  Widget _textItem({
    required String text,
    double width = 100,
    double height = 30,
  }) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(fontSize: defaultFontSize, fontWeight: FontWeight.bold),
      ),
    );
  }
  /***********************************************************************
   *          rowRadioItem을 생성하는 함수
   ***********************************************************************////
  Widget _rowRadioItem(LanguageProvider languageProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          languageProvider.getLanguageTransValue('Output'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _titleRadio<OutputEnum>(
              text: languageProvider.getLanguageTransValue('Auto'),
              width: 108,
              value: OutputEnum.auto,
              groupValue: _outputEnum,
              onChanged: (value) {
                setState(() {
                  _outputEnum = value!;
                });
              },
            ),
            _titleRadio<OutputEnum>(
              text: languageProvider.getLanguageTransValue('Manual'),
              width: 108,
              value: OutputEnum.manual,
              groupValue: _outputEnum,
              onChanged: (value) {
                setState(() {
                  _outputEnum = value!;
                });
              },
            ),
          ],
        ),
      ],
    );
  }
  /***********************************************************************
   *          titleRadio 버튼을 생성하는 함수
   ***********************************************************************////
  Widget _titleRadio<T>({
    required String text,
    required T value,
    required T groupValue,
    required ValueChanged<T?>? onChanged,
    double width = 100,
  }) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Radio(
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
          ),
          Text(
            text,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
          // FilteringTextInputFormatter.digitsOnly,
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
   *          컨트롤 버튼을 생성하는 함수
   ***********************************************************************////
  Widget _ctrlButton({
    required double width,
    required double height,
    required String text,
    double size = defaultFontSize,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black45, // 그림자 색상
            spreadRadius: 1,
            blurRadius: 1, // 그림자 흐림 반경
            offset: Offset(3, 3), // 그림자 위치 (x, y)
          ),
        ],
      ),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          fixedSize: Size(width, height),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.black,
            fontSize: size,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  /***********************************************************************
   *          온도 차트를 생성하는 함수
   ***********************************************************************////
  Widget _tempCharts() {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(left: 10, right: 10),
        height: screenHeight - (barHeight * 2) - tabBarHeight - 15,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black45,
              spreadRadius: 2,
              blurRadius: 1,
              offset: Offset(4, 4),
            ),
          ],
        ),
        child: SfCartesianChart(
          backgroundColor: Colors.black,

          /// ### X-axis ###
          primaryXAxis: DateTimeAxis(
            dateFormat: DateFormat.Hms(),
            rangePadding: ChartRangePadding.roundStart,
            plotOffsetEnd: 10,
            edgeLabelPlacement: EdgeLabelPlacement.shift,
            labelStyle: TextStyle(color: Colors.white),
          ),

          /// ### Y-axis ###
          primaryYAxis: NumericAxis(
            decimalPlaces: 0,
            minorGridLines: MinorGridLines(color: Colors.transparent),
            majorTickLines: MajorTickLines(size: 10),
            minorTickLines: MinorTickLines(
              size: 5,
              width: 1,
              color: Colors.white,
            ),
            minorTicksPerInterval: 5,
            labelStyle: TextStyle(color: Colors.white),
            maximum: 120,
          ),
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
