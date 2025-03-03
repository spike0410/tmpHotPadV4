import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../constant/user_style.dart';
import '../providers/message_provider.dart';

class AlarmPage extends StatelessWidget {
  const AlarmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AlarmTable(),
    );
  }
}

class AlarmTable extends StatefulWidget {
  const AlarmTable({super.key});

  @override
  AlarmTableState createState() => AlarmTableState();
}

class AlarmTableState extends State<AlarmTable> {
  final TextStyle _textStyle = TextStyle(
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    // LanguageProvider와 MessageProvider를 가져옴
    final languageProvider = Provider.of<LanguageProvider>(context);
    final messageProvider = Provider.of<MessageProvider>(context);

    return Container(
      margin: EdgeInsets.all(10),
      height: double.infinity,
      decoration: BoxDecoration(color: Colors.black),
      /**********************************
       *        ScrollBar
       **********************************/
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          primary: true,
          scrollDirection: Axis.vertical,
          padding: EdgeInsets.only(right: 22),
          /**********************************
           *        DataTable
           **********************************/
          child: DataTable(
            border: TableBorder.all(color: Colors.grey),
            headingRowColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
                return gBarBackgroundColor; // 헤더 배경색 적용
              },
            ),
            headingRowHeight: 40,
            headingTextStyle: _textStyle,
            dataTextStyle: _textStyle,
            /**********************************
             *        DataTable Header
             **********************************/
            columns: [
              DataColumn(
                  label: SizedBox(
                      width: 50,
                      child: Text(languageProvider.getLanguageTransValue('NO.'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))),
              DataColumn(
                  label: SizedBox(
                      width: 50,
                      child: Text(languageProvider.getLanguageTransValue('Channel'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))),
              DataColumn(
                  label: SizedBox(
                      width: 100,
                      child: Text('HotPad',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))),
              DataColumn(
                  label: SizedBox(
                      width: 372,
                      child: Text(languageProvider.getLanguageTransValue('Descriptions'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))),
              DataColumn(
                  label: SizedBox(
                      width: 125,
                      child: Text(languageProvider.getLanguageTransValue('Date Time'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))),
            ],
            /**********************************
             *        DataTable Data
             **********************************/
            rows: messageProvider.data.map((data) {
              return DataRow(cells: [
                DataCell(Center(child: Text(data['NO.']!))),
                DataCell(Center(child: Text(data['Channel']!))),
                DataCell(Center(child: Text(data['HotPad']!))),
                // Data 출력시 사용된 code를 언어 설정에 맞게 출력
                DataCell(Text(languageProvider.getMessageTransValue(data['Descriptions']!),
                      softWrap: true)),
                DataCell(Center(child: Text(data['Date Time']!))),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
