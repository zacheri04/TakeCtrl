//
//  ClickInterceptor.swift
//  ControlClickDisablerUI
//
//  Created by Zack on 11/24/25.
//

import CoreGraphics
import Combine

enum ClickInterceptorError: Error {
    case failedToCreateEventTap
}

private func globalEventCallback(proxy: CGEventTapProxy,
                                 type: CGEventType,
                                 event: CGEvent,
                                 refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    
    // Check for left mouse down or up
    if type == .leftMouseDown || type == .leftMouseUp {
        let flags = event.flags
        
        // Check if Control key was pressed during the click
        if flags.contains(.maskControl) {            
            // Remove Control modifier
            let newFlags = flags.subtracting(.maskControl)
            event.flags = newFlags
            
            return Unmanaged.passRetained(event)
        }
    }
    
    return Unmanaged.passRetained(event)
}

class ClickInterceptor: ObservableObject {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    // Tracks if the service is currently running
    @Published var isRunning = false
    
    func start() throws {
        guard !isRunning else { return }
        
        let eventMask = (1 << CGEventType.leftMouseDown.rawValue) |
                        (1 << CGEventType.leftMouseUp.rawValue)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: globalEventCallback, // Pass the global function here
            userInfo: nil
        ) else {
            throw ClickInterceptorError.failedToCreateEventTap
        }
        
        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        
        // Add to the current run loop
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        isRunning = true
    }
    
    func stop() {
        guard isRunning, let tap = eventTap, let source = runLoopSource else { return }
        
        // Disable the tap
        CGEvent.tapEnable(tap: tap, enable: false)
        
        // Remove from run loop to stop processing
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        
        // Cleanup
        self.eventTap = nil
        self.runLoopSource = nil
        self.isRunning = false
    }
}

