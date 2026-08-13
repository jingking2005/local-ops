import AppKit

final class LauncherAppDelegate: NSObject, NSApplicationDelegate {
    private var ownedProcesses: [Process] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        ProcessInfo.processInfo.disableAutomaticTermination("总控台服务运行中")
        ProcessInfo.processInfo.disableSuddenTermination()
        runEntrypoint()
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        runEntrypoint()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        for process in ownedProcesses where process.isRunning {
            process.terminate()
        }
    }

    private func runEntrypoint() {
        let projectDirectory = Bundle.main.bundleURL.deletingLastPathComponent()
        let entrypoint = projectDirectory.appendingPathComponent(
            "open-console.command",
            isDirectory: false
        )

        guard FileManager.default.isExecutableFile(atPath: entrypoint.path) else {
            showError("启动文件不完整。请保留“总控台.app”和 open-console.command、server.py、static 文件夹在同一个发行目录中。")
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [entrypoint.path]
        process.currentDirectoryURL = projectDirectory
        process.standardInput = FileHandle.nullDevice

        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        process.environment = environment

        guard let (logHandle, logPath) = prepareLogHandle(environment: environment) else {
            return
        }
        process.standardOutput = logHandle
        process.standardError = logHandle
        process.terminationHandler = { [weak self] finishedProcess in
            try? logHandle.close()
            DispatchQueue.main.async {
                self?.ownedProcesses.removeAll { $0 === finishedProcess }
                if finishedProcess.terminationStatus != 0 {
                    self?.showError(
                        "启动脚本退出（状态码 \(finishedProcess.terminationStatus)）。请查看 \(logPath)。"
                    )
                }
            }
        }

        do {
            try process.run()
            ownedProcesses.append(process)
        } catch {
            try? logHandle.close()
            showError("无法启动总控台：\(error.localizedDescription)")
        }
    }

    private func prepareLogHandle(
        environment: [String: String]
    ) -> (FileHandle, String)? {
        let defaultDirectory = "~/Library/Logs/总控台"
        let configuredDirectory = environment["CONSOLE_LOG_DIR"] ?? defaultDirectory
        let directoryPath = NSString(string: configuredDirectory).expandingTildeInPath
        let directoryURL = URL(fileURLWithPath: directoryPath, isDirectory: true)
        let logURL = directoryURL.appendingPathComponent("console.log")

        do {
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o700],
                ofItemAtPath: directoryURL.path
            )
            if !FileManager.default.fileExists(atPath: logURL.path) {
                guard FileManager.default.createFile(
                    atPath: logURL.path,
                    contents: nil,
                    attributes: [.posixPermissions: 0o600]
                ) else {
                    throw CocoaError(.fileWriteUnknown)
                }
            }
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: logURL.path
            )
            let handle = try FileHandle(forWritingTo: logURL)
            try handle.seekToEnd()
            return (handle, logURL.path)
        } catch {
            showError("无法写入启动日志：\(error.localizedDescription)")
            return nil
        }
    }

    private func showError(_ message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "总控台"
        alert.informativeText = message
        alert.addButton(withTitle: "好")
        alert.runModal()
    }
}

let application = NSApplication.shared
let appDelegate = LauncherAppDelegate()
application.delegate = appDelegate
application.setActivationPolicy(.regular)

let mainMenu = NSMenu()
let applicationMenuItem = NSMenuItem()
let applicationMenu = NSMenu()
applicationMenu.addItem(
    withTitle: "退出总控台",
    action: #selector(NSApplication.terminate(_:)),
    keyEquivalent: "q"
)
applicationMenuItem.submenu = applicationMenu
mainMenu.addItem(applicationMenuItem)
application.mainMenu = mainMenu
application.run()
