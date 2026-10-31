import 'package:flutter/material.dart';

class PageLayout extends StatelessWidget {
  const PageLayout({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(padding: const EdgeInsets.all(24), children: children),
      ),
    ),
  );
}
