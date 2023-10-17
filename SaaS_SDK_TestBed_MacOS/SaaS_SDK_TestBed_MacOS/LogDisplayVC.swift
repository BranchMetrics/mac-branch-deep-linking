//
//  LogDisplayVC.swift
//  SaaS_SDK_TestBed_MacOS
//
//  Created by apple on 25/07/22.
//

import Cocoa

class LogDisplayVC: NSViewController {
    
    @IBOutlet weak var logDataTextView: NSTextView!
    
    @IBOutlet weak var statusLabel: NSTextField!
    
    var isShareDeepLink = false
    var isNavigateToContent = false
    var isDisplayContent = false
    var isTrackContent = false
    var isTrackContenttoWeb = false
    var handleLinkInWebview = false
    var isCreateDeepLink = false
    var forNotification = false
    var isTrackUser = false
    var readDeeplink = false
    
    var url = ""
    var responseStatus = ""
    var dictData = [String:Any]()
    var textViewText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.statusLabel.stringValue = "Success"
        
        self.logDataTextView.string = textViewText
        
        if let deeplinkurl: String = UserDefaults.standard.string(forKey: "link"){
            url = deeplinkurl
        }
        
    }
    
    fileprivate func showReadDeeplink(_ storyBoard: NSStoryboard) {
        if let vc = storyBoard.instantiateController(withIdentifier: "ReadDeeplinkVC") as? ReadDeeplinkVC {
            vc.strTxt = url
            self.dismiss(self)
            self.presentAsModalWindow(vc)
        }
    }
    
    fileprivate func showWebView(_ storyBoard: NSStoryboard) {
        if let vc = storyBoard.instantiateController(withIdentifier: "WebviewVC") as? WebviewVC {
            self.dismiss(self)
            self.presentAsModalWindow(vc)
        }
    }
    
    @IBAction func nextButtonAction(_ sender: Any) {
        let storyBoard : NSStoryboard = NSStoryboard(name: "Main", bundle:nil)
        if self.isTrackContent == true {
            let trackContentlogShown = UserDefaults.standard.bool(forKey: "trackContentlogShown")
            if trackContentlogShown {
                if let vc = storyBoard.instantiateController(withIdentifier: "GenerateURLVC") as? GenerateURLVC {
                    vc.isTrackContent = self.isTrackContent
                    self.dismiss(self)
                    self.presentAsModalWindow(vc)
                }
            } else {
                showWebView(storyBoard)
            }
        } else if self.isDisplayContent == true {
            showReadDeeplink(storyBoard)
        } else if self.readDeeplink == true{
            showReadDeeplink(storyBoard)
        } else if self.isCreateDeepLink == true{
            showWebView(storyBoard)
        } else {
            self.dismiss(self)
        }
    }
    
}
