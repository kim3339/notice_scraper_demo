import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:notice_scraper/origins/private.dart';
import 'package:pointycastle/export.dart';
import 'notice.dart';
import 'package:html/parser.dart' as parser;
import 'origins/cnu_cybercampus.dart' as cc;
import 'package:encrypt/encrypt.dart';

Future<List<Notice>> scrap() async {
  final client = http.Client();
  final cookies = <Cookie>[];

  // 로그인 페이지 접속 & 로그인 폼 데이터 추출
  var response = await client.get(Uri.https(cc.loginUri, "/login"));
  final inputs = getLoginFormInput(response.body);
  addCookies(cookies, response);

  // 로그인 요청을 위한 input 채우기
  inputs["user_id"] = id;
  inputs["user_password"] = encryptPassword(inputs['key']!, password);
  inputs["univ_no"] = "CNU";

  // 로그인 요청
  response = await client.post(
      Uri.https(cc.loginUri, "${cc.apiPath}/user/login"),
      headers: headerWithCookies(cookies),
      body: {'e': encryptData(inputs)});
  addCookies(cookies, response);

  // 사이버캠퍼스 접속

  // 공지 불러오기
  response = await client.post(
      Uri.https(cc.homeUri, "${cc.apiPath}/term/getYearTermList"),
      headers: headerWithCookies(cookies));

  final currentYearTerm = jsonDecode(response.body)["body"]['list']
      .firstWhere((element) => element['current_term_yn'] == "Y");

  final noticeRequestBody = {
    'type': 'notice',
    'term_cd': currentYearTerm['term_cd']!.toString(),
    'term_year': currentYearTerm['term_year']!.toString(),
    'limit': '100'
  };

  response = await client.post(
      Uri.https(cc.homeUri, "${cc.apiPath}/board/std/notice/list"),
      headers: headerWithCookies(cookies),
      body: {'e': encryptData(noticeRequestBody)});

  // 공지 파싱
  client.close();
  log("Notices loaded");
  return parseNotices(
      HtmlUnescape().convert(const Utf8Decoder().convert(response.bodyBytes)));
}

/* 
{
  "row_idx":1,
  "rseq":18,
  "course_id":"202310UN001214-201800",
  "course_nm":"ì»´í¨í°íë¡ê·¸
  ëë°3",
  "class_no":"00",
  "boarditem_no":"TB_L_BOARDITEM284434",
  "boarditem_title":"ì¤ê°ê³ ì¬ ê³µì§ì¬í­ìëë¤.",
  "top_yn":"N",
  "open_yn":null,
  "file_yn":"N",
  "insert_dt":"2023-04-17 15:36",
  "writeruserno":"plas_ta2",
  "read_yn":"N"
} 
*/

List<Notice> parseNotices(String json) => jsonDecode(json)['body']["list"]
    .map<Notice>((e) => Notice(
        title: "${e['course_nm']}: ${e['boarditem_title']}",
        datetime: DateTime.parse(e['insert_dt']),
        source: cc.homeUri))
    .toList();

Map<String, String> headerWithCookies(List<Cookie> cookies) =>
    Map.from(defaultHeader)..addAll({'Cookie': cookies.join('; ')});

String encryptData(Map<String, String> data) =>
    Encrypter(AES(Key.fromUtf8(cc.encryptKey), mode: AESMode.cbc))
        .encrypt(jsonEncode(data), iv: IV(Uint8List.fromList(cc.iv)))
        .base64
        .replaceAll(RegExp(r'[\r|\n]'), '');

List<Cookie> addCookies(List<Cookie> cookies, http.Response response) => cookies
  ..addAll(
      getCookies(response)?.map((e) => Cookie.fromSetCookieValue(e)) ?? []);

Iterable<String>? getCookies(http.Response response) =>
    response.headers["set-cookie"]
        ?.replaceAll(', ', r'\\')
        .split(',')
        .map((e) => e.replaceAll(r'\\', ', '));

String toCookieHeader(Iterable<Cookie> cookies) =>
    cookies.map((e) => "${e.name}=${e.value}").join('; ');

String encryptPassword(String key, String password) {
  final parsed = RSAKeyParser()
      .parse("-----BEGIN PUBLIC KEY-----\n$key\n-----END PUBLIC KEY-----");
  return Encrypter(
          RSA(publicKey: RSAPublicKey(parsed.modulus!, parsed.exponent!)))
      .encrypt(password, iv: IV(Uint8List.fromList(cc.iv)))
      .base64;
}

Map<String, String> getLoginFormInput(String html) =>
    parser.parse(html).querySelectorAll('form[name=loginForm] input').fold(
        <String, String>{},
        (m, e) =>
            m..addAll({e.attributes["name"]!: e.attributes["value"] ?? ""}))
      ..removeWhere((key, value) => value == "");

const defaultHeader = {
  "Accept": "*/*",
  'Accept-Encoding': 'gzip, deflate, br',
  'Accept-Language':
      'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7,ja;q=0.6,zh-CN;q=0.5,zh;q=0.4',
  'Connection': 'keep-alive',
  "User-Agent":
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36",
  "X-Requested-With": "XMLHttpRequest",
  'sec-ch-ua':
      '"Chromium";v="112", "Google Chrome";v="112", "Not:A-Brand";v="99"',
  'sec-ch-ua-mobile': '?0',
  'sec-ch-ua-platform': '"Windows"',
  'Sec-Fetch-Dest': 'empty',
  'Sec-Fetch-Mode': 'cors',
  'Sec-Fetch-Site': 'same-origin',
};
