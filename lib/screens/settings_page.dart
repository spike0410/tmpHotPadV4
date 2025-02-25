import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../devices/config_file_ctrl.dart';
import '../screens/temp_settings_tab.dart';
import '../screens/temp_cal_tab.dart';
import '../screens/system_tab.dart';
import '../constant/user_style.dart';
import '../providers/language_provider.dart';
import '../providers/authentication_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int activeTabIndex = 0;

  @override
  void dispose() {
    // TabController 해제
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // TabController 초기화
    _tabCtrl = TabController(length: 3, initialIndex: 0, vsync: this);
    // Tab 변경 Listener 추가
    _tabCtrl.addListener(() async {
      if (_tabCtrl.indexIsChanging) {
        final newIndex = _tabCtrl.index;
        // 첫 번째 탭이 아닌 경우 인증 필요
        if (newIndex != 0 && !Provider.of<AuthenticationProvider>(context, listen: false).isAuthenticated) {
          final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
          final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
          final authenticated = await authProvider.showPasswordPrompt(context, languageProvider, ConfigFileCtrl.deviceConfigUserPassword);

          if (!authenticated) {
            _tabCtrl.index = activeTabIndex; // 탭을 원래 인덱스로 되돌림
          }
          else {
            Provider.of<AuthenticationProvider>(context, listen: false).authenticate();
            setState(() {
              activeTabIndex = newIndex; // 탭 이동 허용
            });
          }
        }
        else {
          setState(() {
            activeTabIndex = newIndex; // 탭 이동 허용
          });
        }
      }
    });
  }
  /***********************************************************************
   *          TabBar 생성하는 함수
   ***********************************************************************////
  TabBar _buildTabBar(LanguageProvider languageProvider) => TabBar(
    controller: _tabCtrl,
    labelStyle: TextStyle(
      color: Colors.black,
      fontSize: (defaultFontSize + 6),
      fontWeight: FontWeight.bold,
    ),
    indicatorColor: Colors.transparent,
    dividerColor: Colors.grey,
    dividerHeight: 2,
    tabs: [
      /// ### Temp.Setting
      Tab(
        height: tabBarHeight,
        child: Container(
          decoration: BoxDecoration(
            color: activeTabIndex == 0 ? tabSelectedColor : tabUnselectedColor,
          ),
          child: Align(
            alignment: Alignment.center,
            child: Text(languageProvider.getLanguageTransValue('Temp.Setting')),
          ),
        ),
      ),
      /// ### Temp.Cal.
      Tab(
        height: tabBarHeight,
        child: Container(
          decoration: BoxDecoration(
            color: activeTabIndex == 1 ? tabSelectedColor : tabUnselectedColor,
          ),
          child: Align(
            alignment: Alignment.center,
            child: Text(languageProvider.getLanguageTransValue('Temp.Cal.')),
          ),
        ),
      ),
      /// ### System
      Tab(
        height: tabBarHeight,
        child: Container(
          decoration: BoxDecoration(
            color: activeTabIndex == 2 ? tabSelectedColor : tabUnselectedColor,
          ),
          child: Align(
            alignment: Alignment.center,
            child: Text(languageProvider.getLanguageTransValue('System')),
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: _buildTabBar(languageProvider).preferredSize,
          child: ColoredBox(
            color: Colors.white,
            child: _buildTabBar(languageProvider),
          ),
        ),
        body: TabBarView(
          controller: _tabCtrl,
          physics: NeverScrollableScrollPhysics(),    // 스와이프 동작을 막음
          children: [
            TempSettingsTab(),
            TempCalTab(),
            // SystemTab() 클래스 사용할 때 사용자 모드임을 알려줌.
            SystemTab(isAdmin: false),
          ],
        ),
      ),
    );
  }
}
