import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:provider/provider.dart';
import '../constant/user_style.dart';
import '../providers/language_provider.dart';
import '../devices/serial_ctrl.dart';
import '../devices/hotpad_ctrl.dart';
import '../devices/file_ctrl.dart';
import '../devices/logger.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => GraphPageState();
}

class GraphPageState extends State<GraphPage> with AutomaticKeepAliveClientMixin {
  late ZoomPanBehavior _zoomPanBehavior;
  late TrackballBehavior _trackballBehavior;
  late DateTimeAxis _dateTimeAxis;
  late DateTime _dateTime;
  late int _graphCount;
  final List<bool> _isVisibleSeries = List.filled(10, true);
  final List<List<ChartData>> _chartDataSeries = List.generate(10, (_) => []);
  final List<Color> bkColor = [
    Colors.white, Color(0xFF808080), Colors.red, Colors.green, Colors.blue,
    Colors.yellow, Color(0xFFFF00FF), Color(0xFF00FFFF), Colors.orange, Color(0xFF4682B4),
  ];

  late bool _isChartEnable;
  late String chartTitle;
  late int _liveCount;

  static const int defaultLiveCount = 30;        // defaultLiveCount * 10sec
  late double zoomFactor;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _isChartEnable = true;
    _graphCount = 0;
    chartTitle = '';
    _liveCount = 0;
    zoomFactor = 1;

    // 그래프 확대/축소 및 이동 동작 설정
    _zoomPanBehavior = ZoomPanBehavior(
      enablePanning: true,
      zoomMode: ZoomMode.x,
    );
    _zoomPanBehavior.zoomByFactor(zoomFactor);

    // 그래프 트랙볼 동작 설정
    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.longPress,
      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
      tooltipSettings: InteractiveTooltip(format: 'series.name : point.y℃'),
      hideDelay: 5000,
    );

    _dateTime = DateTime.now();
    int divMin = (_dateTime.minute / 10).toInt() * 10;
    _dateTime = DateTime(_dateTime.year, _dateTime.month, _dateTime.day,
          _dateTime.hour, divMin, 0);

    // 그래프의 X축 설정
    _setXAxis(_dateTime, _dateTime.add(Duration(minutes: 120)), interval: 10);
  }

  @override
  void dispose() {
    super.dispose();
  }
  /***********************************************************************
   *          그래프 Series의 가시성 업데이트하는 함수
   ***********************************************************************////
  void _updateVisibleSeries(int index, bool isVisible) {
    setState(() {
      _isVisibleSeries[index] = isVisible;
    });
  }
  /***********************************************************************
   *          모든 그래프 Series의 가시성 토글 함수
   ***********************************************************************////
  void _toggleAllSeriesVisibility() {
    setState(() {
      for (int i = 0; i < _isVisibleSeries.length; i++) {
        _isVisibleSeries[i] = !_isVisibleSeries[i];
      }
    });
  }
  /***********************************************************************
   *          그래프 확대 함수
   ***********************************************************************////
  void zoomIn() {
    // _zoomPanBehavior.zoomIn();
    zoomFactor -= 0.2;
    if(zoomFactor < 0.2){
      zoomFactor = 0.2;
    }
    _zoomPanBehavior.zoomByFactor(zoomFactor);
  }
  /***********************************************************************
   *          그래프 축소 함수
   ***********************************************************************////
  void zoomOut() {
    // _zoomPanBehavior.zoomOut();
    zoomFactor += 0.2;
    if(zoomFactor > 1){
      zoomFactor = 1;
    }
    _zoomPanBehavior.zoomByFactor(zoomFactor);
  }
  /***********************************************************************
   *          그래프 확대/축소를 초기화하는 함수
   ***********************************************************************////
  void resetZoom() {
    // _zoomPanBehavior.reset();
    zoomFactor = 1;
    _zoomPanBehavior.zoomByFactor(zoomFactor);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Add this line to call super.build
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(width: 10),
        Column(
          children: [
            SizedBox(height: 10),
            _headerRowItem(languageProvider),
            Column(
              children: List.generate(
                _isVisibleSeries.length,
                (index) => Column(
                  children: [
                    SizedBox(height: 5),
                    Consumer<HotpadCtrl>(
                      builder: (context, hotpadCtrlProvider, _) {
                        return _cellRowItem(
                          index: index,
                          strTemp: hotpadCtrlProvider.serialCtrl.rxPackage.rtdTemp[index],
                          color: _isVisibleSeries[index] ? bkColor[index] : Colors.transparent,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            _userButton(languageProvider),
          ],
        ),
        SizedBox(width: 10),
        _tempCharts(),
      ],
    );
  }
  /***********************************************************************
   *          헤더 행 항목을 생성하는 함수
   ***********************************************************************////
  Widget _headerRowItem(LanguageProvider languageProvider) {
    return Row(
      children: [
        _cellItem(
          width: 120,
          height: 60,
          child: TextButton(
            onPressed: () {},
            onLongPress: _toggleAllSeriesVisibility,
            child: Text(
              languageProvider.getLanguageTransValue('Select\nunselect/all'),
              textAlign: TextAlign.center,
              style: TextStyle( color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SizedBox(width: 5),
        _cellItem(
          width: 100,
          height: 60,
          child: Text(
            languageProvider.getLanguageTransValue('Temp\n[℃]'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
  /***********************************************************************
   *          각 데이터 행 항목을 생성하는 함수
   ***********************************************************************////
  Widget _cellRowItem({
    required int index,
    required String strTemp,
    required Color color,
  }) {
    return Row(
      children: [
        _cellItem(
          width: 120,
          height: 43,
          color: color,
          child: Row(
            children: [
              Checkbox(
                value: _isVisibleSeries[index],
                onChanged: (bool? value) {_updateVisibleSeries(index, value!);},
              ),
              Text(
                'CH${(index + 1).toString().padLeft(2, '0')}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(width: 5),
        _cellItem(
          width: 100,
          height: 43,
          child: Text(strTemp,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
  /***********************************************************************
   *          각 셀 항목을 생성하는 함수
   ***********************************************************************////
  Widget _cellItem({
    required double width,
    required double height,
    required Widget child,
    Color color = homeHeaderColor,
  }) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
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
   *          검색 버튼을 생성하는 함수
   ***********************************************************************////
  Widget _userButton(LanguageProvider languageProvider) {
    return Row(
      children: [
        /// ### Live Button
        Container(
          decoration: BoxDecoration(
            color: homeHeaderColor,
            borderRadius: BorderRadius.all(Radius.circular(100)),
            boxShadow: [
              BoxShadow(
                color: (_isChartEnable == true) ? Colors.transparent: Colors.black45,
                spreadRadius: 1, blurRadius: 1, offset: Offset(3, 3),
              ),
            ],
          ),
          child: TextButton.icon(
            icon: Icon(
              Icons.auto_graph,
              size: 22,
              color: (_isChartEnable == true) ? Colors.black45 : Colors.black,
            ),
            onPressed: (_isChartEnable == true) ? null : () {liveChartInit();},
            style: ElevatedButton.styleFrom(fixedSize: Size(110, 35)),
            label: Text(
              languageProvider.getLanguageTransValue('Live'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: (_isChartEnable == true) ? Colors.black45 : Colors.black,
                fontSize: 16, fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        /// ### Search Button
        Container(
          decoration: BoxDecoration(
            color: homeHeaderColor,
            borderRadius: BorderRadius.all(Radius.circular(100)),
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                spreadRadius: 1, blurRadius: 1, offset: Offset(3, 3),
              ),
            ],
          ),
          child: TextButton.icon(
            icon: Icon(
              Icons.search,
              size: 22,
              color: Colors.black,
            ),
            onPressed: () {_searchGraphFile(context, languageProvider);},
            style: ElevatedButton.styleFrom(fixedSize: Size(110, 35)),
            label: Text(
              languageProvider.getLanguageTransValue('Search'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        )
      ],
    );
  }
  /***********************************************************************
   *          그래프 파일 Searching 함수
   ***********************************************************************////
  Future<void> _searchGraphFile(BuildContext context, LanguageProvider languageProvider) async {
    List<String> graphSubFolder = FileCtrl.searchSubFolder();
    List<String> selectedFiles = [];
    String? selectPath;
    String? selectFileName;
    String msgText = '';

    void updateFileList(String path){
      selectedFiles = FileCtrl.searchGraphFileList(path);
      String nowFile = FileCtrl.nowGraphFileName;
      selectedFiles.removeWhere((file) => file == nowFile);
    }

    /// ### message Text 출력 함수
    void showMessage(StateSetter setState, String msg) async{
      setState(() {
        msgText = languageProvider.getLanguageTransValue(msg);
      });
      await Future.delayed(const Duration(seconds: 2));
      setState(() {msgText = '';});
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                languageProvider.getLanguageTransValue('Search Graph File List'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: defaultFontSize + 10, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                height: MediaQuery.of(context).size.height / 3,
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    /// ### DropDownMenu Text ###
                    /// ### Graph Date
                    SizedBox(
                      width: 300,
                      child: Text(languageProvider.getLanguageTransValue('Date'),
                        style: TextStyle(fontSize: defaultFontSize + 4, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 10),
                    DropdownMenu(
                      width: 300,
                      onSelected: (String? value) {
                        if(value != null){
                          setState((){
                            selectPath = value;
                            updateFileList(value);
                          });
                        }
                      },
                      dropdownMenuEntries: graphSubFolder
                          .map((String path) => DropdownMenuEntry<String>(value: path, label: path))
                          .toList(),
                      hintText: languageProvider.getLanguageTransValue('select...'),
                    ),
                    SizedBox(height: 30),
                    /// ### Graph File List
                    SizedBox(
                      width: 300,
                      child: Text(languageProvider.getLanguageTransValue('File List'),
                        style: TextStyle(fontSize: defaultFontSize + 4, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 10),
                    DropdownMenu(
                      width: 300,
                      onSelected: (String? value) {selectFileName = value;},
                      dropdownMenuEntries: selectedFiles
                          .map((file) => DropdownMenuEntry(value: file, label: file))
                          .toList(),
                      hintText: languageProvider.getLanguageTransValue('select...'),
                    ),
                    SizedBox(height: 10),
                    Text(msgText, style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.deepPurpleAccent),
                      fixedSize: WidgetStateProperty.all<Size>(Size.fromWidth(120)),
                    ),
                    child: Text(languageProvider.getLanguageTransValue('Cancel'),
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if((selectPath != null) && (selectFileName != null)){
                      _isChartEnable = false;

                      List<Map<String, dynamic>> graphData = await FileCtrl.loadGraphFileData(selectPath!, selectFileName!);
                      chartTitle = 'File : $selectFileName';
                      drawGraphDataFile(graphData, languageProvider:languageProvider);

                      // context가 유효한지 확인
                      if(!context.mounted) return;
                      Navigator.of(context).pop();
                    }
                    else{
                      showMessage(setState, "There are no selected items");
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.deepPurpleAccent),
                    fixedSize: WidgetStateProperty.all<Size>(Size.fromWidth(120)),),
                  child: Text(languageProvider.getLanguageTransValue('OK'),
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_){
      setState(() { });
    });
  }
  /***********************************************************************
   *          온도 차트를 생성하는 함수
   ***********************************************************************////
  Widget _tempCharts() {
    return Expanded(
      child: Consumer<HotpadCtrl>(
        builder: (context, hotpadCtrlProvider, _) {
          updateChartData(hotpadCtrlProvider);
          return Container(
            margin: EdgeInsets.all(10),
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
              zoomPanBehavior: _zoomPanBehavior,
              trackballBehavior: _trackballBehavior,
              title: ChartTitle(
                text: chartTitle,
                alignment: ChartAlignment.far,
                textStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),

              /// ### X-axis ###
              primaryXAxis: _dateTimeAxis,

              /// ### Y-axis ###
              primaryYAxis: NumericAxis(
                decimalPlaces: 0,
                minorGridLines: MinorGridLines(color: Colors.transparent),
                majorTickLines: MajorTickLines(size: 10),
                minorTickLines: MinorTickLines(size: 5, width: 1, color: Colors.white),
                minorTicksPerInterval: 5,
                labelStyle: TextStyle(color: Colors.white),
                maximum: 120,
              ),

              /// ### Series ###
              // series: List<FastLineSeries<ChartData, DateTime>>.generate(10,
              //   (index) => FastLineSeries<ChartData, DateTime>(
              //     name: 'CH${(index + 1).toString().padLeft(2, '0')}',
              //     dataSource: _chartDataSeries[index],
              //     markerSettings: MarkerSettings(isVisible: false),
              //     xValueMapper: (ChartData data, _) => data.time,
              //     yValueMapper: (ChartData data, _) => data.value,
              //     color: _isVisibleSeries[index] ? bkColor[index] : Colors.transparent),
              // ),
              series: List<SplineSeries<ChartData, DateTime>>.generate(10,
                    (index) => SplineSeries<ChartData, DateTime>(
                    name: 'CH${(index + 1).toString().padLeft(2, '0')}',
                    dataSource: _chartDataSeries[index],
                    // splineType: SplineType.cardinal,
                    splineType: SplineType.monotonic,
                    animationDuration: 100,
                    markerSettings: MarkerSettings(isVisible: false),
                    xValueMapper: (ChartData data, _) => data.time,
                    yValueMapper: (ChartData data, _) => data.value,
                    color: _isVisibleSeries[index] ? bkColor[index] : Colors.transparent),
              ),
            ),
          );
        },
      ),
    );
  }
  /***********************************************************************
   *          차트 데이터를 업데이트하는 함수
   ***********************************************************************////
  void updateChartData(HotpadCtrl hotpadCtrlProvider) {
    if ((hotpadCtrlProvider.serialCtrl.serialPortStatus.index < SerialPortStatus.txBusy.index) ||
        (_graphCount++ % 10 != 0)) {
      return;
    }

    DateTime tmpDateTime = hotpadCtrlProvider.serialCtrl.rxPackage.rxTime;
    hotpadCtrlProvider.isGraphLive= _isChartEnable;
    // HotpadData/yyyyMM/Graph 폴더의 SQLite 파일에 저장
    FileCtrl.saveGraphData(
        tmpDateTime,
        hotpadCtrlProvider.getHeatingStatusList,
        hotpadCtrlProvider.serialCtrl.rxPackage.rtdTemp);

    Logger.msg("Save Graph Data]${hotpadCtrlProvider.serialCtrl.rxPackage.status},${hotpadCtrlProvider.serialCtrl.rxPackage.rtdTemp}");

    if (_isChartEnable == false) {
      if(_liveCount++ >= defaultLiveCount){
          liveChartInit();
      }
      return;
    }

    for (int index = 0; index < totalChannel; index++) {
      double value = double.tryParse(hotpadCtrlProvider.serialCtrl.rxPackage.rtdTemp[index]) ?? 0.0;
      _chartDataSeries[index].add(ChartData(tmpDateTime, value));
    }

    // 그래프가 x축의 maximum 부근에 도달하면 maximum을 확장함.
    if (tmpDateTime.isAfter(_dateTimeAxis.maximum!.subtract(Duration(minutes: 1)))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DateTime tmpMax = DateTime.now().add(Duration(minutes: 60));
        int durationInTime = tmpMax.difference(_dateTimeAxis.minimum!).inMinutes;
        int interval = (durationInTime + 1) ~/ 12;

        _setXAxis(_dateTime, tmpMax, interval: interval);
      });
    }
  }
  /***********************************************************************
   *          Graph Data File 그래프 그리기 함수
   ***********************************************************************////
  void drawGraphDataFile(List<Map<String, dynamic>> data, {LanguageProvider? languageProvider}){
    List<List<ChartData>> tmpCharDataSeries = List.generate(10, (_) => []);

    if(data.isEmpty){
      if(languageProvider != null) {
        liveChartInit();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(languageProvider.getLanguageTransValue('The file does not contain any data.'),
              textAlign: TextAlign.center),
          duration: Duration(seconds: 3),
        ));
      }
      return;
    }

    for(int i = 0; i < (data.length - 1); i++){
      DateTime time = DateTime.parse(data[i]['time']);
      List<String> rtdValues = data[i]['rtd'].split(',');
      for(int j = 0; j < totalChannel; j++){
        double value = double.tryParse(rtdValues[j]) ?? 0.0;
        tmpCharDataSeries[j].add(ChartData(time, value));
      }
    }

    DateTime minDate = DateTime.parse(data[0]['time']);
    minDate = DateTime(minDate.year, minDate.month, minDate.day,
        minDate.hour, ((minDate.minute/10).toInt() * 10), 0);
    DateTime lastDate = DateTime.parse(data[(data.length-1)]['time']);
    DateTime maxDate = minDate.add(Duration(minutes: 120));
    Duration diff = lastDate.difference(maxDate);

    if(!diff.isNegative){
      maxDate = DateTime(lastDate.year, lastDate.month, lastDate.day,
          lastDate.hour, ((lastDate.minute/10).toInt() + 1) * 10, 0);
    }

    _setXAxis(minDate, maxDate);

    setState(() {
      _chartDataSeries.clear();
      _chartDataSeries.addAll(tmpCharDataSeries);
    });
  }
  /***********************************************************************
   *          Graph x축 설정 함수
   ***********************************************************************////
  void _setXAxis(DateTime minDate, DateTime maxDate, {int? interval}){
    // 그래프 x축 Range 계산
    Duration diff = maxDate.difference(minDate);
    diff = maxDate.difference(minDate);
    int tmpInterval = diff.inMinutes ~/ 12;

    _dateTimeAxis = DateTimeAxis(
      dateFormat: DateFormat.Hms(),
      intervalType: DateTimeIntervalType.minutes,
      interval: (interval ?? tmpInterval).toDouble(),
      minimum: minDate,
      maximum: maxDate,
      plotOffsetStart: 5,
      plotOffsetEnd: 10,
      edgeLabelPlacement: EdgeLabelPlacement.shift,
      labelStyle: TextStyle(color: Colors.white),
    );
  }

  void liveChartInit() async{
    List<Map<String, dynamic>> graphData = await FileCtrl.loadGraphData();
    drawGraphDataFile(graphData);

    zoomFactor = 1;
    _zoomPanBehavior.zoomByFactor(zoomFactor);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState((){
        chartTitle = '';
        _isChartEnable = true;
        _liveCount = 0;
      });
    });
  }
}
/***********************************************************************
 *          차트 데이터 구조 클래스
 ***********************************************************************////
class ChartData {
  final DateTime time;
  final double value;

  ChartData(this.time, this.value);
}
