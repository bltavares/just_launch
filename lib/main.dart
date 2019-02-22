import 'package:flutter/material.dart';
import 'package:launcher_assist/launcher_assist.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:superpower/superpower.dart';
import 'package:rxdart/rxdart.dart';

var globalTheme = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: Colors.black,
);

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: globalTheme,
      home: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          body: MyLauncher(),
        ),
      ),
    );
  }
}

class MyLauncher extends StatefulWidget {
  @override
  MyAppState createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyLauncher> {
  var installedApps = [];

  Future<List<dynamic>> fetchCachedApps() {
    return SharedPreferences.getInstance().then((cache) {
      var storedApps = cache.getString("apps");
      if (storedApps == null) {
        return [];
      }
      try {
        return jsonDecode(storedApps);
      } catch (error) {
        return [];
      }
    });
  }

  List<dynamic> setApps(List<dynamic> apps) {
    setState(() {
      this.installedApps = apps;
    });
    return apps;
  }

  Future cacheApps(apps) {
    return SharedPreferences.getInstance().then((cache) {
      cache.setString("apps", jsonEncode(apps));
    });
  }

  Future<List<dynamic>> findApps() async {
    List<dynamic> apps = await LauncherAssist.getAllApps();
    return apps;
  }

  @override
  void initState() {
    super.initState();
    fetchCachedApps().then(this.setApps);
    findApps().then(this.setApps).then(this.cacheApps);
  }

  @override
  Widget build(BuildContext context) {
    if (this.installedApps.length > 0) {
      return AppList(this.installedApps);
    }

    return Center(
      child: Text(
        "Just Launch",
        style: TextStyle(fontSize: 36),
      ),
    );
  }
}

class AppList extends StatefulWidget {
  final List<dynamic> installedApps;

  const AppList(
    this.installedApps, {
    Key key,
  }) : super(key: key);

  @override
  AppListState createState() {
    return AppListState();
  }
}

class AppListState extends State<AppList> {
  final search = BehaviorSubject<String>();

  Stream<List<dynamic>> get _apps {
    return search.stream.debounce(Duration(milliseconds: 300)).map((search) {
      if (search == null || search == "") {
        return widget.installedApps;
      }

      return $(widget.installedApps.where(
        (app) => app["label"]
            .toString()
            .toLowerCase()
            .contains(search.toLowerCase()),
      ));
    });
  }

  Stream<List> get _sortedApps {
    return this._apps.map(
          (apps) => $(apps)
              .where((app) => app["label"] != "just_launch")
              .sortedBy((app) => app["label"]),
        );
  }

  final text = TextEditingController();

  void dispose() {
    search.close();
    super.dispose();
  }

  Widget appButton(BuildContext context, dynamic app) {
    return FlatButton(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          app["label"],
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26),
        ),
      ),
      onPressed: () {
        search.add(null);
        text.clear();
        LauncherAssist.launchApp(app["package"]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Center(
        child: Column(
          children: <Widget>[
            TextField(
              autofocus: true,
              autocorrect: false,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26),
              controller: text,
              onChanged: search.add,
            ),
            StreamBuilder(
              initialData: widget.installedApps,
              stream: this._sortedApps,
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) =>
                  Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data.length,
                      itemBuilder: (context, index) => this.appButton(
                            context,
                            snapshot.data[index],
                          ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
