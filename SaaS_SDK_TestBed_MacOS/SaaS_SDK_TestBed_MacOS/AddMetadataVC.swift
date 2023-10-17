//
//  AddMetadataVC.swift
//  SaaS_SDK_TestBed_MacOS
//
//  Created by apple on 19/07/22.
//

import Cocoa
import Branch

class AddMetadataVC: NSViewController {
    
    @IBOutlet weak var submitButton: NSButton!
    
    
    
    private var productName: NSTextField!
    private var productBrand: NSTextField!
    private var productVariant: NSTextField!
    private var street: NSTextField!
    private var city: NSTextField!
    private var region: NSTextField!
    private var country: NSTextField!
    private var postalCode: NSTextField!
    private var latitude: NSTextField!
    private var longitude: NSTextField!
    private var sku: NSTextField!
    private var rating: NSTextField!
    private var averageRating: NSTextField!
    private var maximumRating: NSTextField!
    private var ratingCount: NSTextField!
    private var imageCaption: NSTextField!
    private var quantity: NSTextField!
    private var price: NSTextField!
    private var customMetadata: NSTextField!
    
    private var productCategory: NSComboBox!
    private var productCondition: NSComboBox!
    private var currencyName: NSComboBox!
    private var contentSchema: NSComboBox!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        setupViewWithScroll()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        CommonMethod.sharedInstance.resetBranchContentMetadata()
    }
    
    func setupViewWithScroll(){
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
        
        
        let view1 = getTextField(targetVew: documentView)
        productName = view1
        productName.placeholderString = "Product Name"
        
        let view2 = getTextField(targetVew: documentView)
        productBrand = view2
        productBrand.placeholderString = "Product Brand"
        
        let view3 = getTextField(targetVew: documentView)
        productVariant = view3
        productVariant.placeholderString = "Product Variant"
        
        let view4 = getComboBox(targetVew: documentView)
        productCategory = view4
        productCategory.placeholderString = Utils.shared.productCategories.first
        productCategory.addItems(withObjectValues: Utils.shared.productCategories)
        productCategory.reloadData()
        productCategory.selectItem(at: 0)
        
        let view5 = getComboBox(targetVew: documentView)
        productCondition = view5
        productCondition.placeholderString = Utils.shared.productConditions.first
        productCondition.addItems(withObjectValues: Utils.shared.productConditions)
        productCategory.reloadData()
        productCondition.selectItem(at: 0)
        
        let view6 = getTextField(targetVew: documentView)
        street = view6
        street.placeholderString = "Street"
        
        let view7 = getTextField(targetVew: documentView)
        city = view7
        city.placeholderString = "City"
        
        let view8 = getTextField(targetVew: documentView)
        region = view8
        region.placeholderString = "Region"
        
        let view9 = getTextField(targetVew: documentView)
        country = view9
        country.placeholderString = "Country"
        
        let view10 = getTextField(targetVew: documentView)
        postalCode = view10
        postalCode.placeholderString = "Postal Code"
        
        let view11 = getTextField(targetVew: documentView)
        latitude = view11
        latitude.placeholderString = "Latitude"
        
        let view12 = getTextField(targetVew: documentView)
        longitude = view12
        longitude.placeholderString = "Longitude"
        
        let view13 = getTextField(targetVew: documentView)
        sku = view13
        sku.placeholderString = "SKU"
        
        let view14 = getTextField(targetVew: documentView)
        rating = view14
        rating.placeholderString = "Rating"
        
        let view15 = getTextField(targetVew: documentView)
        averageRating = view15
        averageRating.placeholderString = "Average Rating"
        
        let view16 = getTextField(targetVew: documentView)
        maximumRating = view16
        maximumRating.placeholderString = "Maximum Rating"
        
        let view17 = getTextField(targetVew: documentView)
        ratingCount = view17
        ratingCount.placeholderString = "Rating Count"
        
        let view18 = getTextField(targetVew: documentView)
        imageCaption = view18
        imageCaption.placeholderString = "Image Caption"
        
        let view19 = getTextField(targetVew: documentView)
        quantity = view19
        quantity.placeholderString = "Quantity"
        
        let view20 = getTextField(targetVew: documentView)
        price = view20
        price.placeholderString = "Price"
        
        let view21 = getComboBox(targetVew: documentView)
        currencyName = view21
        currencyName.placeholderString = Utils.shared.currencyNames.first
        currencyName.addItems(withObjectValues: Utils.shared.currencyNames)
        currencyName.selectItem(at: 0)
        
        let view22 = getComboBox(targetVew: documentView)
        contentSchema = view22
        contentSchema.placeholderString = Utils.shared.contentSchemaNames.first
        contentSchema.addItems(withObjectValues: Utils.shared.contentSchemaNames)
        contentSchema.selectItem(at: 0)
        
        let view23 = getTextField(targetVew: documentView)
        customMetadata = view23
        customMetadata.placeholderString = "Custom Metadata"
        
        let submitButton = NSButton()
        submitButton.wantsLayer = true
        submitButton.controlSize = .large
        submitButton.setButtonType(.momentaryPushIn)
        submitButton.bezelStyle = .roundRect
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        //submitButton.title = "Submit"
        let attributes: [NSAttributedString.Key : Any] = [.foregroundColor: NSColor.white]
        submitButton.attributedTitle = NSMutableAttributedString(string: "Submit Metadata", attributes: attributes)
        //        submitButton.bezelColor = NSColor(calibratedRed: 89/255, green: 12/255, blue: 228/255, alpha: 1)
        //        submitButton.contentTintColor = NSColor(calibratedRed: 89/255, green: 12/255, blue: 228/255, alpha: 1)
        submitButton.layer?.backgroundColor = NSColor(calibratedRed: 89/255, green: 12/255, blue: 228/255, alpha: 1).cgColor
        submitButton.action = #selector(submitButtonAction(_:))
        documentView.addSubview(submitButton)
        documentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-50-[submitButton]-50-|", options: [], metrics: nil, views: ["submitButton": submitButton]))
        
        // Vertical autolayout
        documentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-15-[view1]-15-[view2]-15-[view3]-15-[view4]-15-[view5]-15-[view6]-15-[view7]-15-[view8]-15-[view9]-15-[view10]-15-[view11]-15-[view12]-15-[view13]-15-[view14]-15-[view15]-15-[view16]-15-[view17]-15-[view18]-15-[view19]-15-[view20]-15-[view21]-15-[view22]-15-[view23]-20-[submitButton]", options: [], metrics: nil, views: ["view1": view1, "view2": view2, "view3": view3, "view4": view4, "view5": view5, "view6": view6, "view7": view7, "view8": view8, "view9": view9, "view10": view10, "view11": view11, "view12": view12, "view13": view13, "view14": view14, "view15": view15, "view16": view16, "view17": view17, "view18": view18, "view19": view19, "view20": view20, "view21": view21, "view22": view22, "view23": view23, "submitButton": submitButton]))
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
        if CommonMethod.sharedInstance.branchUniversalObject == nil {
            CommonMethod.sharedInstance.branchUniversalObject = BranchUniversalObject()
        }
        let branchUniversalObject: BranchUniversalObject = CommonMethod.sharedInstance.branchUniversalObject!
        branchUniversalObject.canonicalIdentifier = branchUniversalObject.canonicalIdentifier
        branchUniversalObject.canonicalUrl        = "https://branch.io/item/12345"
        branchUniversalObject.title               = branchUniversalObject.title
        
        let contentSchemaSelected : BranchContentSchema = BranchContentSchema(rawValue: Utils.shared.contentSchemaNames[contentSchema.indexOfSelectedItem])
        branchUniversalObject.contentMetadata.contentSchema     = contentSchemaSelected
        
        let notanumber = NSDecimalNumber.notANumber

        if quantity.stringValue.isEmpty{
            branchUniversalObject.contentMetadata.quantity          = 0
        } else {
            let quantityEntered = Double(quantity.stringValue)
            branchUniversalObject.contentMetadata.quantity          = quantityEntered ?? 0
        }
        
        if price.stringValue.isEmpty{
            branchUniversalObject.contentMetadata.price             = 0
        }else {
            let formattedPrice  = NSDecimalNumber(string: price.stringValue)
            branchUniversalObject.contentMetadata.price             = formattedPrice == notanumber ? 0 : formattedPrice
        }
        
        let currencySelected: BNCCurrency = BNCCurrency(rawValue: Utils.shared.currencyNames[currencyName.indexOfSelectedItem])
        branchUniversalObject.contentMetadata.currency          = currencySelected
        
        branchUniversalObject.contentMetadata.sku               = sku.stringValue
        branchUniversalObject.contentMetadata.productName       = productName.stringValue
        branchUniversalObject.contentMetadata.productBrand      = productBrand.stringValue
        
        let productCategorySelected: BNCProductCategory = BNCProductCategory(rawValue: Utils.shared.productCategories[productCategory.indexOfSelectedItem])
        branchUniversalObject.contentMetadata.productCategory   = productCategorySelected
        
        branchUniversalObject.contentMetadata.productVariant    = productVariant.stringValue
        
        let conditionSelected: BranchCondition = BranchCondition(rawValue: productCondition.stringValue)
        branchUniversalObject.contentMetadata.condition         = conditionSelected
        branchUniversalObject.contentMetadata.customMetadata = [
            "custom_key1": customMetadata.stringValue,
        ]
        branchUniversalObject.contentMetadata.addressStreet = street.stringValue
        branchUniversalObject.contentMetadata.addressCity = city.stringValue
        branchUniversalObject.contentMetadata.addressRegion = region.stringValue
        branchUniversalObject.contentMetadata.addressCountry = country.stringValue
        branchUniversalObject.contentMetadata.addressPostalCode = postalCode.stringValue
        
        if latitude.stringValue.isEmpty{
            branchUniversalObject.contentMetadata.latitude = 0.0
        } else {
            branchUniversalObject.contentMetadata.latitude = Double(latitude.stringValue ) ?? 0.0
        }
        if latitude.stringValue.isEmpty{
            branchUniversalObject.contentMetadata.longitude = 0.0
        } else {
            branchUniversalObject.contentMetadata.longitude = Double(longitude.stringValue ) ?? 0.0
        }
        if averageRating.stringValue.isEmpty{
            branchUniversalObject.contentMetadata.ratingAverage = 0.0
        } else {
            branchUniversalObject.contentMetadata.ratingAverage = Double(averageRating.stringValue ) ?? 0.0
        }
        if maximumRating.stringValue.isEmpty{
            branchUniversalObject.contentMetadata.ratingMax = 0.0
        } else {
            branchUniversalObject.contentMetadata.ratingMax = Double(maximumRating.stringValue ) ?? 0.0
        }
        if ratingCount.stringValue.isEmpty{
            branchUniversalObject.contentMetadata.ratingCount =  0
        } else {
            branchUniversalObject.contentMetadata.ratingCount = Int(ratingCount.stringValue ) ?? 0
        }
        if ratingCount.stringValue.isEmpty{
            branchUniversalObject.contentMetadata.rating = 0.0
        } else {
            branchUniversalObject.contentMetadata.rating = Double(rating.stringValue ) ?? 0.0
        }
        
        branchUniversalObject.contentMetadata.imageCaptions = [imageCaption.stringValue ]
        
        self.dismiss(self)
        
    }
    
}

