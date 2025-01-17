# What is Desktop Updater?
This Flutter plugin supports desktop platforms including macOS, Windows, and Linux. It enables in-app application updates without requiring users to re-download the entire application. The plugin applies updates by restarting the application, ensuring a seamless user experience. Additionally, it provides two essential commands for preparing updates efficiently.

# How does it work?
This plugin is a platform-specific solution that executes native code tailored to each supported platform. Additionally, it includes a built-in update interface that can be seamlessly integrated into your application.

## Getting Started
Add dependency to your `pubspec.yaml`:
```
dependencies:
  ...
  desktop_updater: ^1.0.0
```

Install as CLI, 
Run in your terminal:
```
dart pub global activate desktop_updater
```

# Usage

Add the following codes to your home page or any page you want to see the update card.

```dart
import 'package:desktop_updater/desktop_updater.dart';

late DesktopUpdaterController _desktopUpdaterController;

@override
void initState() {
    super.initState();
    _desktopUpdaterController = DesktopUpdaterController(
        appArchiveUrl: Uri.parse(
        "https://www.yoursite.com/app-archive.json",
        ),
    );
}
```

Then wrap your home page with `DesktopUpdater` widget, under the Scaffold widget.

```dart
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your App Home Page"),
      ),
      body: DesktopUpdateWidget(
        controller: _desktopUpdaterController,
        child: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                    const Text(
                        'Hello World!',
                    ),
                ],
            ),
        ),
      ),
    );
}
```

# Creating app-archive.json
```
{
    "appName": "Desktop Updater",
    "descriptipn": "This is my app descriptipn",
    "items": [
        {
            "version": "0.1.8",
            "shortVersion": 9,
            "changes": [
                {
                    "type": "chore",
                    "message": "Fix bug #1"
                },
                {
                    "type": "feat",
                    "message": "Add new feature #1"
                },
                {
                    "message": "Add new feature #2"
                }
            ],
            "date": "2025-01-10",
            "mandatory": true,
            "url": "https://www.yourwebsite.com/archive/desktop_updater/0.1.8%2B9-windows",
            "platform": "windows"
        },
        {
            "version": "0.1.7",
            "shortVersion": 8,
            "changes": [
                {
                    "type": "chore",
                    "message": "Fix bug #1"
                },
                {
                    "type": "feat",
                    "message": "Add new feature #1"
                },
                {
                    "message": "Add new feature #2"
                }
            ],
            "date": "2025-01-10",
            "mandatory": true,
            "url": ""https://www.yourwebsite.com/archive/desktop_updater/0.1.6%2B7-macos",
            "platform": "macos"
        }
    ]
}
```

# How to use it?
The steps are as follows:

- Prepare an app-archive file.
- Add a JSON file specifying the new version.
- Build the application using the CLI and generate the output.
- Upload the output directory, ensuring all its contents are accessible.

# Commands
You need to update version on `pubspec.yaml` file and run the following commands to build the application:

`dart run desktop_updater:release macos`

then it will create a folder named dist, then run the following command:

`dart run desktop_updater:archive macos`

You'll see `1.0.0+1-macos` folder in dist/1 folder. You can upload this folder to your server directly as a folder, you'll have to access the folder directly. You can use s3 or your own server to host the files, you can also use github pages to host the files, but this should be public access.

# App Archive JSON Structure
You should add your versions to the `items` array. Each version should have the following fields:
- `version`: Required, The version number of the app.
- `shortVersion`: Required, The short version number of the app. This is used to compare the versions.
- `changes`: Required, The changes made in this version. This is an array of objects with the following fields:
    - `type`: Optional, the type of the change. This can be one of the following values: feat, fix, chore, docs, style, refactor, perf, test, build, ci, or other.
    - `message`: Required, The message describing the change.
- `date`: Required, The date when this version was released.
- `mandatory`: Required, A boolean value indicating whether this version is mandatory. If this is true, the user will not be able to skip this version.
- `url`: Required, The URL where the app can be downloaded. This should be a direct link of the folder containing the app files.
- `platform`: Required, The platform for which this version is available. This can be one of the following values: windows, macos, or linux.

# Customization

You can change text and button text by passing `DesktopUpdateLocalization` to controller.

```dart
@override
void initState() {
    super.initState();
    _desktopUpdaterController = DesktopUpdaterController(
        appArchiveUrl: Uri.parse(
        "https://www.yoursite.com/app-archive.json",
        ),
        localization: const DesktopUpdateLocalization(
            updateAvailableText: "Update available",
            newVersionAvailableText: "{} {} is available",
            newVersionLongText:
                "New version is ready to download, click the button below to start downloading. This will download {} MB of data.",
            restartText: "Restart to update",
            warningTitleText: "Are you sure?",
            restartWarningText:
                "A restart is required to complete the update installation.\nAny unsaved changes will be lost. Would you like to restart now?",
            warningCancelText: "Not now",
            warningConfirmText: "Restart",
        ),
    );
}
```
