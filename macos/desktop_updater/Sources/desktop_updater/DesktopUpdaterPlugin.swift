import Cocoa
import FlutterMacOS

public class DesktopUpdaterPlugin: NSObject, FlutterPlugin {
    func restartApp() {
        let currentPath = Bundle.main.executablePath!
        let newPath = currentPath + ".replace"
        let backupPath = currentPath + ".backup"
        
        print("Current path: \(currentPath)")
        
        NSApplication.shared.terminate(nil)

        do {
          print("Moving \(currentPath) to \(backupPath)")
          print("Copying \(newPath) to \(currentPath)")
            // remove .backup if it exists
            if FileManager.default.fileExists(atPath: backupPath) {
                try FileManager.default.removeItem(atPath: backupPath)
            }
            try FileManager.default.moveItem(atPath: currentPath, toPath: backupPath)
            try FileManager.default.copyItem(atPath: newPath, toPath: currentPath)
            
            // Set execute permissions
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: currentPath)
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: currentPath)
            process.arguments = []
            try process.run()
        } catch {
            print("Error during restart: \(error)")
        }
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "desktop_updater", binaryMessenger: registrar.messenger)
        let instance = DesktopUpdaterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
        case "restartApp":
            restartApp()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
