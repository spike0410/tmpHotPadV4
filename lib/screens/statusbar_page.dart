import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constant/user_style.dart';
import '../devices/hotpad_ctrl.dart';
import '../devices/config_file_ctrl.dart';
import '../devices/logger.dart';
import '../providers/language_provider.dart';

class StatusBarPage extends StatefulWidget {
  final double barHeight;
  final VoidCallback onCtrlPressed;

  const StatusBarPage({super.key,
    required this.barHeight,
    required this.onCtrlPressed,
  });

  @override
  State<StatusBarPage> createState() => _StatusBarPageState();
}

class _StatusBarPageState extends State<StatusBarPage> {
  bool isDebugMode = false;
  bool isBtn = false;
  int countDebugMode = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async{
    isDebugMode = await Logger.loadStartLoggerFlag();
    isBtn = false;
    countDebugMode = 0;
  }

  @override
  Widget build(BuildContext context) {
    // LanguageProvider와 HotpadCtrl 프로바이더를 가져옴
    final languageProvider = Provider.of<LanguageProvider>(context);
    final hotpadCtrlProvider = Provider.of<HotpadCtrl>(context);

    return Container(
      height: widget.barHeight,
      width: double.infinity,
      padding: EdgeInsets.only(left: 10, right: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            barBackgroundColor,
            gBarBackgroundColor,
          ],
        ),
      ),
      child: SizedBox.expand(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 컨트롤러 버튼
            IconButton(
              icon: (ConfigFileCtrl.deviceConfigLanguage == 'Kor') ? Image.asset(shiLogPathKor, height: 40) : Image.asset(shiLogPath, height: 40),
              onPressed: widget.onCtrlPressed,
            ),
            SizedBox(width: 50),
            // 컨트롤러 번호 텍스트
            SizedBox(
              child: FilledButton(
                onPressed: (){
                  if(isBtn == true){
                    countDebugMode++;
                  }
                },
                onLongPress: () async{
                  if(isBtn == false){
                    isBtn = true;
                    countDebugMode = 0;
                  }
                  else{
                    if(countDebugMode >= 7){
                      setState(() {
                        isDebugMode = !isDebugMode;
                      });
                      await Logger.saveStartLoggerFlag(isDebugMode);
                      isBtn = false;
                      if(isDebugMode){
                        Logger.start();
                      }
                      else{
                        Logger.dispose();
                      }
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: isDebugMode
                            ? Text('### Logger Start ###', textAlign: TextAlign.center)
                            : Text('### Logger End ###', textAlign: TextAlign.center),
                        duration: Duration(seconds: 5),
                      ));
                    }
                  }
                },
                style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.transparent)),
                child: Text(
                  '${languageProvider.getLanguageTransValue('Controller No.')} ${ConfigFileCtrl.deviceConfigNumber.toString().padLeft(3,'0')}',
                  style: TextStyle(color: Colors.black ,fontSize: (defaultFontSize + 4), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            isDebugMode == true
                ? Icon(Icons.admin_panel_settings, size: 50)
                : SizedBox(width: 50),
            // 내부 온도 및 전력 텍스트
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${languageProvider.getLanguageTransValue('Internal Temp.')} : ${hotpadCtrlProvider.serialCtrl.rxPackage.intTemp}℃',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 3),
                SizedBox(
                  width: 170,
                  child: Text(
                    '${languageProvider.getLanguageTransValue('Internal Power')} : '
                        '${hotpadCtrlProvider.serialCtrl.rxPackage.dcVolt}V/'
                        '${hotpadCtrlProvider.serialCtrl.rxPackage.dcCrnt}A',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            // 저장소 정보 영역
            Row(
              children: [
                SizedBox(
                  height: 40,
                  child: Image.asset(diskPath),
                ),
                SizedBox(width: 5),
                Consumer<HotpadCtrl>(
                  builder: (context, hotpadCtrlProvider, _){
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${(hotpadCtrlProvider.usedStorage / 1024).toStringAsFixed(1)}/${(hotpadCtrlProvider.totalStorage / 1024).toStringAsFixed(1)} GB'),
                        Stack(
                          children: [
                            SizedBox(
                              width: 100,
                              height: 20,
                              child: LinearProgressIndicator(
                                value: hotpadCtrlProvider.storageProgressValue,
                                backgroundColor: Colors.white,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006400)),
                              ),
                            ),
                            Positioned.fill(
                              child: Center(
                                child: Text(
                                  '${(hotpadCtrlProvider.storageProgressValue * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
