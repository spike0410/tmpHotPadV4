import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../devices/config_file_ctrl.dart';
import '../providers/language_provider.dart';

class AuthenticationProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  Timer? _timer;

  bool get isAuthenticated => _isAuthenticated;

  void authenticate() {
    _isAuthenticated = true;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<bool> showPasswordPrompt(BuildContext context, LanguageProvider languageProvider, String password) async {
    TextEditingController passwordController = TextEditingController();
    String passwordMsg = '';

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
        // Future.delayed(Duration(seconds: 3), () {
        //   Navigator.of(context).pop(false);   // Close the dialog after 3 seconds
        // });
        _timer = Timer(Duration(seconds: 3), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(false);
          }
        });
      }
    }

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

    return result ?? false;
  }
}