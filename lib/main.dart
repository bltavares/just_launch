import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:package_manager/package_manager.dart';
import 'package:package_manager/package_manager_platform_interface.dart';
import 'package:provider/provider.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var fallbackTheme = ColorScheme.fromSeed(
      seedColor: Colors.grey,
      brightness: Brightness.dark,
      surface: Colors.black,
    ).copyWith(primary: Colors.white);

    return DynamicColorBuilder(
      builder: (_, darkTheme) => MaterialApp(
        theme: ThemeData(
          colorScheme: darkTheme ?? fallbackTheme,
          useMaterial3: true,
        ),
        home: const PopScope(
          canPop: false,
          child: Scaffold(
            body: MyLauncher(),
          ),
        ),
      ),
    );
  }
}

class AppListModel extends ChangeNotifier {
  AppListModel(this.plugin);

  final PackageManager plugin;

  var _search = "";
  var _installedApps = <InstalledApp>[];
  var _hasError = false;

  List<InstalledApp> get _filteredApps {
    if (_search == "") {
      return _installedApps;
    }

    return _installedApps
        .where((app) => app.label.toLowerCase().contains(_search.toLowerCase()))
        .toList();
  }

  set installedApps(List<InstalledApp> apps) {
    _installedApps = apps;
    notifyListeners();
  }

  set search(String search) {
    _search = search;
    notifyListeners();
  }

  set hasError(bool status) {
    _hasError = status;
    notifyListeners();
  }

  List<InstalledApp> get apps {
    return _filteredApps
        .where((app) => app.label != "just_launch")
        .sortedBy((app) => app.label.toLowerCase());
  }

  bool get hasError => _hasError;

  List<InstalledApp> get installedApps => _installedApps;

  Future<void> updateApps() async {
    try {
      hasError = false;
      installedApps =
          await plugin.getAllApps().timeout(const Duration(seconds: 5));
    } catch (e) {
      hasError = true;
    }
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
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
        value: appListModel,
        child: const AppList(),
      );
}

class AppList extends StatefulWidget {
  const AppList({
    super.key,
  });

  @override
  State<AppList> createState() => _AppListState();
}

class _AppListState extends State<AppList> {
  final TextEditingController text = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppListModel>(builder: (context, model, _) {
      Widget child;

      if (model.hasError) {
        child = Center(
          key: const Key("error"),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Just Launch",
                style: TextStyle(fontSize: 36),
              ),
              OutlinedButton(
                onPressed: model.updateApps,
                child: const Text("Retry"),
              )
            ],
          ),
        );
      } else if (model.installedApps.isEmpty) {
        child = const Center(
          key: Key("loading"),
          child: Text(
            "Just Launch",
            style: TextStyle(fontSize: 36),
          ),
        );
      } else {
        child = Padding(
            key: const Key("loaded"),
            padding: const EdgeInsets.only(top: 20.0),
            child: Center(
              child: Column(
                children: <Widget>[
                  SearchTextField(
                    text: text,
                    appList: model.apps,
                    search: (e) {
                      model.search = e;
                    },
                    plugin: model.plugin,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: model.updateApps,
                      child: ListView.builder(
                        itemCount: model.apps.length,
                        itemBuilder: (context, index) => AppListButton(
                          search: (String e) {
                            model.search = e;
                          },
                          app: model.apps[index],
                          text: text,
                          plugin: model.plugin,
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
    super.key,
    required this.text,
    required this.app,
    required this.search,
    required this.plugin,
  });

  final TextEditingController text;
  final InstalledApp app;
  final Function(String) search;
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
        search("");
        text.clear();
        await plugin.launchApp(app.package);
      },
      onLongPress: () async {
        search("");
        text.clear();
        await plugin.launchSettings(app.package);
      },
    );
  }
}

class SearchTextField extends StatelessWidget {
  const SearchTextField({
    super.key,
    required this.text,
    required this.search,
    required this.appList,
    required this.plugin,
  });

  final TextEditingController text;
  final List<InstalledApp> appList;
  final Function(String) search;
  final PackageManager plugin;

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: true,
      autocorrect: false,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 26),
      controller: text,
      onChanged: search,
      onSubmitted: (valueChanged) {
        if (appList.isNotEmpty) {
          plugin.launchApp(appList[0].package);
        }
        search("");
        text.clear();
      },
    );
  }
}
