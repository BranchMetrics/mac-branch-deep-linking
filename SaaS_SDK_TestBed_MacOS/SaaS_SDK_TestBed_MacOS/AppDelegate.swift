//
//  AppDelegate.swift
//  SaaS_SDK_TestBed_MacOS
//
//  Created by ajaykumar on 05/07/22.
//

import Cocoa
import Branch

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var window: NSWindow!
    
    
    func applicationWillFinishLaunching(_ notification: Notification) {
            
        BNCLogSetDisplayLevel(BNCLogLevel.all)
        Branch.loggingIsEnabled = true
    
        // Register for Branch URL notifications
        
        NotificationCenter.default.addObserver(self, selector: #selector(branchWillStartSession), name: .BranchWillStartSession, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(branchDidStartSession), name: .BranchDidStartSession, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(branchOpenedURLNotification), name: .BranchDidOpenURLWithSession, object: nil)
        
        // Create a Branch configuration object with your key:
        let configuration = BranchConfiguration(key: "key_test_om2EWe1WBeBYmpz9Z1mdpopouDmoN72T")
        
        configuration.branchAPIServiceURL = "https://api.branch.io"
        configuration.key = "key_test_om2EWe1WBeBYmpz9Z1mdpopouDmoN72T"
        
        // Start Branch:
        Branch.sharedInstance.start(with: configuration)
        
        
    }
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        Utils.shared.clearAllLogFiles()
        Utils.shared.setLogFile("AppLaunch")
        StartupOptionsData.setActiveSetDebugEnabled(true)
        StartupOptionsData.setPendingSetDebugEnabled(true)
        Utils.shared.setLogFile("AppDelegate")
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 1000),
            styleMask: [.fullScreen],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Main Window")
        
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    func application(_ application: NSApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([NSUserActivityRestoring]) -> Void) -> Bool {
        Branch.sharedInstance.continue(userActivity)
        return true
    }
    @objc private func branchWillStartSession(_ notification: Notification?) {
        guard let notification = notification else { return }
        
        let url = notification.userInfo?[BranchURLKey] ?? "N/A"
        NSLog("branchWillStartSession: \(notification.name) URL: \(url)")
    }
    
    @objc private func branchDidStartSession(_ notification: Notification?) {
        guard let notification = notification else { return }
        
        let url = notification.userInfo?[BranchURLKey] ?? "N/A"
        let session = notification.userInfo?[BranchSessionKey] as? BranchSession
        let data = (session != nil && session?.data != nil) ? session?.data?.description ?? "" : ""
        NSLog("branchDidStartSession: \(notification.name) URL: \(url) Data: \(data)")
    }
    
    @objc private func branchOpenedURLNotification(_ notification: Notification?) {
        guard let notification = notification else { return }
        
        let url = notification.userInfo?[BranchURLKey] ?? "N/A"
        NSLog("branchOpenedURLNotification: \(notification.name) URL: \(url)")
        
        if let session = notification.userInfo?[BranchSessionKey] as? BranchSession,
           let data = session.data{
            let linkContent = session.linkContent
            displayLinkContent(linkContent, appData: data)
        }
    }
    
    private func displayLinkContent(_ linkContent: BranchUniversalObject?, appData: [AnyHashable : Any]) {
        let storyBoard : NSStoryboard = NSStoryboard(name: "Main", bundle:nil)
        let viewController = storyBoard.instantiateController(withIdentifier: "DisplayContentVC") as! DisplayContentVC
        viewController.appData = appData as? Dictionary<String, Any> ?? Dictionary<String, Any>()
        NSApplication.shared.keyWindow?.contentViewController?.presentAsModalWindow(viewController)
    }
    
}

