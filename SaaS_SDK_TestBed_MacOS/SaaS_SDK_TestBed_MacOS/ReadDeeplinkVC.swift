//
//  ReadDeeplinkVC.swift
//  SaaS_SDK_TestBed_MacOS
//
//  Created by apple on 28/07/22.
//

import Cocoa

class ReadDeeplinkVC: NSViewController {

    @IBOutlet weak var labelTxt: NSTextField!

    var strTxt = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        labelTxt.stringValue = "Success\nUrl is generated.\nHere is the Short URL\(strTxt)"

    }
    
    @IBAction func btnrReadDeeplink(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "isRead")
        let anURL = URL(string: strTxt)
        Branch.sharedInstance.open(anURL)
        self.dismiss(self)
    }

}
