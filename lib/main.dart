import 'package:flutter/material.dart';
import 'package:launcher_assist/launcher_assist.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(home: new Scaffold(body: MyLauncher()));
  }
}

class MyLauncher extends StatefulWidget {
  @override
  MyAppState createState() {
    return new MyAppState();
  }
}

class MyAppState extends State<MyLauncher> {
  var installedApps = [];

  @override
  void initState() {
    super.initState();
    LauncherAssist.getAllApps().then((apps) {
      setState(() {
        this.installedApps = apps;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: installedApps.length,
      itemBuilder: this.appButton,
    );
  }

  Widget appButton(BuildContext context, index) {
    var app = this.installedApps[index];
    return FlatButton(
      child: Text(app["label"]),
      onPressed: () {
        LauncherAssist.launchApp(app["package"]);
      },
    );
  }
}
