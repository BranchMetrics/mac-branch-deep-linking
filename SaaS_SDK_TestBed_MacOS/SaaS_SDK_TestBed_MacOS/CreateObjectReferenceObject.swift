//
//  File.swift
//  SaaS_SDK_TestBed_MacOS
//
//  Created by ajaykumar on 07/07/22.
//

import Foundation
import Cocoa
import Branch


enum ScreenMode  {
    static let createBUO = 0
    static let readdeeplink = 1
    static let sharedeeplink = 2
    static let navigatetoContent = 3
    static let handlLinkinWebview = 4
    static let createdeeplink = 5
    static let sendnotification = 6
    static let trackContent = 7
    static let displayContent = 8
}

class CreateObjectReferenceObject: NSViewController {
    
    var screenMode = 0
    var txtFldValue = ""
    var responseStatus = ""
    
    
    @IBOutlet weak var txtFldContentTitle: NSTextField!
    @IBOutlet weak var txtFldCanonicalIdentifier: NSTextField!
    @IBOutlet weak var txtFldDescription: NSTextField!
    @IBOutlet weak var txtFldImageUrl: NSTextField!
    
    override func viewWillAppear() {
        super.viewWillAppear()
        Utils.shared.clearAllLogFiles()
        if self.screenMode == ScreenMode.trackContent {
            Utils.shared.setLogFile("TrackContent")
        }
        else {
            Utils.shared.setLogFile("CreateBUO")
        }
    }
    
    @IBAction func addMetadataButtonAction(_ sender: Any) {
        let storyBoard : NSStoryboard = NSStoryboard(name: "Main", bundle:nil)
        if let vc = storyBoard.instantiateController(withIdentifier: "AddMetadataVC") as? AddMetadataVC {
            self.presentAsModalWindow(vc)
        }
    }
    
    fileprivate func getScreenValuesAsDict() -> [String:Any]{
        var dict = [String:Any]()
        dict["$canonicalIdentifier"] = txtFldCanonicalIdentifier.stringValue
        dict["title"] = txtFldContentTitle.stringValue
        dict["description"] = txtFldDescription.stringValue
        dict["imgurl"] = txtFldImageUrl.stringValue
        return dict
    }
    
    @IBAction func submitButtonAction(_ sender: Any) {
        if CommonMethod.sharedInstance.branchUniversalObject == nil {
            CommonMethod.sharedInstance.branchUniversalObject = BranchUniversalObject()
        }
        let buo = CommonMethod.sharedInstance.branchUniversalObject
        buo?.canonicalIdentifier = txtFldCanonicalIdentifier.stringValue
        buo?.title = txtFldContentTitle.stringValue
        buo?.contentDescription = txtFldDescription.stringValue
        buo?.imageUrl = txtFldImageUrl.stringValue
                
        buo?.locallyIndex = true
        buo?.publiclyIndex = true
        if CommonMethod.sharedInstance.contentMetaData != nil {
            buo?.contentMetadata = CommonMethod.sharedInstance.contentMetaData!
        }
        NSLog("universalObject:", buo!)
        if self.screenMode == ScreenMode.trackContent {
            let event = CommonMethod.sharedInstance.branchEvent
            event.contentItems = [buo!]
            Branch.sharedInstance.userTrackingIsDisabled = false
            Branch.sharedInstance.logEvent(event) { (loggingErr) in
                if loggingErr == nil {
                    self.responseStatus = "Success"
                    NSLog("BranchEvent Logged")
                    NSLog("Brach event successfully logged %@", event.debugDescription)
                    //self.showAlertWithTitle(alertMessage: "Alert", alertTitle:"BranchUniversalObject reference created" )
                    UserDefaults.standard.set(true, forKey: "trackContentlogShown")
                    let alertMessage = self.getAPIDetailFromLogFile("TrackContent.log")
                    self.openLogDisplayPage(dict: [:], message: alertMessage, TrackContent: true)
                }else {
                    self.showAlertWithTitle(alertMessage: "Failure", alertTitle:"Failed to create BranchUniversalObject reference \(loggingErr?.localizedDescription ?? "")" )
                    NSLog("BranchEvent failed to log\(loggingErr?.localizedDescription ?? "NA")")
                }
            }
            
        }
        else {
            NSLog("BranchUniversalObject reference created")
            self.showAlertWithTitle(alertMessage: "Alert", alertTitle:"BranchUniversalObject reference created" )
        }
    }
        
    
    func showAlertWithTitle(alertMessage: String, alertTitle: String) {
        let alert = NSAlert()
        alert.messageText = alertMessage
        alert.informativeText = alertTitle
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let modalResult = alert.runModal()
        switch modalResult {
        case .alertFirstButtonReturn: // NSApplication.ModalResponse.alertFirstButtonReturn
            NSLog("First button clicked")
            if alertMessage == "Failure" {
                
            }else {
                if self.screenMode == ScreenMode.createdeeplink {
                    self.handleOkBtnAction(dict: getScreenValuesAsDict(), alertMessage: "")
                } else if self.screenMode == ScreenMode.trackContent {
                    self.handleOkBtnAction(dict: getScreenValuesAsDict(), alertMessage: "")
                }else if self.screenMode == ScreenMode.displayContent {
                    self.handleOkBtnAction(dict: getScreenValuesAsDict(), alertMessage: "")
                }else if self.screenMode == ScreenMode.readdeeplink {
                    self.handleOkBtnAction(dict: getScreenValuesAsDict(), alertMessage: "")
                }else {
                    self.dismiss(self)
                }
            }
        default:
            NSLog("Secon button clicked")
        }
    }
    
    fileprivate func handleOkBtnAction(dict : [String:Any], alertMessage: String) {
        Utils.shared.setLogFile("CreateBUO")
        if self.screenMode == ScreenMode.displayContent {
            NSLog("screenMode:", self.screenMode)
            launchGenerateURLVC(dict: dict, displayContent: true)
        }else if self.screenMode == ScreenMode.trackContent {
            NSLog("screenMode:", self.screenMode)
            launchGenerateURLVC(dict: dict, TrackContent: true)
        }else if self.screenMode == ScreenMode.sendnotification {
            NSLog("screenMode:", self.screenMode)
            launchGenerateURLVC(dict: dict, forNotification: true)
        }else if self.screenMode == ScreenMode.createdeeplink {
            NSLog("screenMode:", self.screenMode)
            launchGenerateURLVC(dict: dict, CreateDeepLink: true)
        }else if self.screenMode == ScreenMode.sharedeeplink {
            NSLog("screenMode:", self.screenMode)
            launchGenerateURLVC(dict: dict, ShareDeepLink: true)
        }else if self.screenMode == ScreenMode.readdeeplink {
            NSLog("screenMode:", self.screenMode)
            launchGenerateURLVC(dict: dict, readDeeplink: true)
        }else if self.screenMode == ScreenMode.navigatetoContent {
            NSLog("screenMode:", self.screenMode)
            launchGenerateURLVC(dict: dict, NavigateToContent: true)
        }else if self.screenMode == ScreenMode.handlLinkinWebview {
            NSLog("screenMode:", self.screenMode)
            launchGenerateURLVC(dict: dict, handleLinkInWebview: true)
        }else {
            self.dismiss(self)
        }
    }
    
    func openLogDisplayPage(dict: [String:Any], message: String? = "", ShareDeepLink: Bool? = false, displayContent: Bool? = false, NavigateToContent: Bool? = false, TrackContent: Bool? = false, handleLinkInWebview: Bool? = false, CreateDeepLink: Bool? = false, forNotification: Bool? = false, readDeeplink: Bool? = false){
        let storyBoard : NSStoryboard = NSStoryboard(name: "Main", bundle:nil)
        if let vc = storyBoard.instantiateController(withIdentifier: "LogDisplayVC") as? LogDisplayVC {
            vc.isTrackContent = TrackContent!
            vc.forNotification = forNotification!
            vc.isCreateDeepLink = CreateDeepLink!
            vc.isShareDeepLink = ShareDeepLink!
            vc.isNavigateToContent = NavigateToContent!
            vc.handleLinkInWebview = handleLinkInWebview!
            vc.isDisplayContent = displayContent!
            vc.readDeeplink = readDeeplink!
            vc.dictData = dict
            vc.textViewText = message!
            vc.responseStatus = self.responseStatus
            self.presentAsModalWindow(vc)
            self.dismiss(self)
        }
    }
    
    func openGenerateURLPage(dict: [String:Any], message: String? = "", ShareDeepLink: Bool? = false, displayContent: Bool? = false, NavigateToContent: Bool? = false, TrackContent: Bool? = false, handleLinkInWebview: Bool? = false, CreateDeepLink: Bool? = false, forNotification: Bool? = false, readDeeplink: Bool? = false){
        let storyBoard : NSStoryboard = NSStoryboard(name: "Main", bundle:nil)
        if let vc = storyBoard.instantiateController(withIdentifier: "GenerateURLVC") as? GenerateURLVC {
            vc.isTrackContent = TrackContent!
            vc.forNotification = forNotification!
            vc.isCreateDeepLink = CreateDeepLink!
            vc.isShareDeepLink = ShareDeepLink!
            vc.isNavigateToContent = NavigateToContent!
            vc.handleLinkInWebview = handleLinkInWebview!
            vc.isDisplayContent = displayContent!
            vc.readDeeplink = readDeeplink!
            vc.dictData = dict
            self.presentAsModalWindow(vc)
            self.dismiss(self)
        }
    }
    func launchGenerateURLVC(dict: [String:Any], message: String? = "", ShareDeepLink: Bool? = false, displayContent: Bool? = false, NavigateToContent: Bool? = false, TrackContent: Bool? = false, handleLinkInWebview: Bool? = false, CreateDeepLink: Bool? = false, forNotification: Bool? = false, readDeeplink: Bool? = false) {
        openGenerateURLPage(dict: dict, message: message, ShareDeepLink: ShareDeepLink, displayContent: displayContent, NavigateToContent: NavigateToContent, TrackContent: TrackContent, handleLinkInWebview: handleLinkInWebview, CreateDeepLink: CreateDeepLink, forNotification: forNotification, readDeeplink: readDeeplink)
    }
    
    
    private func loadTextWithFileName(_ fileName: String) -> String? {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(fileName)
            guard let text = try? String(contentsOf: fileURL, encoding: .utf8) else {
                return nil
            }
            return text
        }
        return nil
    }
    
    fileprivate func getAPIDetailFromLogFile(_ fileName: String) -> String{
        var alertMessage = "LogFilePath : \(self.getLogFilepath(fileName)!) \n\n"
        alertMessage = alertMessage + "\n\n"
        if let fileContent = self.loadTextWithFileName(fileName), !fileContent.isEmpty {
            let startlocation = fileContent.range(of: "BranchSDK API LOG START OF FILE")
            let endlocation = fileContent.range(of: "BranchSDK API LOG END OF FILE")
            let apiResponse = fileContent[startlocation!.lowerBound..<endlocation!.lowerBound]
            alertMessage = alertMessage + apiResponse
        }
        return alertMessage
    }
    
    fileprivate func getLogFilepath(_ fileName: String) -> String? {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let fileURL = dir?.appendingPathComponent(fileName)
        let fileURLStr = fileURL?.path
        return fileURLStr
    }
    
}
