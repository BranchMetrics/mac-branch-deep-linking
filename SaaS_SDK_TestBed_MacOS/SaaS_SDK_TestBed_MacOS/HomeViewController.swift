//
//  ViewController.swift
//  SaaS_SDK_TestBed_MacOS
//
//  Created by ajaykumar on 05/07/22.
//

import Cocoa
import Reachability

class HomeViewController: NSViewController, NSWindowDelegate {
    private var reachability: Reachability?
   
    private var responseStatus = ""

    @IBOutlet weak var btnCreatBUO: NSButton!
    @IBOutlet weak var btnTrackingEnabled: NSSwitch!
    @IBOutlet weak var btnCreateDeepLinking: NSButton!
    @IBOutlet weak var btnShareLink: NSButton!
    @IBOutlet weak var btnSendNotification: NSButton!
    @IBOutlet weak var btnTrackUser: NSButton!
    @IBOutlet weak var btnLoadWebView: NSButton!
    @IBOutlet weak var btReadDeeplink: NSButton!
    @IBOutlet weak var btnTrackContent: NSButton!
    @IBOutlet weak var btnNavigateToContent: NSButton!
    @IBOutlet weak var btnDisplayContent: NSButton!
    
    @IBOutlet weak var labelTrackingEnabled: NSTextField!
    enum ScreenMode  {
        static let createBUO = 0
        static let readdeeplink = 1
        static let sharedeeplink = 5
        static let navigatetoContent = 3
        static let handlLinkinWebview = 4
        static let createdeeplink = 2
        static let sendnotification = 6
        static let trackContent = 7
        static let displayContent = 8
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        Branch.sharedInstance.setUserIdentity("qentelli_test_user_macOS_dev1")
        //self.preferredContentSize = NSMakeSize(600, 400)
        NSLog("userTrackingIsDisabled", Branch.sharedInstance.userTrackingIsDisabled ? "userTrackingIsDisabled" : "userTrackingIsEnabled")
        if Branch.sharedInstance.userTrackingIsDisabled{
            btnTrackingEnabled.state = .off
        }else{
            btnTrackingEnabled.state = .on
        }
        swichAction(btnTrackingEnabled)

        self.title = "Branch-SDK-TestBed"
    }
    
    
    @IBAction func displayContentBtnAction(_ sender: Any) {
        self.launchBUOVC(mode: 8)
    }
    
    @IBAction func navigatetoContentBtnAction(_ sender: Any) {
        self.launchBUOVC(mode: 7)
    }
        
    @IBAction func createDeeplinking(_ sender: Any) {
        self.launchBUOVC(mode: 5)
    }
    
    
    @IBAction func readDeeplinking(_ sender: Any) {
        self.launchBUOVC(mode: 1)
    }
    
    @IBAction func trackContentAction(_ sender: Any) {
        self.launchBUOVC(mode: 7)
    }
    
    @IBAction func swichAction(_ sender: NSSwitch) {
        if sender.state == NSControl.StateValue.on {
            NSLog("is OFF", "ison")
            labelTrackingEnabled.stringValue = "Tracking Enabled"
            Branch.sharedInstance.userTrackingIsDisabled = true
            
        } else {
            NSLog("is ON", "isOFF")
            Branch.sharedInstance.userTrackingIsDisabled = false
            labelTrackingEnabled.stringValue = "Tracking Disabled"
        }
    }

    @IBAction func trackUserAction(_ sender: Any) {
        NSLog("Track user")
        
        Branch.sharedInstance.setUserIdentity("qentelli_test_user_macOS_dev1",
                                              completion: { (branchSession, error) in
            if error == nil{
                self.responseStatus = "Success"
                //Branch.sharedInstance.userTrackingIsDisabled = true
                //self.showAlertWithTitle(alertMessage: "Alert", alertTitle: "Result \(String(describing: branchSession))")
                self.openLogDisplayPage(message: "Result \(String(describing: branchSession))")
                print("Track user sessions",branchSession ??  "NA")
            } else {
                self.responseStatus = "Failure"
                print("error",error ?? "NA")
                self.openLogDisplayPage(message: "Result \(String(describing: error?.localizedDescription))")
            }
            
        })
    }
    
    func openLogDisplayPage(message: String? = ""){
        let storyBoard : NSStoryboard = NSStoryboard(name: "Main", bundle:nil)
        if let vc = storyBoard.instantiateController(withIdentifier: "LogDisplayVC") as? LogDisplayVC {
            vc.textViewText = message!
            vc.responseStatus = self.responseStatus
            self.presentAsModalWindow(vc)
        }
    }

    
    func showAlertWithTitle(alertMessage: String, alertTitle: String) {
        let alert = NSAlert()
        alert.messageText = alertMessage
        alert.informativeText = alertTitle
        alert.alertStyle = NSAlert.Style.critical
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let modalResult = alert.runModal()
        switch modalResult {
        case .alertFirstButtonReturn: // NSApplication.ModalResponse.alertFirstButtonReturn
            NSLog("First button clicked")
        default:
            NSLog("Secon button clicked")
        }
    }
    
    @IBAction func createObject(_ sender: Any) {
        self.launchBUOVC(mode: 0)
    }
    
    func launchBUOVC(mode: Int) {
        CommonMethod.sharedInstance.resetBranchUniversalObject()
        let storyBoard : NSStoryboard = NSStoryboard(name: "Main", bundle:nil)
        if mode == 7 {
            if let vc = storyBoard.instantiateController(withIdentifier: "TrackContentTabbar") as? TrackContentTabVC {
                self.presentAsModalWindow(vc)
            }
        }else{
            if let vc = storyBoard.instantiateController(withIdentifier: "CreateObjectReferenceObject") as? CreateObjectReferenceObject {
                vc.screenMode = mode
                self.presentAsModalWindow(vc)
            }
        }
    }
    
}

