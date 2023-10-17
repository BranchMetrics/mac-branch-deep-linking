//
//  DisplayContentVC.swift
//  SaaS_SDK_TestBed_MacOS
//
//  Created by apple on 28/07/22.
//

import Cocoa

class DisplayContentVC: NSViewController {
    
    @IBOutlet weak var textViewDescription: NSTextView!

    var textDescription = ""
    var linkURL = ""
    var appData : Dictionary<String, Any> = Dictionary<String, Any>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.preferredContentSize = NSMakeSize(600, 400)
        let content = String(format:"\nReferring link: %@ \n\nSession Details:\n %@", linkURL, appData.jsonStringRepresentation!)
        self.textViewDescription.string = content

    }
    
    @IBAction func readDeepLink(_ sender: Any){
        let storyBoard : NSStoryboard = NSStoryboard(name: "Main", bundle:nil)
        if let vc = storyBoard.instantiateController(withIdentifier: "WebviewVC") as? WebviewVC {
            self.presentAsModalWindow(vc)
            self.dismiss(self)
        }
    }
}
