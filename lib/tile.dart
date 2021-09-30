import 'package:flutter/material.dart';

class AppTile extends StatefulWidget {
  final app;
  AppTile({this.app});

  @override
  _AppTileState createState() => _AppTileState();
}

class _AppTileState extends State<AppTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          children: [
            Text("${widget.app['package'].split(".")[2]}"),
            Text("${widget.app['version']}")
          ],
        ),
        GestureDetector(
          child: Container(
            color: Colors.blue,
            child: Text("Update"),
          ),
        )
      ],
    ));
  }
}
