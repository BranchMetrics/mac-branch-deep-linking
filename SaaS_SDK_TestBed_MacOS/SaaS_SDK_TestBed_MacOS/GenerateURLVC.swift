//
//  GenerateURLVC.swift
//  SaaS_SDK_TestBed_MacOS
//
//  Created by ajaykumar on 12/07/22.
//

import Cocoa
import Branch

class GenerateURLVC: NSViewController {
    var responseStatus = ""
    var screenMode = 0
    
    var dictData = [String:Any]()
    
    var isShareDeepLink = false
    var isDisplayContent = false
    var isNavigateToContent = false
    var isTrackContent = false
    var handleLinkInWebview = false
    var isCreateDeepLink = false
    var forNotification = false
    var readDeeplink = false

    @IBOutlet weak var txtFldCChannel: NSTextField!
    @IBOutlet weak var txtFldFeature: NSTextField!
    @IBOutlet weak var txtFldChampaignName: NSTextField!
    @IBOutlet weak var txtFldStage: NSTextField!
    @IBOutlet weak var txtFldDeskTopUrl: NSTextField!
    @IBOutlet weak var txtFldAndroidUrl: NSTextField!
    @IBOutlet weak var txtFldiOSTopUrl: NSTextField!
    @IBOutlet weak var txtFldAdditionalData: NSTextField!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    override func viewWillAppear() {
        super.viewWillAppear()
        CommonMethod.sharedInstance.resetBranchLinkProperties()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        Utils.shared.clearAllLogFiles()
        if readDeeplink {
            Utils.shared.setLogFile("ReadDeeplink")
        }  else if isDisplayContent{
            Utils.shared.setLogFile("DisplayContent")
        } else{
            Utils.shared.setLogFile("CreateDeeplink")
        }
    }
    @IBAction func submitAction(_ sender: NSButton) {
        if readDeeplink {
            Utils.shared.setLogFile("ReadDeeplink")
        }  else if isDisplayContent{
            Utils.shared.setLogFile("DisplayContent")
        } else{
            Utils.shared.setLogFile("CreateDeeplink")
        }
        let linkProperties:BranchLinkProperties = BranchLinkProperties()
        linkProperties.feature = txtFldFeature.stringValue
        linkProperties.channel = txtFldCChannel.stringValue
        linkProperties.campaign = txtFldChampaignName.stringValue
        linkProperties.stage = txtFldStage.stringValue
        let controlParams: NSMutableDictionary = ["$desktop_url":txtFldDeskTopUrl.stringValue,
                                        "$ios_url": txtFldiOSTopUrl.stringValue,
                                        "$android_url":txtFldAndroidUrl.stringValue,
                                        "custom":txtFldAdditionalData.stringValue]
        if isNavigateToContent == true {
            controlParams["nav_to"] =  "landing_page"
        } else if isDisplayContent == true {
            controlParams["display_Cont"] = "landing_page"
        }
        linkProperties.controlParams = controlParams
        CommonMethod.sharedInstance.linkProperties = linkProperties
        Branch.sharedInstance.branchShortLink(withContent: CommonMethod.sharedInstance.branchUniversalObject!, linkProperties: CommonMethod.sharedInstance.linkProperties!) { [weak self] shortLinkURL, error in
            if error == nil {
                self?.responseStatus = "Success"
                /*if self?.isCreateDeepLink == true {
                    /*if let _shortLinkURL = shortLinkURL{
                        self?.dismiss(self)
                        NSWorkspace.shared.open(_shortLinkURL)
                    }*/
                    self?.processShortURLGenerated(shortLinkURL?.absoluteString)
                }else{
                    self?.processShortURLGenerated(shortLinkURL?.absoluteString)
                }*/
                self?.processShortURLGenerated(shortLinkURL?.absoluteString)
            }else{
                self?.responseStatus = "Failure"
            }
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
    
    // MARK: - Unused Methods
    
    fileprivate func testCreateDeepLinkWithDummyData() {
        let buo = createUniversalObject()
        
        let feature = "Sharing Feature"
        let channel = "Distribution Channel"
        let desktop_url = "http://branch.io"
        let linkProperties = BranchLinkProperties()
        linkProperties.feature = feature
        linkProperties.channel = channel
        linkProperties.campaign = ""
        linkProperties.stage = ""
        linkProperties.controlParams["$desktop_url"] = desktop_url
        linkProperties.controlParams["$ios_url"] = ""
        linkProperties.controlParams["$android_url"] = ""
        linkProperties.controlParams["custom"] = ""
        if isNavigateToContent == true {
            linkProperties.controlParams["nav_to"] = "landing_page"
        } else if isDisplayContent == true {
            linkProperties.controlParams["display_Cont"] = "landing_page"
        }
        Branch.sharedInstance.branchShortLink(
            withContent: buo!,
            linkProperties: linkProperties) { [weak self] shortURL, error in
                if (error == nil) {
                    NSLog("Successfully indexed on spotlight \(shortURL!)")
                    //                    self?.showAlertWithTitle(question: "Alert", text: "BranchUniversalObject reference created")
                    self?.processShortURLGenerated(shortURL?.path)
                    
                }
            }
    }

    
    func createUniversalObject() -> BranchUniversalObject? {
        let canonicalIdentifier = "item/12345"
        let canonicalUrl = "https://dev.branch.io/getting-started/deep-link-routing/guide/ios/"
        let contentTitle = "Content Title"
        let contentDescription = "My Content Description"
        let imageUrl = """
            http://a57.foxnews.com/images.foxnews.com/content/fox-news/science/2018/03/20/\
            first-day-spring-arrives-5-things-to-know-about-vernal-equinox/_jcr_content/\
            par/featured_image/media-0.img.jpg/1862/1048/1521552912093.jpg?ve=1&tl=1
            """
        let buo = BranchUniversalObject(canonicalIdentifier: canonicalIdentifier)
        buo.canonicalUrl = canonicalUrl
        buo.title = contentTitle
        buo.contentDescription = contentDescription
        buo.imageUrl = imageUrl
        buo.contentMetadata.price = NSDecimalNumber(string: "1000.00")
        buo.contentMetadata.currency = .USD
        buo.contentMetadata.contentSchema = BranchContentSchema.textArticle
        buo.contentMetadata.customMetadata["deeplink_text"] = """
            This text was embedded as data in a Branch link with the following characteristics:\n\n\
            canonicalUrl: \(canonicalUrl)\n  title: \(contentTitle)\n  contentDescription: \(contentDescription)\n  imageUrl: \(imageUrl)\n
            """
        return buo
    }
    fileprivate func processShortURLGenerated(_ url: String?) {
        NSLog("Check out my ShortUrl!! \(url ?? "")")
        if readDeeplink {
            Utils.shared.setLogFile("ReadDeeplink")
        } else if isDisplayContent{
            Utils.shared.setLogFile("DisplayContent")
        } else{
            Utils.shared.setLogFile("CreateDeeplink")
        }
        var alertMessage = ""

        if readDeeplink {
            alertMessage = self.getAPIDetailFromLogFile("ReadDeeplink.log")
        } else if isDisplayContent{
            alertMessage = self.getAPIDetailFromLogFile("DisplayContent.log")
        }else{
            alertMessage = self.getAPIDetailFromLogFile("CreateDeeplink.log")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            UserDefaults.standard.set("createdeeplinking", forKey: "isStatus")
            UserDefaults.standard.set(true, forKey: "isCreatedDeepLink")
            UserDefaults.standard.set("\(url ?? "")", forKey: "link")
            if self.isTrackContent{
                UserDefaults.standard.set(false, forKey: "trackContentlogShown")
            }
            self.openLogDisplayPage(dict: [:], message: alertMessage, ShareDeepLink: self.isShareDeepLink, displayContent: self.isDisplayContent, NavigateToContent: self.isNavigateToContent, TrackContent: self.isTrackContent, handleLinkInWebview: self.handleLinkInWebview, CreateDeepLink: self.isCreateDeepLink, forNotification: self.forNotification, readDeeplink: self.readDeeplink)
        }
    }

}
