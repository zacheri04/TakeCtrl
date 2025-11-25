//
//  ControlClickDisablerUIApp.swift
//  ControlClickDisablerUI
//
//  Created by Zack on 11/24/25.
//

import SwiftUI

@main
struct TakeCtrlApp: App {
    @State private var toggle: Bool = false
    @StateObject private var interceptor: ClickInterceptor
    
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
        
        // Initialize the Property Wrappers
        // IMPORTANT: Use the underscore (_) to set the initial values.
        _interceptor = StateObject(wrappedValue: newInterceptor)
        _toggle = State(initialValue: startSuccess)
    }
    
    var body: some Scene {
        MenuBarExtra {
            Toggle("Disable Control Click", isOn: $toggle)
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            let image: NSImage = {
                    let ratio = $0.size.height / $0.size.width
                    $0.size.height = 18
                    $0.size.width = 18 / ratio
                    return $0
                }(NSImage(named: "BarIcon")!)

                Image(nsImage: image)
        }
        .onChange(of: toggle) {
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
    }
}

