import 'package:collection/collection.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:package_manager/package_manager.dart';
import 'package:package_manager/package_manager_platform_interface.dart';
import 'package:rxdart/rxdart.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var fallbackTheme = ColorScheme.fromSeed(
      seedColor: Colors.grey,
      brightness: Brightness.dark,
      background: Colors.black,
    ).copyWith(primary: Colors.white);

    return DynamicColorBuilder(
      builder: (_, darkTheme) => MaterialApp(
        theme: ThemeData(
          colorScheme: darkTheme ?? fallbackTheme,
          useMaterial3: true,
        ),
        home: WillPopScope(
          onWillPop: () async => false,
          child: const Scaffold(
            body: MyLauncher(),
          ),
        ),
      ),
    );
  }
}

class AppListModel {
  final PackageManager plugin;

  final _search = BehaviorSubject<String>.seeded("");
  final _installedApps = BehaviorSubject<List<InstalledApp>>.seeded([]);

  AppListModel(this.plugin);

  Sink<String> get search => _search.sink;

  Future<List<InstalledApp>> _findApps() async => await plugin.getAllApps();

  void dispose() {
    _search.close();
    _installedApps.close();
  }

  Stream<List<InstalledApp>> get _filteredApps {
    return Rx.combineLatest2(
      _installedApps,
      _search.debounceTime(const Duration(milliseconds: 300)),
      (List<InstalledApp> installedApps, String search) {
        if (search == "") {
          return installedApps;
        }

        return installedApps
            .where(
              (app) => app.label.toLowerCase().contains(search.toLowerCase()),
            )
            .toList();
      },
    );
  }

  List<dynamic> _setApps(List<InstalledApp> apps) {
    _installedApps.add(apps);
    return apps;
  }

  Stream<List<InstalledApp>> get apps {
    return _filteredApps.map(
      (apps) => apps
          .where((app) => app.label != "just_launch")
          .sortedBy((app) => app.label.toLowerCase()),
    );
  }

  Future<void> updateApps() async {
    return _findApps().then(_setApps);
  }

  Future<void> launchPackage(InstalledApp app) {
    return plugin.launchApp(app.package);
  }
}

class MyLauncher extends StatefulWidget {
  const MyLauncher({super.key});

  @override
  MyLauncherState createState() {
    return MyLauncherState();
  }
}

class MyLauncherState extends State<MyLauncher> {
  final plugin = PackageManager();
  late final AppListModel appListModel;

  @override
  void initState() {
    super.initState();
    appListModel = AppListModel(plugin);
    appListModel.updateApps();
  }

  @override
  void dispose() {
    appListModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppList(
        installedApps: appListModel,
        plugin: plugin,
      );
}

class AppList extends StatelessWidget {
  final AppListModel installedApps;
  final PackageManager plugin;
  final TextEditingController text = TextEditingController();

  AppList({
    required this.installedApps,
    required this.plugin,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: installedApps.apps,
        builder: (context, AsyncSnapshot<List<InstalledApp>> snapshot) {
          Widget child;

          final data = snapshot.data;
          if (data == null || data.isEmpty) {
            child = const Center(
              child: Text(
                  key: Key("loading"),
                  "Just Launch",
                  style: TextStyle(fontSize: 36)),
            );
          } else {
            child = Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Center(
                  child: Column(
                    children: <Widget>[
                      SearchTextField(
                        text: text,
                        appList: data,
                        search: installedApps.search,
                        plugin: plugin,
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: installedApps.updateApps,
                          child: ListView.builder(
                            itemCount: data.length,
                            itemBuilder: (context, index) => AppListButton(
                              search: installedApps.search,
                              app: data[index],
                              text: text,
                              plugin: plugin,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ));
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: child,
          );
        });
  }
}

class AppListButton extends StatelessWidget {
  const AppListButton({
    Key? key,
    required this.text,
    required this.app,
    required this.search,
    required this.plugin,
  }) : super(key: key);

  final TextEditingController text;
  final InstalledApp app;
  final Sink<String> search;
  final PackageManager plugin;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          app.label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26),
        ),
      ),
      onPressed: () async {
        search.add("");
        text.clear();
        await plugin.launchApp(app.package);
      },
      onLongPress: () async {
        search.add("");
        text.clear();
        await plugin.launchSettings(app.package);
      },
    );
  }
}

class SearchTextField extends StatelessWidget {
  const SearchTextField({
    Key? key,
    required this.text,
    required this.search,
    required this.appList,
    required this.plugin,
  }) : super(key: key);

  final TextEditingController text;
  final List<InstalledApp> appList;
  final Sink<String> search;
  final PackageManager plugin;

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: true,
      autocorrect: false,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 26),
      controller: text,
      onChanged: search.add,
      onSubmitted: (valueChanged) {
        if (appList.isNotEmpty) {
          plugin.launchApp(appList[0].package);
        }
        search.add("");
        text.clear();
      },
    );
  }
}
