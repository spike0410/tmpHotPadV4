import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:provider/provider.dart';
import '../constant/user_style.dart';
import '../providers/language_provider.dart';
import '../devices/serial_ctrl.dart';
import '../devices/hotpad_ctrl.dart';
import '../devices/file_ctrl.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => GraphPageState();
}

class GraphPageState extends State<GraphPage>
    with AutomaticKeepAliveClientMixin {
  late ZoomPanBehavior _zoomPanBehavior;
  late TrackballBehavior _trackballBehavior;
  late DateTimeAxis _dateTimeAxis;
  late DateTime _dateTime;
  late int _graphCount;
  final List<bool> _isVisibleSeries = List.filled(10, true);
  final List<List<ChartData>> _chartDataSeries = List.generate(10, (_) => []);
  final List<Color> bkColor = [
    Colors.white,
    Color(0xFF808080),
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Color(0xFFFF00FF),
    Color(0xFF00FFFF),
    Colors.orange,
    Color(0xFF4682B4),
  ];

  late bool _isChartEnable;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _isChartEnable = true;
    _graphCount = 0;

    // 그래프 확대/축소 및 이동 동작 설정
    _zoomPanBehavior = ZoomPanBehavior(
      enablePanning: true,
      zoomMode: ZoomMode.x,
    );

    // 그래프 트랙볼 동작 설정
    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.longPress,
      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
      tooltipSettings: InteractiveTooltip(format: 'series.name : point.y℃'),
      hideDelay: 3000,
    );

    _dateTime = DateTime.now();

    // 그래프의 X축 설정
    _dateTimeAxis = DateTimeAxis(
      dateFormat: DateFormat.Hms(),
      intervalType: DateTimeIntervalType.minutes,
      interval: 10,
      minimum: _dateTime,
      maximum: _dateTime.add(Duration(minutes: 120)),
      plotOffsetStart: 5,
      plotOffsetEnd: 10,
      edgeLabelPlacement: EdgeLabelPlacement.shift,
      labelStyle: TextStyle(color: Colors.white),
    );

    //startIsolate();
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
    _zoomPanBehavior.zoomIn();
  }

  /***********************************************************************
   *          그래프 축소 함수
   ***********************************************************************////
  void zoomOut() {
    _zoomPanBehavior.zoomOut();
  }

  /***********************************************************************
   *          그래프 확대/축소를 초기화하는 함수
   ***********************************************************************////
  void resetZoom() {
    _zoomPanBehavior.reset();
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
                      builder: (context, hotpadCtrl, _) {
                        return _cellRowItem(
                          index: index,
                          strTemp: hotpadCtrl.serialCtrl.rxPackage.rtd[index],
                          color: _isVisibleSeries[index]
                              ? bkColor[index]
                              : Colors.transparent,
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
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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
                onChanged: (bool? value) {
                  _updateVisibleSeries(index, value!);
                },
              ),
              Text(
                'CH${(index + 1).toString().padLeft(2, '0')}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 5),
        _cellItem(
          width: 100,
          height: 43,
          child: Text(
            strTemp,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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
            onPressed: (_isChartEnable == true) ? null : () {
                setState(() {
                  _isChartEnable = true;
                });
              },
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
            onPressed: () {
              _searchGraphFile(context, languageProvider);
            },
            style: ElevatedButton.styleFrom(
              fixedSize: Size(110, 35),
            ),
            label: Text(
              languageProvider.getLanguageTransValue('Search'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold,
              ),
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
    String? selectedPath;
    List<String> graphDates = FileCtrl.searchGraphDate();
    List<String> selectedFiles = [];

    void updateFileList(String path){
      selectedFiles = FileCtrl.searchGraphFileList(path);
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
                width: MediaQuery.of(context).size.width / 2,
                height: MediaQuery.of(context).size.height / 2,
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    /// ### DropDownMenu Text ###
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SizedBox(
                          width: 150,
                          child: Text(
                            languageProvider.getLanguageTransValue('Date'),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: defaultFontSize + 4, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          width: 250,
                          child: Text(
                            languageProvider.getLanguageTransValue('File List'),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: defaultFontSize + 4, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    /// ### DropDownMenu ###
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        DropdownMenu(
                          width: 150,
                          onSelected: (String? value) {
                            if(value != null){
                              setState((){
                                updateFileList(value);
                              });
                            }
                          },
                          dropdownMenuEntries: graphDates
                              .map((String path) => DropdownMenuEntry<String>(value: path, label: path))
                              .toList(),
                          hintText: languageProvider.getLanguageTransValue('select...'),

                        ),
                        DropdownMenu(
                          width: 250,
                          onSelected: (_) {},
                          dropdownMenuEntries: selectedFiles
                              .map((file) => DropdownMenuEntry(value: file, label: file))
                              .toList(),
                          hintText: languageProvider.getLanguageTransValue('select...'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () { Navigator.of(context).pop(); },
                    child: Text(
                      languageProvider.getLanguageTransValue('Cancel'),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () {
                      setState((){ _isChartEnable = false;});
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      languageProvider.getLanguageTransValue('OK'),
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
      setState(() { });
    });
  }



  /***********************************************************************
   *          온도 차트를 생성하는 함수
   ***********************************************************************////
  Widget _tempCharts() {
    return Expanded(
      child: Consumer<HotpadCtrl>(
        builder: (context, hotpadCtrl, _) {
          updateChartData(hotpadCtrl);
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

              /// ### X-axis ###
              primaryXAxis: _dateTimeAxis,

              /// ### Y-axis ###
              primaryYAxis: NumericAxis(
                decimalPlaces: 0,
                minorGridLines: MinorGridLines(color: Colors.transparent),
                majorTickLines: MajorTickLines(size: 10),
                minorTickLines:
                    MinorTickLines(size: 5, width: 1, color: Colors.white),
                minorTicksPerInterval: 5,
                labelStyle: TextStyle(color: Colors.white),
                maximum: 120,
              ),

              /// ### Series ###
              series: List<FastLineSeries<ChartData, DateTime>>.generate(
                10,
                (index) => FastLineSeries<ChartData, DateTime>(
                  name: 'CH${(index + 1).toString().padLeft(2, '0')}',
                  dataSource: _chartDataSeries[index],
                  markerSettings: MarkerSettings(isVisible: false),
                  xValueMapper: (ChartData data, _) => data.time,
                  yValueMapper: (ChartData data, _) => data.value,
                  color: _isVisibleSeries[index]
                      ? bkColor[index]
                      : Colors.transparent,
                ),
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
  void updateChartData(HotpadCtrl hotpadCtrl) {
    if (_isChartEnable == false) {
      return;
    }

    if ((hotpadCtrl.serialCtrl.serialPortStatus.index <
            SerialPortStatus.txBusy.index) ||
        (_graphCount++ % 10 != 0)) {
      return;
    }

    DateTime tmpDateTime = hotpadCtrl.serialCtrl.rxPackage.rxTime;
    for (int index = 0; index < 10; index++) {
      double value =
          double.tryParse(hotpadCtrl.serialCtrl.rxPackage.rtd[index]) ?? 0.0;
      _chartDataSeries[index].add(ChartData(tmpDateTime, value));
    }

    // HotpadData/yyyyMM/Graph 폴더의 SQLite 파일에 저장
    FileCtrl.saveGraphData(tmpDateTime, hotpadCtrl.serialCtrl.rxPackage.status,
        hotpadCtrl.serialCtrl.rxPackage.rtd);

    debugPrint(
        "Graph Data] [$tmpDateTime] ${hotpadCtrl.serialCtrl.rxPackage.status},${hotpadCtrl.serialCtrl.rxPackage.rtd}");

    // 그래프가 x축의 maximum 부근에 도달하면 maximum을 확장함.
    if (tmpDateTime
        .isAfter(_dateTimeAxis.maximum!.subtract(Duration(minutes: 1)))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DateTime tmpMax = DateTime.now().add(Duration(minutes: 60));
        int durationInTime =
            tmpMax.difference(_dateTimeAxis.minimum!).inMinutes;
        int interval = (durationInTime + 1) ~/ 12;

        _dateTimeAxis = DateTimeAxis(
          dateFormat: DateFormat.Hms(),
          intervalType: DateTimeIntervalType.minutes,
          interval: interval.toDouble(),
          minimum: _dateTime,
          maximum: tmpMax,
          plotOffsetStart: 5,
          plotOffsetEnd: 10,
          edgeLabelPlacement: EdgeLabelPlacement.shift,
          labelStyle: TextStyle(color: Colors.white),
        );
      });
    }
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
