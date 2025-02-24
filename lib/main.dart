
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hotpadapp_v4/devices/usb_copy_ctrl.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import '../devices/hotpad_ctrl.dart';
import '../constant/user_style.dart';
import '../screens/alarm_page.dart';
import '../screens/backup_page.dart';
import '../screens/control_page.dart';
import '../screens/home_page.dart';
import '../screens/graph_page.dart';
import '../screens/settings_page.dart';
import '../screens/menubar_page.dart';
import '../screens/statusbar_page.dart';
import '../devices/config_file_ctrl.dart';
import '../devices/file_ctrl.dart';
import '../providers/authentication_provider.dart';
import '../providers/language_provider.dart';
import '../providers/message_provider.dart';

Future main() async {
  // 플러그인(ex. 파일시스템 접근, 카메라, GPS 등등)이 네이티브 코드와 통신할 수 있도록 초기화하는 역할
  ui.DartPluginRegistrant.ensureInitialized();
  // Flutter의 위젯 바인딩이 초기화되었는지 확인
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // 초기화가 완료될 때까지 스플래시 화면 유지
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 프로바이더 및 컨트롤러 초기화
  final languageProvider = LanguageProvider();
  final authProvider = AuthenticationProvider();
  final messageProvider = MessageProvider();
  final hotpadCtrlProvider = HotpadCtrl(messageProvider: messageProvider);
  final usbCopyCtrlProvider = UsbCopyCtrl();

  await FileCtrl.checkFolder(messageProvider);          // 폴더 확인 및 생성
  await ConfigFileCtrl.check();                         // Hotpad Setup Data check & load
  await languageProvider.setLanguageFromDeviceConfig(); // 언어 데이터 가져오기
  await hotpadCtrlProvider.initialize();                        // Hotpad 컨트롤러 초기화

  // Syncfusion license 등록
  SyncfusionLicense.registerLicense(
      "Ngo9BigBOggjHTQxAR8/V1NDaF5cWWtCf1FpRmJGdld5fUVHYVZUTXxaS00DNHVRdkdnWH1ednRWQ2hcWU1xV0I=");

  // 다중 프로바이더와 함께 애플리케이션 실행
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => languageProvider),
        ChangeNotifierProvider(create: (context) => authProvider),
        ChangeNotifierProvider(create: (context) => messageProvider),
        ChangeNotifierProvider(create: (context) => usbCopyCtrlProvider),
        ChangeNotifierProvider(create: (context) => hotpadCtrlProvider
),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        // 시스템 UI를 완전히 숨기고 전체 화면 모드를 활성화
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
        // Material Design3 기반으로 앱 전체의 테마를 설정
        return MaterialApp(
          // title: 'HotpadApp_V4',
          theme: ThemeData(
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: backgroundColor,
            ),
            scaffoldBackgroundColor: backgroundColor,
            bottomAppBarTheme: const BottomAppBarTheme(
              color: backgroundColor,
            ),
            scrollbarTheme: ScrollbarThemeData(
              thumbVisibility: MaterialStateProperty.all<bool>(true),
              trackVisibility: MaterialStateProperty.all<bool>(true),
              trackColor: MaterialStateProperty.all<Color>(Colors.white),
              thumbColor: MaterialStateProperty.all<Color>(Color(0xFF606060)),
              thickness: MaterialStateProperty.all<double>(20),
              crossAxisMargin: 1,
            ),
          ),
          home: MainPage(),
        );
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  String _appBarTitle = 'Main Panel';
  String _appBarImage = iconHomePath;

  // 페이지 이동을 위한 컨트롤러
  final PageController _pageController = PageController();
  // GraphPage에 대한 키
  final GlobalKey<GraphPageState> _graphPageKey = GlobalKey<GraphPageState>();
  // 스크린샷 캡처에 사용하는 RepaintBoundary의 키
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // 위젯이 빌드된 후 컨텍스트 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hotpadCtrlProvider = Provider.of<HotpadCtrl>(context, listen: false);
      hotpadCtrlProvider.setContext(context);
      hotpadCtrlProvider.serialStart();
      hotpadCtrlProvider.showAlarmMessage('SYS', '-', 'I0001');
    });

    splashScreenDelay();
  }

  /***********************************************************************
   *          스플래시 화면 지연을 처리하는 함수
   ***********************************************************************////
  void splashScreenDelay() async{
    await Future.delayed(const Duration(seconds: 2));

    // 처음에 페이지 1로 이동
    _pageController.jumpToPage(1);

    // 지연 후 페이지 0으로 다시 이동
    await Future.delayed(const Duration(seconds: 2), () {
      _onItemTapped(0);
    });

    // 스플래시 화면 제거
    FlutterNativeSplash.remove();
  }

  /***********************************************************************
   *          MenuBar 항목 탭을 처리하는 함수
   ***********************************************************************////
  void _onItemTapped(int index) {
    final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
    setState(() {
      _selectedIndex = index;
      if(index != 2) {
        authProvider.logout();
      }
      _updateAppBar(index);
    });
    _pageController.jumpToPage(index);
  }

  /***********************************************************************
   *          선택된 인덱스에 따라 앱 바 제목과 이미지를 업데이트하는 함수
   ***********************************************************************////
  void _updateAppBar(int index) {
    switch (index) {
      case 0:
        _appBarTitle = 'Main Panel';
        _appBarImage = iconHomePath;
        break;
      case 1:
        _appBarTitle = 'Graph View';
        _appBarImage = iconGraphPath;
        break;
      case 2:
        _appBarTitle = 'Setup';
        _appBarImage = iconSetupPath;
        break;
      case 3:
        _appBarTitle = 'Event View';
        _appBarImage = iconAlarmPath;
        break;
      case 4:
        _appBarTitle = 'File Backup View';
        _appBarImage = iconBackupPath;
        break;
      case 5:
        _appBarTitle = 'Control Setup';
        _appBarImage = iconSetupPath;
        break;
      default:
        _appBarTitle = 'Main Panel';
        _appBarImage = iconHomePath;
        break;
    }
  }

  /***********************************************************************
   *          인증을 통해 Control 페이지로 이동하는 함수
   ***********************************************************************////
  Future<void> _navigateToControlPage() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
    bool authenticated = await authProvider.showPasswordPrompt(context, languageProvider, ConfigFileCtrl.deviceConfigAdminPassword);

    if (authenticated) {
      setState(() {
        _selectedIndex = 5;
        _updateAppBar(5);
      });
      authProvider.logout();
      _pageController.jumpToPage(5);
    }
  }

  /***********************************************************************
   *          현재 화면의 스크린샷을 캡처하는 함수
   ***********************************************************************////
  Future<void> _capturePng() async {
    try {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      // 프레임이 완전히 렌더링된 후 스크린 샷을 캡쳐해야 함.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        RenderRepaintBoundary boundary =
          _repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage();
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          Uint8List pngBytes = byteData.buffer.asUint8List();
          String savedPath = await FileCtrl.screenShotsSave(pngBytes);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: savedPath.isNotEmpty
              ? Text('${languageProvider.getLanguageTransValue('Screenshot has been saved')} : $savedPath',
              textAlign: TextAlign.center)
              : Text(languageProvider.getLanguageTransValue('Screenshot not saved'),
              textAlign: TextAlign.center),
            duration: Duration(seconds: 5),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(languageProvider.getLanguageTransValue('Failed to capture image.'),
              textAlign: TextAlign.center),
            duration: Duration(seconds: 5),
          ));
        }
      });
    } catch (e) {
      debugPrint("$e");
    }
  }

  /***********************************************************************
   *          GUI 기본 구조
   ***********************************************************************////
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _repaintBoundaryKey,
      child: Stack(
        children: [
          Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: MenuBarPage(
              barHeight: barHeight,
              title: _appBarTitle,
              imagePath: _appBarImage,
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
              onCapturePressed: _capturePng,
              graphPageKey: _graphPageKey,
            ),
            body: PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),    // 스와이프 동작을 막음
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                  _updateAppBar(index);
                });
              },
              children: [
                HomePage(),
                GraphPage(key: _graphPageKey),
                SettingsPage(),
                AlarmPage(),
                BackupPage(),
                ControlPage(),
              ],
            ),
            bottomNavigationBar: StatusBarPage(
              barHeight: barHeight,
              onCtrlPressed: _navigateToControlPage,
            ),
          ),
          Consumer2<UsbCopyCtrl, HotpadCtrl>(
            builder: (context, usbCopyCtrlProvider, hotpadCtrlProvider,child) {
              if (usbCopyCtrlProvider.isIndicator || hotpadCtrlProvider.isIndicator) {
                return Stack(
                  children: [
                    Opacity(
                      opacity: 0.3,
                      child: ModalBarrier(dismissible: false, color: Colors.black),
                    ),
                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(strokeWidth: 15),
                      ),
                    ),
                  ],
                );
              } else {
                return SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }
}