import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:superpower/superpower.dart' show $;
import 'package:launcher_assist/launcher_assist.dart' show LauncherAssist;
import 'package:rxdart/rxdart.dart' show BehaviorSubject, Observable;

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

class AppListModel {
  final _search = BehaviorSubject<String>.seeded("");
  final _installedApps = BehaviorSubject<List<dynamic>>.seeded([]);

  Sink<String> get search => _search.sink;

  void dispose() {
    _search.close();
    _installedApps.close();
  }

  Stream<List<dynamic>> get _filteredApps {
    return Observable.combineLatest2(
      _installedApps,
      _search.debounce(Duration(milliseconds: 300)),
      (List<dynamic> installedApps, String search) {
        if (search == null || search == "") {
          return installedApps;
        }

        return $(installedApps.where(
          (app) => app["label"]
              .toString()
              .toLowerCase()
              .contains(search.toLowerCase()),
        ));
      },
    );
  }

  Future<List<dynamic>> _fetchCachedApps() {
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

  List<dynamic> _setApps(List<dynamic> apps) {
    _installedApps.add(apps);
    return apps;
  }

  Future _cacheApps(apps) {
    return SharedPreferences.getInstance().then((cache) {
      cache.setString("apps", jsonEncode(apps));
    });
  }

  Future<List<dynamic>> _findApps() async {
    List<dynamic> apps = await LauncherAssist.getAllApps();
    return apps;
  }

  Stream<List> get apps {
    return _filteredApps.map(
      (apps) => $(apps)
          .where((app) => app["label"] != "just_launch")
          .sortedBy((app) => app["label"]),
    );
  }

  void initState() {
    _fetchCachedApps().then(this._setApps);
    _findApps().then(this._setApps).then(this._cacheApps);
  }
}

class MyLauncher extends StatefulWidget {
  @override
  MyLauncherState createState() {
    return MyLauncherState();
  }
}

class MyLauncherState extends State<MyLauncher> {
  final appListModel = AppListModel();

  @override
  void initState() {
    super.initState();
    appListModel.initState();
  }

  @override
  void dispose() {
    appListModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppList(appListModel);
}

class AppList extends StatelessWidget {
  final AppListModel installedApps;
  final TextEditingController text = TextEditingController();

  AppList(
    this.installedApps, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: installedApps.apps,
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: Text("Just Launch", style: TextStyle(fontSize: 36)),
            );
          }

          return Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Center(
                child: Column(
                  children: <Widget>[
                    SearchTextField(
                      text: text,
                      appList: snapshot.data,
                      search: installedApps.search,
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: snapshot.data.length,
                        itemBuilder: (context, index) => AppListButton(
                              search: installedApps.search,
                              appList: snapshot.data,
                              index: index,
                              text: text,
                            ),
                      ),
                    ),
                  ],
                ),
              ));
        });
  }
}

class AppListButton extends StatelessWidget {
  const AppListButton({
    Key key,
    @required this.text,
    @required this.index,
    @required this.appList,
    @required this.search,
  }) : super(key: key);

  final TextEditingController text;
  final List<dynamic> appList;
  final int index;
  final Sink<String> search;

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          appList[index]["label"],
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26),
        ),
      ),
      onPressed: () {
        search.add(null);
        text.clear();
        LauncherAssist.launchApp(appList[index]["package"]);
      },
    );
  }
}

class SearchTextField extends StatelessWidget {
  const SearchTextField({
    Key key,
    @required this.text,
    @required this.search,
    @required this.appList,
  }) : super(key: key);

  final TextEditingController text;
  final List<dynamic> appList;
  final Sink<String> search;

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: true,
      autocorrect: false,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 26),
      controller: text,
      onChanged: search.add,
      onSubmitted: (valueChanged) {
        if (appList.length > 0) {
          LauncherAssist.launchApp(appList[0]["package"]);
        }
        search.add(null);
        text.clear();
      },
    );
  }
}
