//
//  LifecycleTrackContentVC.swift
//  SaaS_SDK_TestBed_MacOS
//
//  Created by apple on 13/08/22.
//

import Cocoa
import Branch

class LifecycleTrackContentVC: NSViewController {
        
    private let trackContentOptions = ["COMPLETE_REGISTRATION", "COMPLETE_TUTORIAL", "ACHIEVE_LEVEL", "UNLOCK_ACHIEVEMENT", "INVITE", "LOGIN", "START_TRIAL", "SUBSCRIBE"]

    private var trackContentEvents: NSComboBox!
    private var aliasTextField: NSTextField!
    private var transactionIDTextField: NSTextField!
    private var eventDescriptionTextField: NSTextField!
    private var customDataTextField: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = NSColor.gridColor
        scrollView.hasVerticalScroller = true
        
        self.view.addSubview(scrollView)
        setConstraints(forView: scrollView, targetView: self.view, bottomNeeded: true)
        
        // Initial clip view
        let clipView = NSClipView()
        clipView.translatesAutoresizingMaskIntoConstraints = false
        clipView.backgroundColor = NSColor.gridColor
        scrollView.contentView = clipView
        setConstraints(forView: clipView, targetView: scrollView, bottomNeeded: true)
        
        // Initial document view
        let documentView = NSView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        documentView.wantsLayer = true
        documentView.layer?.backgroundColor = NSColor.gridColor.cgColor
        
        scrollView.documentView = documentView
        setConstraints(forView: clipView, targetView: documentView, bottomNeeded: false)
        
        
        let view1 = getComboBox(targetVew: documentView)
        trackContentEvents = view1
        trackContentEvents.placeholderString = trackContentOptions.first
        trackContentEvents.addItems(withObjectValues: trackContentOptions)
        trackContentEvents.reloadData()
        trackContentEvents.selectItem(at: 0)

        let view2 = getTextField(targetVew: documentView)
        aliasTextField = view2
        aliasTextField.placeholderString = "Alias"
        
        let view3 = getTextField(targetVew: documentView)
        transactionIDTextField = view3
        transactionIDTextField.placeholderString = "Transaction ID"
        
        let view4 = getTextField(targetVew: documentView)
        eventDescriptionTextField = view4
        eventDescriptionTextField.placeholderString = "Event Description"
        
        let view5 = getTextField(targetVew: documentView)
        customDataTextField = view5
        customDataTextField.placeholderString = "Custom Data"
        
        let submitButton = NSButton()
        submitButton.wantsLayer = true
        submitButton.controlSize = .large
        submitButton.setButtonType(.momentaryPushIn)
        submitButton.bezelStyle = .roundRect
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        //submitButton.title = "Submit"
        let attributes: [NSAttributedString.Key : Any] = [.foregroundColor: NSColor.white]
        submitButton.attributedTitle = NSMutableAttributedString(string: "Submit", attributes: attributes)
        //        submitButton.bezelColor = NSColor(calibratedRed: 89/255, green: 12/255, blue: 228/255, alpha: 1)
        //        submitButton.contentTintColor = NSColor(calibratedRed: 89/255, green: 12/255, blue: 228/255, alpha: 1)
        submitButton.layer?.backgroundColor = NSColor(calibratedRed: 89/255, green: 12/255, blue: 228/255, alpha: 1).cgColor
        submitButton.action = #selector(submitButtonAction(_:))
        documentView.addSubview(submitButton)
        documentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-50-[submitButton]-50-|", options: [], metrics: nil, views: ["submitButton": submitButton]))
        
        // Vertical autolayout
        documentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-15-[view1]-15-[view2]-15-[view3]-15-[view4]-15-[view5]-20-[submitButton]", options: [], metrics: nil, views: ["view1": view1, "view2": view2, "view3": view3, "view4": view4, "view5": view5, "submitButton": submitButton]))
        documentView.addConstraint(NSLayoutConstraint(item: documentView, attribute: .bottom, relatedBy: .equal, toItem: submitButton, attribute: .bottom, multiplier: 1.0, constant: 20))
        
        
    }
    
    func setConstraints(forView: NSView, targetView: NSView, bottomNeeded:Bool){
        self.view.addConstraint(NSLayoutConstraint(item: forView, attribute: .left, relatedBy: .equal, toItem: targetView, attribute: .left, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: forView, attribute: .top, relatedBy: .equal, toItem: targetView, attribute: .top, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: forView, attribute: .right, relatedBy: .equal, toItem: targetView, attribute: .right, multiplier: 1.0, constant: 0))
        if bottomNeeded {
            self.view.addConstraint(NSLayoutConstraint(item: forView, attribute: .bottom, relatedBy: .equal, toItem: targetView, attribute: .bottom, multiplier: 1.0, constant: 0))
        }
        
    }
    
    func getTextField(targetVew: NSView) -> NSTextField{
        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        targetVew.addSubview(textField)
        targetVew.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-40-[textField]-40-|", options: [], metrics: nil, views: ["textField": textField]))
        return textField
    }
    
    func getComboBox(targetVew: NSView) -> NSComboBox{
        let textField = NSComboBox()
        textField.translatesAutoresizingMaskIntoConstraints = false
        targetVew.addSubview(textField)
        targetVew.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-40-[textField]-40-|", options: [], metrics: nil, views: ["textField": textField]))
        return textField
    }
    
    @IBAction func submitButtonAction(_ sender: Any) {
        NSLog(#function)
        
        let trackContentOptionSelected = trackContentOptions[trackContentEvents.indexOfSelectedItem]

        let stdevent = BranchStandardEvent(rawValue: trackContentOptionSelected)
        let event = BranchEvent.standardEvent(stdevent)

        event.transactionID     = transactionIDTextField.stringValue
        event.eventDescription = eventDescriptionTextField.stringValue
        event.customData       = [
            "Custom_Event_Property_Key1": customDataTextField.stringValue
        ]

        CommonMethod.sharedInstance.branchEvent = event
        
        NotificationCenter.default.post(name: NSNotification.Name("LogTrackEvent"), object: nil)

    }
    
}
