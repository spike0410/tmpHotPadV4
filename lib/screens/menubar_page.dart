import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constant/user_style.dart';
import '../devices/hotpad_ctrl.dart';
import '../screens/graph_page.dart';
import '../devices/config_file_ctrl.dart';

enum LanguageEnum { kor, eng }

class MenuBarPage extends StatelessWidget implements PreferredSizeWidget {
  final double barHeight;
  final String title;
  final String imagePath;
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onCapturePressed; // 추가된 콜백 함수
  final GlobalKey<GraphPageState> graphPageKey;

  const MenuBarPage({
    super.key,
    required this.barHeight,
    required this.title,
    required this.imagePath,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onCapturePressed,
    required this.graphPageKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // 그라데이션 배경 설정
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
      // 왼쪽 패딩을 설정
      padding: EdgeInsets.only(left: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // 이미지 설정
                  Image.asset(imagePath, width: menuBtnHeight, height: menuBtnWidth),
                  SizedBox(width: 10),
                  // 타이틀 및 현재 시간 표시
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(color: titleTextColor, fontSize: 34, fontWeight: FontWeight.bold),
                      ),
                      Consumer<HotpadCtrl>(
                          builder: (context, hotpadCtrl, _) {
                            return Text(
                              hotpadCtrl.getCurrentTimeValue(),
                              style: TextStyle(fontSize: defaultFontSize),
                            );
                          },
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  selectedIndex <= 7        // <---!@# Test
                  // selectedIndex == 0
                    ? Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 언어 선택 아이콘 버튼
                      IconButton(
                        icon: Image.asset(iconLanguagePath, width: 40, height: 30),
                        onPressed: () {
                          _showLanguageDialog(context);
                        },
                      ),
                      Text(
                        'Ver $swVersion', // 소프트웨어 버전
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  )
                  : SizedBox(width: 56),
                  SizedBox(width: 10),
                  _buildZoomIcons(),
                  SizedBox(width: 10),
                  _buildMenuIcons(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;
    LanguageEnum languageEnum = (ConfigFileCtrl.deviceConfigLanguage == 'Kor')
        ? LanguageEnum.kor
        : LanguageEnum.eng;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              child: Container(
                width: (screenWidth * 0.45),
                height: (screenHeight * 0.8),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(LanguageBackgroundPath), // 사용자 이미지 경로
                    fit: BoxFit.fill,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 200),
                    _titleRadio(
                      text: '한국어',
                      width: 200,
                      value: LanguageEnum.kor,
                      groupValue: languageEnum,
                      onChanged: (value) {
                        setState(() {
                          languageEnum = value!;
                        });
                        ConfigFileCtrl.deviceConfigLanguage = 'Kor';
                        ConfigFileCtrl.setLanguageData(context);
                      },
                    ),
                    SizedBox(height: 60),
                    _titleRadio(
                      text: 'English',
                      width: 200,
                      value: LanguageEnum.eng,
                      groupValue: languageEnum,
                      onChanged: (value) {
                        setState(() {
                          languageEnum = value!;
                        });
                        ConfigFileCtrl.deviceConfigLanguage = 'Eng';
                        ConfigFileCtrl.setLanguageData(context);
                      },
                    ),
                    SizedBox(height: 120),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon:
                      Image.asset(iconCloseBtnPath, width: 70, height: 70),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 줌 아이콘 생성
  Widget _buildZoomIcons() {
    return Row(
      children: [
        selectedIndex == 1
            ? IconButton(
          icon: Image.asset(iconZoomOutPath,
              width: zoomBtnHeight, height: zoomBtnWidth),
          onPressed: () {
            graphPageKey.currentState?.zoomOut();
          },
        )
            : SizedBox(width: 56),
        selectedIndex == 1
            ? IconButton(
          icon: Image.asset(iconZoomZeroPath,
              width: zoomBtnHeight, height: zoomBtnWidth),
          onPressed: () {
            graphPageKey.currentState?.resetZoom();
          },
        )
            : SizedBox(width: 56),
        selectedIndex == 1
            ? IconButton(
          icon: Image.asset(iconZoomInPath,
              width: zoomBtnHeight, height: zoomBtnWidth),
          onPressed: () {
            graphPageKey.currentState?.zoomIn();
          },
        )
            : SizedBox(width: 56),
      ],
    );
  }

  // 메뉴 아이콘 생성
  Widget _buildMenuIcons() {
    return Row(
      children: [
        _buildToggleButton(iconHomePath, 0),
        SizedBox(width: 10),
        _buildToggleButton(iconGraphPath, 1),
        SizedBox(width: 10),
        _buildToggleButton(iconSetupPath, 2),
        SizedBox(width: 10),
        _buildToggleButton(iconAlarmPath, 3),
        SizedBox(width: 10),
        _buildToggleButton(iconBackupPath, 4),
        IconButton(
          icon: Image.asset(iconCapturePath,
              width: menuBtnHeight, height: menuBtnWidth),
          onPressed: onCapturePressed,
        ),
      ],
    );
  }

  // 토글 버튼 생성
  Widget _buildToggleButton(String iconPath, int index) {
    return GestureDetector(
      onTap: () => onItemTapped(index),
      // 원형으로 자르기
      child: ClipOval(
        child: ColorFiltered(
          // 선택된 인덱스에 따라 색상 필터링
          colorFilter: selectedIndex == index
              ? ColorFilter.mode(Colors.grey, BlendMode.color)
              : ColorFilter.mode(Colors.transparent, BlendMode.srcATop),
          child: Image.asset(
            iconPath,
            width: menuBtnHeight,
            height: menuBtnWidth,
          ),
        ),
      ),
    );
  }

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
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  // AppBar의 높이를 설정합니다. barHeight 변수의 값을 사용하여 높이를 결정합니다.
  Size get preferredSize => Size.fromHeight(barHeight);
}
