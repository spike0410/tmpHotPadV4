import 'package:flutter/material.dart';
import 'package:hotpadapp_v4/devices/hotpad_ctrl.dart';
import 'package:provider/provider.dart';
import '../constant/user_style.dart';
import '../devices/config_file_ctrl.dart';
import '../providers/language_provider.dart';

class StatusBarPage extends StatelessWidget {
  final double barHeight;
  final double progressStorageValue;
  final double totalStorage;
  final double usedStorage;
  final VoidCallback onCtrlPressed;

  const StatusBarPage({super.key,
    required this.barHeight,
    required this.progressStorageValue,
    required this.totalStorage,
    required this.usedStorage,
    required this.onCtrlPressed,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final hotpadCtrlProvider = Provider.of<HotpadCtrl>(context);

    return Container(
      height: barHeight,
      width: double.infinity,
      padding: EdgeInsets.only(left: 10, right: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            barBackgroundColor,
            gbarBackgroundColor,
          ],
        ),
      ),
      child: SizedBox.expand(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: (ConfigFileCtrl.deviceConfigLanguage == 'Kor') ? Image.asset(shiLogPath_kor, height: 40) : Image.asset(shiLogPath, height: 40),
              onPressed: onCtrlPressed,
            ),
            SizedBox(width: 50),
            Text(
              '${languageProvider.getLanguageTransValue('Controller No.')} ${ConfigFileCtrl.deviceConfigNumber.toString().padLeft(3,'0')}',
              style: TextStyle(
                fontSize: (defaultFontSize + 4),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 50),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${languageProvider.getLanguageTransValue('Internal Temp.')} : ${hotpadCtrlProvider.serialCtrl.rxPackage.intTemp}℃',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '${languageProvider.getLanguageTransValue('Internal Power')} : '
                      '${hotpadCtrlProvider.serialCtrl.rxPackage.dcVolt}V/'
                      '${hotpadCtrlProvider.serialCtrl.rxPackage.dcCrnt}A',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                SizedBox(
                  height: 40,
                  child: Image.asset(diskPath),
                ),
                SizedBox(width: 5),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        '${(usedStorage / 1024).toStringAsFixed(1)}/${(totalStorage / 1024).toStringAsFixed(1)} GB'),
                    Stack(
                      children: [
                        SizedBox(
                          width: 100,
                          height: 20,
                          child: LinearProgressIndicator(
                            // value: progressStorageValue,
                            value: progressStorageValue,
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF006400)),
                          ),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: Text(
                              '${(progressStorageValue * 100).round()}%',
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
