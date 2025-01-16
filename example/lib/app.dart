import "package:desktop_updater/desktop_updater.dart";
import "package:desktop_updater/updater_controller.dart";
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
  late DesktopUpdaterController _desktopUpdaterController;

  @override
  void initState() {
    super.initState();
    initPlatformState();

    _desktopUpdaterController = DesktopUpdaterController(
      appArchiveUrl: Uri.parse(
        "https://www.yoursite.com/app-archive.json",
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
                  "Running on: 1.0.0+1",
                ),
                Text("Running on: $_platformVersion\n"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
