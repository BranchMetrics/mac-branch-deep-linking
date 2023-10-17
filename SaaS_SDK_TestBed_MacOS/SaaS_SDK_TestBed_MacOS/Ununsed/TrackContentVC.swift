//
//  TrackContentVC.swift
//  SaaS_SDK_TestBed_MacOS
//
//  Created by apple on 21/07/22.
//

import Cocoa

class TrackContentVC: NSViewController {

    @IBOutlet weak var trackContentTypesSegmentControl: NSSegmentedControl!
    @IBOutlet weak var vc1ContainerView: NSView!
    @IBOutlet weak var vc2ContainerView: NSView!
    @IBOutlet weak var vc3ContainerView: NSView!
    @IBOutlet weak var vc4ContainerView: NSView!

    var containerViewArr: [NSView] = [NSView]()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerViewArr = [vc1ContainerView, vc2ContainerView, vc3ContainerView, vc4ContainerView]
        
        trackContentTypesSegmentControl.selectedSegment = 0
        trackContentTypesSegmentControl.performClick(trackContentTypesSegmentControl)

        self.title = "Track Content"

        NotificationCenter.default.addObserver(self, selector: #selector(listenTrackContentLogType), name: NSNotification.Name("LogTrackEvent"), object: nil)
    }
    
    @objc func listenTrackContentLogType(){
        let storyBoard : NSStoryboard = NSStoryboard(name: "Main", bundle:nil)
        let vc = storyBoard.instantiateController(withIdentifier: "CreateObjectReferenceObject") as! CreateObjectReferenceObject
        vc.screenMode = 7
        self.dismiss(self)
        self.presentAsModalWindow(vc)
    }
    
    @IBAction func trackContentTypesValueChanged(_ sender : NSSegmentedControl){
        _ = containerViewArr.map { element in
            element.isHidden = true
        }
        switch sender.selectedSegment{
        case 0 :
            vc1ContainerView.isHidden = false
        case 1 :
            vc2ContainerView.isHidden = false
        case 2 :
            vc3ContainerView.isHidden = false
        case 3 :
            vc4ContainerView.isHidden = false
        default:
            vc1ContainerView.isHidden = false
        }
    }
    
}
