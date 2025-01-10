import Cocoa
import FlutterMacOS

public class DesktopUpdaterPlugin: NSObject, FlutterPlugin {
    func restartApp() {
        let executablePath = Bundle.main.executablePath!
        print("executablePath path: \(executablePath)")
        
        NSApplication.shared.terminate(nil)
        
        let updateFolder = Bundle.main.bundlePath + "/Contents/update"
        do {
            let updateFiles = try FileManager.default.contentsOfDirectory(atPath: updateFolder)
            for file in updateFiles {
                let source = updateFolder + "/" + file
                let destination = Bundle.main.bundlePath + "/Contents/" + file
                print("Copying \(source) to \(destination)")
                do {
                    try FileManager.default.copyItem(atPath: source, toPath: destination)
                } 
                catch {
                    // print("Error copying update files: \(error)")
                    print("Copying \(source) to \(destination) with replace")
                    // if error is File exists, replace
                    if let e = error as NSError?, e.domain == NSCocoaErrorDomain && e.code == NSFileWriteFileExistsError {
                        do {
                            try FileManager.default.removeItem(atPath: destination)
                            try FileManager.default.copyItem(atPath: source, toPath: destination)
                        } catch {
                            print("Error replace update files: \(error)")
                        }
                    }
                }
            }
        } catch {
            print("Error reading update folder: \(error)")
            return
        }
        
        do {
            // Set execute permissions
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executablePath)
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = []
            try process.run()
        } catch {
            print("Error during restart: \(error)")
        }

        // Remove update folder
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
        case "getExecutablePath":
            result(Bundle.main.executablePath)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
