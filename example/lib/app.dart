import "package:desktop_updater/desktop_updater.dart";
import "package:desktop_updater/updater_controller.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _platformVersion = "Unknown";
  final _desktopUpdaterPlugin = DesktopUpdater();
  String length = "";
  String changedFiles = "";
  String hashes = "";
  ItemModel? appArchiveItem;
  UpdateProgress? updateProgress;

  late DesktopUpdaterController _desktopUpdaterController;

  @override
  void initState() {
    super.initState();
    initPlatformState();

    _desktopUpdaterController = DesktopUpdaterController(
      appArchiveUrl: Uri.parse(
        "https://s3.eu-central-1.amazonaws.com/www.monolib.net/archive/desktop_updater/app-archive.json",
      ),
    );
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _desktopUpdaterPlugin.getPlatformVersion() ??
          "Unknown platform version";
    } on PlatformException {
      platformVersion = "Failed to get platform version.";
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Plugin example app"),
      ),
      body: DesktopUpdateWidget(
        controller: _desktopUpdaterController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Column(
              children: [
                const Text(
                  "Running on: 0.1.5+6",
                ),
                Text("Running on: $_platformVersion\n"),
                ElevatedButton(
                  onPressed: _desktopUpdaterPlugin.restartApp,
                  child: const Text("Restart App"),
                ),
                OutlinedButton(
                  onPressed: () {
                    _desktopUpdaterPlugin
                        .versionCheck(
                      appArchiveUrl:
                          "https://s3.eu-central-1.amazonaws.com/www.monolib.net/archive/desktop_updater/app-archive.json",
                    )
                        .then(
                      (value) {
                        print("App archive downloaded");
                        print(value?.url);

                        setState(() {
                          appArchiveItem = value;
                        });
                      },
                    );
                  },
                  child: const Text("Check version"),
                ),
                SelectableText("App archive item:\n${appArchiveItem?.url}\n"),
                FilledButton(
                  onPressed: () {
                    _desktopUpdaterPlugin.updateApp(
                      remoteUpdateFolder: appArchiveItem?.url ?? "",
                      changedFiles: [],
                    ).then(
                      (value) {
                        value.listen(
                          (event) {
                            setState(() {
                              updateProgress = event;
                            });
                          },
                          onDone: () {
                            print("Update done");
                          },
                        );
                      },
                    );
                  },
                  child: const Text("Update App"),
                ),
                SelectableText(
                  "Update progress:\n${updateProgress?.currentFile ?? ""}\n${updateProgress?.receivedBytes ?? 0}/${updateProgress?.totalBytes ?? 0}\n${updateProgress?.completedFiles ?? 0}/${updateProgress?.totalFiles ?? 0}",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty("length", length))
      ..add(StringProperty("changedFiles", changedFiles))
      ..add(StringProperty("hashes", hashes))
      ..add(DiagnosticsProperty<ItemModel?>("appArchiveItem", appArchiveItem))
      ..add(
        DiagnosticsProperty<UpdateProgress?>("updateProgress", updateProgress),
      );
  }
}
