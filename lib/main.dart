import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hotpadapp_v4/devices/hotpad_ctrl.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
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
import '../devices/serial_ctrl.dart';
import '../devices/file_ctrl.dart';
import '../providers/authentication_provider.dart';
import '../providers/language_provider.dart';
import '../providers/message_provider.dart';

void main() async {
  ui.DartPluginRegistrant.ensureInitialized();
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // final serialCtrlProvider = SerialCtrl();
  final languageProvider = LanguageProvider();
  final authProvider = AuthenticationProvider();
  final messageProvider = MessageProvider();
  // final hotpadCtrl = HotpadCtrl(serialCtrl: serialCtrlProvider, messageProvider: messageProvider);
  final hotpadCtrl = HotpadCtrl(messageProvider: messageProvider);

  await FileCtrl.checkFolder(messageProvider);
  await ConfigFileCtrl.initialize(); // ConfigFileCtrl 초기화
  await languageProvider.setLanguageFromDeviceConfig(); // 초기 언어 설정
  hotpadCtrl.initialize();

  // Register Syncfusion license
  SyncfusionLicense.registerLicense(
      "Ngo9BigBOggjHTQxAR8/V1NDaF5cWWtCf1FpRmJGdld5fUVHYVZUTXxaS00DNHVRdkdnWH1ednRWQ2hcWU1xV0I=");

  runApp(
    MultiProvider(
      providers: [
        // ChangeNotifierProvider(create: (context) => serialCtrlProvider),
        ChangeNotifierProvider(create: (context) => languageProvider),
        ChangeNotifierProvider(create: (context) => authProvider),
        ChangeNotifierProvider(create: (context) => messageProvider),
        ChangeNotifierProvider(create: (context) => hotpadCtrl),
        // 다른 providers
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
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
        return MaterialApp(
          title: 'HotpadApp_V4',
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
              thumbVisibility: WidgetStateProperty.all<bool>(true),
              trackVisibility: WidgetStateProperty.all<bool>(true),
              trackColor: WidgetStateProperty.all<Color>(Colors.white),
              thumbColor: WidgetStateProperty.all<Color>(Color(0xFF606060)),
              thickness: WidgetStateProperty.all<double>(20),
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
  String _currentTime = '';
  String _appBarTitle = 'Main Panel';
  String _appBarImage = iconHomePath;
  double _storageValue = 0.0;
  double _totalStorage = 0.0;
  double _usedStorage = 0.0;

  final PageController _pageController = PageController();
  final GlobalKey<GraphPageState> _graphPageKey = GlobalKey<GraphPageState>();
  final GlobalKey _repaintBoundaryKey = GlobalKey(); // RepaintBoundary Key
  static const platform = MethodChannel('internal_storage');

  @override
  void initState() {
    super.initState();
    _currentTime = _getCurrentTime();
    Timer.periodic(Duration(seconds: 1), (Timer t) => _updateTime());
    _updateStorageUsage();

    splashScreenDelay();

    // Set the context after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Provider.of<SerialCtrl>(context, listen: false).setContext(context);
      Provider.of<HotpadCtrl>(context, listen: false).setContext(context);
      Provider.of<HotpadCtrl>(context, listen: false).serialStart();
      Provider.of<HotpadCtrl>(context, listen: false).showAlarmMessage('SYS', '-', 'I0001');
    });
  }

  void splashScreenDelay() async{
    await Future.delayed(const Duration(seconds: 2));

    // Initial navigation to page 1
    _pageController.jumpToPage(1);

    // Delayed navigation back to page 0
    await Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _selectedIndex = 0;
        _updateAppBar(0);
      });
      _pageController.jumpToPage(0);
    });

    FlutterNativeSplash.remove();

  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  void _updateTime() {
    setState(() {
      _currentTime = _getCurrentTime();
    });
  }

  Future<void> _updateStorageUsage() async {
    try {
      final List<dynamic> result =
      await platform.invokeMethod('getIntStorageInfo');
      setState(() {
        _totalStorage = result[0] / (1024 * 1024); // MB 단위로 변환
        _usedStorage = result[1] / (1024 * 1024); // MB 단위로 변환
        _storageValue = _usedStorage / _totalStorage;
        debugPrint(
            "##### Internal Storage Info] $_totalStorage / $_usedStorage(${(_storageValue * 100).toStringAsFixed(1)})");
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to get USB storage info: '${e.message}'.");
    }
  }

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

  Future<void> _capturePng() async {
    try {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();
        String savedPath = await FileCtrl.screenShotsSave(pngBytes);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: savedPath.isNotEmpty
              ? Text('${languageProvider.getLanguageTransValue('Screenshot has been saved')} : $savedPath')
              : Text(languageProvider.getLanguageTransValue('Screenshot not saved')),
          duration: Duration(seconds: 5),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(languageProvider.getLanguageTransValue('Failed to capture image.')),
          duration: Duration(seconds: 5),
        ));
      }
    } catch (e) {
      debugPrint("$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _repaintBoundaryKey,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: MenuBarPage(
          barHeight: barHeight,
          currentTime: _currentTime,
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
            BackupPage(
              progressStorageValue: _storageValue,
              totalStorage: _totalStorage,
              usedStorage: _usedStorage,
            ),
            ControlPage(),
          ],
        ),
        bottomNavigationBar: StatusBarPage(
          barHeight: barHeight,
          progressStorageValue: _storageValue,
          totalStorage: _totalStorage,
          usedStorage: _usedStorage,
          onCtrlPressed: _navigateToControlPage,
        ),
      ),
    );
  }
}