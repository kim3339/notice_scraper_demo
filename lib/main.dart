import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:notice_scraper/notice.dart';
import 'package:notice_scraper/notice_widget.dart';
import 'scraper.dart' as scraper;

final List<Request> sequence = [Request('get', Uri.base)];

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notice Scraper',
      theme: ThemeData(
        textTheme: GoogleFonts.nanumGothicTextTheme(),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
          textTheme: GoogleFonts.nanumGothicTextTheme(),
          useMaterial3: true,
          brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      home: const HomePage(title: 'Notice Scraper Demo'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  HomePageState() : notices = [] {
    getNotice();
  }

  List<Notice> notices;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: NoticeList(notices: notices),
      floatingActionButton: FloatingActionButton(
          onPressed: getNotice, child: const Icon(Icons.refresh)),
    );
  }

  void getNotice() =>
      scraper.scrap().then((value) => setState(() => notices = value));
}
