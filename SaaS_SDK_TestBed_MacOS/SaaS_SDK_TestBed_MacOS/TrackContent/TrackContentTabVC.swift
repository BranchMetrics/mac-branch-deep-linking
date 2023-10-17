//
//  TrackContentTabVC.swift
//  SaaS_SDK_TestBed_MacOS
//
//  Created by apple on 16/08/22.
//

import Cocoa

class TrackContentTabVC: NSTabViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.selectedTabViewItemIndex  = 0
        NotificationCenter.default.addObserver(self, selector: #selector(listenTrackContentLogType), name: NSNotification.Name("LogTrackEvent"), object: nil)
        self.title = "Track Content"

    }
    
    @objc func listenTrackContentLogType(){
        let storyBoard : NSStoryboard = NSStoryboard(name: "Main", bundle:nil)
        let vc = storyBoard.instantiateController(withIdentifier: "CreateObjectReferenceObject") as! CreateObjectReferenceObject
        vc.screenMode = 7
        self.view.window?.close()
        self.presentAsModalWindow(vc)
    }
    
    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        let selectedIndex = tabView.indexOfTabViewItem(tabViewItem ?? NSTabViewItem())
        if selectedIndex == 0 {
            self.preferredContentSize = NSMakeSize(450, 470)
        } else if selectedIndex == 3 {
            self.preferredContentSize = NSMakeSize(450, 230)
        }else{
            self.preferredContentSize = NSMakeSize(450, 250)
        }
    }

}
