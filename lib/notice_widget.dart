import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'notice.dart';

class NoticeList extends StatelessWidget {
  const NoticeList({super.key, required this.notices});
  final List<Notice> notices;
  @override
  Widget build(BuildContext context) {
    return ListView(
        children: notices
            .map((e) => Column(
                children: [NoticeView(notice: e), Container(height: 10)]))
            .toList());
  }
}

class NoticeView extends StatelessWidget {
  const NoticeView({super.key, required this.notice});

  final Notice notice;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
        onPressed: () => _buildNoticeDialog(context, notice),
        style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).cardColor,
            elevation: 4,
            shape: const LinearBorder()),
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.justify,
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  height: 10,
                ),
                Row(children: [
                  Text(
                    DateFormat.yMMMd().format(notice.datetime),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Expanded(
                      child: Text(
                    notice.source,
                    style: Theme.of(context).textTheme.labelLarge,
                    textAlign: TextAlign.right,
                  ))
                ])
              ],
            )));
  }
}

Future<void> _buildNoticeDialog(BuildContext context, Notice notice) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        contentPadding: const EdgeInsets.all(20),
        children: [
          Text(
            notice.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Expanded(
              child: Text(
            DateFormat.yMMMd().format(notice.datetime),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.right,
          )),
          const Divider(
            height: 30,
          ),
          Row(children: [
            Expanded(
                child: Text(
              notice.source,
              style: Theme.of(context).textTheme.bodyLarge,
            )),
            FilledButton(
                onPressed: () => _launchUrl(notice.source),
                child: const Text("사이트 접속"))
          ]),
        ],
      );
    },
  );
}

Future<void> _launchUrl(String source) async {
  if (!await launchUrl(Uri.https(source))) {
    throw Exception('Could not launch $source');
  }
}
