import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SafeArea(
          child: TextField(
            cursorWidth: 8,
            autofocus: true,
            decoration: InputDecoration(
              prefix: Text("\$ "),
              border: InputBorder.none
            ),
          ),
        ),
      ),
    );
  }
}
