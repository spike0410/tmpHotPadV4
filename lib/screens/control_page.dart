import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constant/user_style.dart';
import '../screens/system_tab.dart';
import '../screens/ctrl_fault_diagnosis_tab.dart';
import '../screens/ctrl_temp_control.dart';
import '../screens/ctrl_vc_control.dart';
import '../providers/language_provider.dart';

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int activeTabIndex = 0;

  @override
  void dispose() {
    // TabController를 해제
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // TabController를 초기화
    _tabCtrl = TabController(
      length: 4,
      initialIndex: 0,
      vsync: this,
    );
    // TabController의 Listener를 추가하여 탭 변경 시 상태를 업데이트
    _tabCtrl.addListener(() {
      setState(() {
        activeTabIndex = _tabCtrl.index;
      });
    });
  }

  /***********************************************************************
   *          TabBar를 생성하는 함수
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
      Tab(
        height: tabBarHeight,
        child: Container(
          decoration: BoxDecoration(
            color:
            activeTabIndex == 0 ? tabSelectedColor : tabUnselectedColor,
          ),
          child: Align(
            alignment: Alignment.center,
            child: Text(languageProvider.getLanguageTransValue('Fault Diagnosis')),
          ),
        ),
      ),
      Tab(
        height: tabBarHeight,
        child: Container(
          decoration: BoxDecoration(
            color:
            activeTabIndex == 1 ? tabSelectedColor : tabUnselectedColor,
          ),
          child: Align(
            alignment: Alignment.center,
            child: Text(languageProvider.getLanguageTransValue('Temp. Control')),
          ),
        ),
      ),
      Tab(
        height: tabBarHeight,
        child: Container(
          decoration: BoxDecoration(
            color:
            activeTabIndex == 2 ? tabSelectedColor : tabUnselectedColor,
          ),
          child: Align(
            alignment: Alignment.center,
            child: Text(languageProvider.getLanguageTransValue('Voltage/Current Cal.')),
          ),
        ),
      ),
      Tab(
        height: tabBarHeight,
        child: Container(
          decoration: BoxDecoration(
            color:
            activeTabIndex == 3 ? tabSelectedColor : tabUnselectedColor,
          ),
          child: Align(
            alignment: Alignment.center,
            child: Text(languageProvider.getLanguageTransValue('System Info.')),
          ),
        ),
      ),
    ],
  );


  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return DefaultTabController(
      length: 4,
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
            CtrlFaultDiagnosisTab(),
            CtrlTempControl(),
            CtrlVCControl(),
            // SystemTab() 클래스 사용할 때 관리자 모드임을 알려줌.
            SystemTab(isAdmin: true),
          ],
        ),
      ),
    );
  }
}
