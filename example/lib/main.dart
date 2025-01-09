import "dart:async";

import "package:desktop_updater/desktop_updater.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = "Unknown";
  final _desktopUpdaterPlugin = DesktopUpdater();
  String length = "";
  String changedFiles = "";
  String hashes = "";

  @override
  void initState() {
    super.initState();
    initPlatformState();
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
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Plugin example app"),
        ),
        body: Center(
          child: Column(
            children: [
              const Text(
                "Running on: 0.1.2+3",
              ),
              Text("Running on: $_platformVersion\n"),
              ElevatedButton(
                onPressed: _desktopUpdaterPlugin.restartApp,
                child: const Text("Restart App"),
              ),
              ElevatedButton(
                onPressed: () {
                  _desktopUpdaterPlugin.sayHello().then(print);
                },
                child: const Text("Say Hello"),
              ),
              ElevatedButton(
                onPressed: () {
                  final startTime = DateTime.now();
                  _desktopUpdaterPlugin.generateFileHashes().then(
                    (value) {
                      print(
                        "File hashes generated in ${DateTime.now().difference(startTime).inMilliseconds} ms",
                      );
                      print(value);
                      setState(() {
                        hashes = value ?? "";
                      });
                    },
                  );
                },
                child: const Text("Get Executable Path"),
              ),
              SelectableText("Hashes path:\n$hashes\n"),
              ElevatedButton(
                onPressed: () {
                  final startTime = DateTime.now();
                  setState(() {
                    changedFiles = "";
                    length = "";
                  });

                  _desktopUpdaterPlugin
                      .verifyFileHash(
                    "/var/folders/6w/86tr67px42vbszwd8tdlr3vr0000gn/T/desktop_updatervIckPX/hashes.json",
                    "/var/folders/6w/86tr67px42vbszwd8tdlr3vr0000gn/T/desktop_updaterAlf5te/hashes.json",
                  )
                      .then(
                    (value) {
                      print(
                        "File hashes verified in ${DateTime.now().difference(startTime).inMilliseconds} ms",
                      );

                      for (final file in value) {
                        if (file != null) {
                          print("${file.filePath} - ${file.length}b");

                          setState(() {
                            changedFiles +=
                                "${file.filePath} - ${file.length}b\n";
                          });
                        }
                      }

                      // Calculate total length of all files
                      print(
                        value.fold<int>(
                          0,
                          (previousValue, element) =>
                              previousValue + element!.length,
                        ),
                      );

                      setState(() {
                        length = value
                            .fold<int>(
                              0,
                              (previousValue, element) =>
                                  previousValue + element!.length,
                            )
                            .toString();
                      });
                    },
                  );
                },
                child: const Text("Verify File Hash"),
              ),
              Text("Total length of changed files: $length\n"),
              Text("Changed files:\n$changedFiles"),
              FilledButton(
                onPressed: () {
                  _desktopUpdaterPlugin.updateApp(
                    remoteUpdateFolder:
                        "https://s3.eu-central-1.amazonaws.com/www.monolib.net/archive/desktop_updater/0.1.2%2B3-macos",
                  );
                },
                child: const Text("Update App"),
              ),
            ],
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
      ..add(StringProperty("hashes", hashes));
  }
}
