//
//  TakeCtrlApp.swift
//  TakeCtrl
//
//  Created by Zack on 11/24/25.
//

import Combine
import ServiceManagement
import SwiftUI

enum TakeCtrlError: Error {
    case failedLaunchAtLoginToggle
}

@main
struct TakeCtrlApp: App {
    @State private var toggle: Bool = false
    @State private var openAtLoginPreference: Bool = LaunchAtLogin.isEnabled
    @StateObject private var interceptor: ClickInterceptor

    @State private var permissionTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    init() {
        let newInterceptor = ClickInterceptor()
        var startSuccess = false

        do {
            try newInterceptor.start()
            startSuccess = true
            print("ClickInterceptor started successfully on launch.")
        } catch {
            print("Failed to start ClickInterceptor on launch: \(error)")
        }

        _interceptor = StateObject(wrappedValue: newInterceptor)
        _toggle = State(initialValue: startSuccess)
    }

    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading, spacing: 8) {
                if !interceptor.getPermission() {
                    Button(action: openAccessibilitySettings) {
                        Label(
                            "Open System Settings",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        Spacer()
                    }
                    .buttonStyle(.accessoryBar)
                } else {
                    // Toggle Interceptor on/off
                    HStack {
                        Text("Enable TakeCtrl")
                        Spacer()
                        Toggle("", isOn: $toggle)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                    .padding([.leading, .trailing], 10)

                    // Open at Login Toggle
                    HStack {
                        Text("Open at Login")
                        Spacer()
                        Toggle("", isOn: $openAtLoginPreference)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                    .padding([.leading, .trailing], 10)
                }
                Divider()

                Button(action: {
                    NSApp.activate(ignoringOtherApps: true)

                    let credits = NSMutableAttributedString(
                        string: "Created by Zack Dupree\n")

                    let linkText = NSAttributedString(
                        string: "View Project on GitHub",
                        attributes: [
                            .link: URL(
                                string:
                                    "https://github.com/zacheri04/takectrl"
                            )!,
                            .foregroundColor: NSColor.linkColor,
                            .underlineStyle: NSUnderlineStyle.single
                                .rawValue,
                        ]
                    )

                    // 3. Combine them
                    credits.append(linkText)

                    // Standard about page panel
                    NSApp.orderFrontStandardAboutPanel(
                        options: [
                            .applicationName: "TakeCtrl",
                            .credits: credits,
                            .applicationVersion: Bundle.main.object(
                                forInfoDictionaryKey:
                                    "CFBundleShortVersionString"
                            ) as? String ?? "Unknown",
                        ]
                    )
                }) {
                    Text("About")
                    Spacer()
                }
                .buttonStyle(.accessoryBar)

                // Quit application
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Text("Quit")
                    Spacer()
                }
                .buttonStyle(.accessoryBar)
            }
            .onReceive(permissionTimer) { _ in
                if interceptor.getPermission() {
                    do {
                        try interceptor.start()
                        toggle = true
                    } catch {
                        print(error)
                    }
                }

                openAtLoginPreference = LaunchAtLogin.isEnabled
            }
            .padding(8)
        } label: {
            // App icon in menu bar
            let image: NSImage = {
                let ratio = $0.size.height / $0.size.width
                $0.size.height = 18
                $0.size.width = 18 / ratio
                return $0
            }(NSImage(named: "BarIcon")!)

            Image(nsImage: image)
        }
        .onChange(of: toggle) {
            // Handle enabling/disabling interceptor while application running
            if toggle {
                do {
                    try interceptor.start()
                } catch {
                    toggle = false
                }
            } else {
                interceptor.stop()
            }
        }
        .onChange(of: openAtLoginPreference) {
            // Handle toggling open at login
            do {
                try LaunchAtLogin.set(enabled: openAtLoginPreference)
            } catch {
                print(error)
            }
        }
        .menuBarExtraStyle(.window)
    }
}

func openAccessibilitySettings() {
    // Open System Settings to Privacy & Security -> Accessibility
    if let url = URL(
        string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    ) {
        NSWorkspace.shared.open(url)
    }
}

final class LaunchAtLogin {
    // Class for managing open at login
    // Check if currently enabled
    static var isEnabled: Bool {
        return SMAppService.mainApp.status == .enabled
    }

    // Toggle the setting
    static func set(enabled: Bool) throws {
        do {
            if enabled {
                if SMAppService.mainApp.status == .enabled { return }
                try SMAppService.mainApp.register()
            } else {
                if SMAppService.mainApp.status == .notFound { return }
                try SMAppService.mainApp.unregister()
            }
        } catch {
            throw TakeCtrlError.failedLaunchAtLoginToggle
        }
    }
}

