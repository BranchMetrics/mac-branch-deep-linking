//
//  OldTrackContentVC.swift
//  SaaS_SDK_TestBed_MacOS
//
//  Created by apple on 14/08/22.
//

import Cocoa

class OldTrackContentVC: NSViewController {

    @IBOutlet weak var trackContentComboBox: NSComboBox!
    @IBOutlet weak var currencyComboBox: NSComboBox!
    
    @IBOutlet weak var transactionIDTextField: NSTextField!
    @IBOutlet weak var revenueTextField: NSTextField!
    @IBOutlet weak var shippingTextField: NSTextField!
    @IBOutlet weak var taxTextField: NSTextField!
    @IBOutlet weak var couponTextField: NSTextField!
    @IBOutlet weak var affiliationTextField: NSTextField!
    @IBOutlet weak var eventDescriptionTextField: NSTextField!
    @IBOutlet weak var searchQueryTextField: NSTextField!
    @IBOutlet weak var customDataTextField: NSTextField!


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        trackContentComboBox.placeholderString = Utils.shared.trackContentOptions.first
        trackContentComboBox.addItems(withObjectValues: Utils.shared.trackContentOptions)
        trackContentComboBox.reloadData()
        trackContentComboBox.selectItem(at: 0)

        currencyComboBox.placeholderString = Utils.shared.currencyNames.first
        currencyComboBox.addItems(withObjectValues: Utils.shared.currencyNames)
        currencyComboBox.reloadData()
        currencyComboBox.selectItem(at: 0)

    }
    
    func createEvent() -> BranchEvent{
        let trackContentOptionSelected = Utils.shared.trackContentOptions[trackContentComboBox.indexOfSelectedItem]
        let selectedEvent: BranchStandardEvent = BranchStandardEvent(rawValue: trackContentOptionSelected)
        let event = BranchEvent.standardEvent(selectedEvent)
        //event.contentItems     = [ CommonMethod.sharedInstance.branchUniversalObject ]

        event.transactionID    = transactionIDTextField.stringValue
        let currencySelected: BNCCurrency = BNCCurrency(rawValue: Utils.shared.currencyNames[currencyComboBox.indexOfSelectedItem])
        event.currency         = currencySelected
        let notanumber = NSDecimalNumber.notANumber
        if revenueTextField.stringValue.isEmpty{
            event.revenue          = 0
        } else {
            let formattedPrice  = NSDecimalNumber(string: revenueTextField.stringValue)
            event.revenue          = formattedPrice == notanumber ? 0 : formattedPrice
        }
        if shippingTextField.stringValue.isEmpty{
            event.shipping         = 0
        } else{
            let formattedPrice  = NSDecimalNumber(string: shippingTextField.stringValue)
            event.shipping         = formattedPrice == notanumber ? 0 : formattedPrice
        }
        if taxTextField.stringValue.isEmpty{
            event.tax              = 0
        } else{
            let formattedPrice  = NSDecimalNumber(string: taxTextField.stringValue)
            event.tax              = formattedPrice == notanumber ? 0 : formattedPrice
        }
        event.coupon           = couponTextField.stringValue
        event.affiliation      = affiliationTextField.stringValue
        event.eventDescription = eventDescriptionTextField.stringValue
        event.searchQuery      = searchQueryTextField.stringValue
        event.customData       = [
            "Custom_Event_Property_Key1": customDataTextField.stringValue
        ]

        return event
    }
    
    
    @IBAction func submitButtonAction(_ sender: Any){
        CommonMethod.sharedInstance.branchEvent = createEvent()
        let storyBoard : NSStoryboard = NSStoryboard(name: "Main", bundle:nil)
        if let vc = storyBoard.instantiateController(withIdentifier: "CreateObjectReferenceObject") as? CreateObjectReferenceObject {
            vc.screenMode = 7
            let trackContentOptionSelected = Utils.shared.trackContentOptions[trackContentComboBox.indexOfSelectedItem]
            vc.txtFldValue = trackContentOptionSelected
            self.presentAsModalWindow(vc)
            self.dismiss(self)
        }
    }

}
