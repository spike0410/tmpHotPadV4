import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../devices/config_file_ctrl.dart';
import '../providers/language_provider.dart';

class AuthenticationProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  Timer? _timer;

  // 인증 상태를 반환하는 getter
  bool get isAuthenticated => _isAuthenticated;
  // 인증 상태를 true로 설정하고, Listeners에게 알림
  void authenticate() {
    _isAuthenticated = true;
    notifyListeners();
  }

  // 인증 상태를 false로 설정하고, Listeners에게 알림
  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }

  /***********************************************************************
   *          비밀번호 입력 프롬프트를 표시하는 함수
   *
   *    - 타이머를 사용하여 일정 시간 후 다이얼로그 닫기
   ***********************************************************************////
  Future<bool> showPasswordPrompt(BuildContext context, LanguageProvider languageProvider, String password) async {
    TextEditingController passwordController = TextEditingController();
    String passwordMsg = '';

    // 비밀번호를 인증하는 함수
    void authenticate(StateSetter setState) {
      if (passwordController.text == password) {
        if(password != ConfigFileCtrl.deviceConfigAdminPassword) {
          this.authenticate();
        }
        Navigator.of(context).pop(true);
      } else {
        if(password != ConfigFileCtrl.deviceConfigAdminPassword) {
          logout();
        }
        setState(() {
          passwordMsg = languageProvider.getLanguageTransValue('The password does not match.');
        });
        _timer = Timer(Duration(seconds: 3), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(false);
          }
        });
      }
    }

    /***********************************************************************
     *          비밀번호 입력 다이얼로그를 표시
     ***********************************************************************////
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(languageProvider.getLanguageTransValue('Enter Password')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Password',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onSubmitted: (_) => authenticate(setState), // 가상 키보드의 확인 버튼을 눌렀을 때
              ),
              SizedBox(height: 10),
              Text(
                passwordMsg,
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(languageProvider.getLanguageTransValue('Cancel')),
            ),
            TextButton(
              onPressed: () => authenticate(setState), // OK 버튼을 눌렀을 때
              child: Text(languageProvider.getLanguageTransValue('OK')),
            ),
          ],
        ),
      ),
    ).then((value){
      // 다이얼로그가 프로그래밍적으로 닫힐 때 타이머를 취소합니다.
      _timer?.cancel();
      return value;
    });

    return result ?? false;   // 다이얼로그의 결과를 반환
  }
}