//
//  CommerceTrackContentVC.swift
//  SaaS_SDK_TestBed_MacOS
//
//  Created by apple on 13/08/22.
//

import Cocoa
import Branch

class CommerceTrackContentVC: NSViewController {
    
    private let trackContentOptions = ["ADD_TO_CART", "ADD_TO_WISHLIST", "VIEW_CART", "INITIATE_PURCHASE", "ADD_PAYMENT_INFO", "CLICK_AD", "PURCHASE", "RESERVE", "VIEW_AD"]

    private var trackContentEvents: NSComboBox!
    private var transactionIDTxtField: NSTextField!
    private var currencyTxtField: NSComboBox!
    private var revenueTxtField: NSTextField!
    private var shippingTxtField: NSTextField!
    private var taxTxtField: NSTextField!
    private var couponTxtField: NSTextField!
    private var affiliationTxtField: NSTextField!
    private var eventDescriptionTxtField: NSTextField!
    private var searchQueryTxtField: NSTextField!
    private var customDataOneTxtField: NSTextField!

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
        transactionIDTxtField = view2
        transactionIDTxtField.placeholderString = "Transaction ID"
        
        let view3 = getComboBox(targetVew: documentView)
        currencyTxtField = view3
        currencyTxtField.placeholderString = Utils.shared.currencyNames.first
        currencyTxtField.addItems(withObjectValues: Utils.shared.currencyNames)
        currencyTxtField.reloadData()
        currencyTxtField.selectItem(at: 0)
        
        let view4 = getTextField(targetVew: documentView)
        revenueTxtField = view4
        revenueTxtField.placeholderString = "Revenue"
        
        let view5 = getTextField(targetVew: documentView)
        shippingTxtField = view5
        shippingTxtField.placeholderString = "Shipping"
        
        let view6 = getTextField(targetVew: documentView)
        taxTxtField = view6
        taxTxtField.placeholderString = "Tax"
        
        let view7 = getTextField(targetVew: documentView)
        couponTxtField = view7
        couponTxtField.placeholderString = "Coupon"
        
        let view8 = getTextField(targetVew: documentView)
        affiliationTxtField = view8
        affiliationTxtField.placeholderString = "Affiliation"
        
        let view9 = getTextField(targetVew: documentView)
        eventDescriptionTxtField = view9
        eventDescriptionTxtField.placeholderString = "Event Description"
        
        let view10 = getTextField(targetVew: documentView)
        searchQueryTxtField = view10
        searchQueryTxtField.placeholderString = "Search Query"
        
        let view11 = getTextField(targetVew: documentView)
        customDataOneTxtField = view11
        customDataOneTxtField.placeholderString = "Custom Data"
        
        
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
        documentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-15-[view1]-15-[view2]-15-[view3]-15-[view4]-15-[view5]-15-[view6]-15-[view7]-15-[view8]-15-[view9]-15-[view10]-15-[view11]-20-[submitButton]", options: [], metrics: nil, views: ["view1": view1, "view2": view2, "view3": view3, "view4": view4, "view5": view5, "view6": view6, "view7": view7, "view8": view8, "view9": view9, "view10": view10, "view11": view11, "submitButton": submitButton]))
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

        event.transactionID     = transactionIDTxtField.stringValue
        let currencySelected: BNCCurrency = BNCCurrency(rawValue: Utils.shared.currencyNames[currencyTxtField.indexOfSelectedItem])
        event.currency          = currencySelected
        let notanumber = NSDecimalNumber.notANumber
        if revenueTxtField.stringValue.isEmpty{
            event.revenue          = 0
        } else {
            let formattedPrice  = NSDecimalNumber(string: revenueTxtField.stringValue)
            event.revenue          = formattedPrice == notanumber ? 0 : formattedPrice
        }
        if shippingTxtField.stringValue.isEmpty{
            event.shipping         = 0
        } else{
            let formattedPrice  = NSDecimalNumber(string: shippingTxtField.stringValue)
            event.shipping         = formattedPrice == notanumber ? 0 : formattedPrice
        }
        if taxTxtField.stringValue.isEmpty{
            event.tax              = 0
        } else{
            let formattedPrice  = NSDecimalNumber(string: taxTxtField.stringValue)
            event.tax              = formattedPrice == notanumber ? 0 : formattedPrice
        }
        event.coupon           = couponTxtField.stringValue
        event.affiliation      = affiliationTxtField.stringValue
        event.eventDescription = eventDescriptionTxtField.stringValue
        event.searchQuery      = searchQueryTxtField.stringValue
        event.customData       = [
            "Custom_Event_Property_Key1": customDataOneTxtField.stringValue
        ]

        CommonMethod.sharedInstance.branchEvent = event
        
        NotificationCenter.default.post(name: NSNotification.Name("LogTrackEvent"), object: nil)
    }
    
}
