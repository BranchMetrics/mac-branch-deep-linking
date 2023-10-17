//
//  Utils.swift
//  DeepLinkDemo
//
//  Created by Apple on 24/05/22.
//

import Foundation

class Utils: NSObject {
    
    static let shared = Utils()
    var logFileName: String?
    var prevCommandLogFileName: String?

    let trackContentOptions = ["ADD_TO_CART", "ADD_TO_WISHLIST", "VIEW_CART", "INITIATE_PURCHASE", "ADD_PAYMENT_INFO", "PURCHASE", "SPEND_CREDITS", "SUBSCRIBE", "START_TRIAL", "CLICK_AD", "VIEW_AD", "SEARCH", "VIEW_ITEM", "VIEW_ITEMS", "RATE", "SHARE", "START_TRIAL", "CLICK_AD", "COMPLETE_REGISTRATION", "COMPLETE_TUTORIAL", "ACHIEVE_LEVEL", "UNLOCK_ACHIEVEMENT", "INVITE", "LOGIN", "RESERVE", "OPT_IN", "OPT_OUT"]

    let currencyNames = ["AED", "AFN", "ALL", "AMD", "ANG", "AOA", "ARS", "AUD", "AWG", "AZN", "BAM", "BBD", "BDT", "BGN", "BHD", "BIF", "BMD", "BND", "BOB", "BOV", "BRL", "BSD", "BTN", "BWP", "BYN", "BYR", "CAD", "CDF", "CHE", "CHF", "CHW", "CLF", "CLP", "CNY", "COP", "COU", "CRC", "CUC", "CUP", "CVE", "CZK", "DJF", "DKK", "DOP", "DZD", "EGP", "ERN", "ETB", "EUR", "FJD", "FKP", "GBP", "GEL", "GHS", "GIP", "GMD", "GNF", "GTQ", "GYD", "HKD", "HNL", "HRK", "HTG", "HUF", "IDR", "ILS", "INR", "IQD", "IRR", "ISK", "JMD", "JOD", "JPY", "KES", "KGS", "KHR", "KMF", "KPW", "KRW", "KWD", "KYD", "KZT", "LAK", "LBP", "LKR", "LRD", "LSL", "LYD", "MAD", "MDL", "MGA", "MKD", "MMK", "MNT", "MOP", "MRO", "MUR", "MVR", "MWK", "MXN", "MXV", "MYR", "MZN", "NAD", "NGN", "NIO", "NOK", "NPR", "NZD", "OMR", "PAB", "PEN", "PGK", "PHP", "PKR", "PLN", "PYG", "QAR", "RON", "RSD", "RUB", "RWF", "SAR", "SBD", "SCR", "SDG", "SEK", "SGD", "SHP", "SLL", "SOS", "SRD", "SSP", "STD", "SYP", "SZL", "THB", "TJS", "TMT", "TND", "TOP", "TRY", "TTD", "TWD", "TZS", "UAH", "UGX", "USD", "USN", "UYI", "UYU", "UZS", "VEF", "VND", "VUV", "WST", "XAF", "XAG", "XAU", "XBA", "XBB", "XBC", "XBD", "XCD", "XDR", "XFU", "XOF", "XPD", "XPF", "XPT", "XSU", "XTS", "XUA", "XXX", "YER", "ZAR", "ZMW"]

    let contentSchemaNames  = ["COMMERCE_AUCTION", "COMMERCE_BUSINESS", "COMMERCE_OTHER",
                                       "COMMERCE_PRODUCT", "COMMERCE_RESTAURANT", "COMMERCE_SERVICE",
                                       "COMMERCE_TRAVEL_FLIGHT", "COMMERCE_TRAVEL_HOTEL", "COMMERCE_TRAVEL_OTHER",
                                       "GAME_STATE", "MEDIA_IMAGE", "MEDIA_MIXED", "MEDIA_MUSIC", "MEDIA_OTHER",
                                       "MEDIA_VIDEO", "OTHER", "TEXT_ARTICLE", "TEXT_BLOG", "TEXT_OTHER",
                                       "TEXT_RECIPE", "TEXT_REVIEW", "TEXT_SEARCH_RESULTS", "TEXT_STORY",
                                       "TEXT_TECHNICAL_DOC"]
    
    let productCategories = ["Animals & Pet Supplies", "Apparel & Accessories", "Arts & Entertainment",
                                     "Baby & Toddler", "Business & Industrial", "Cameras & Optics",
                                     "Electronics", "Food, Beverages & Tobacco", "Furniture", "Hardware",
                                     "Health & Beauty", "Home & Garden", "Luggage & Bags", "Mature",
                                     "Media", "Media", "Office Supplies", "Religious & Ceremonial",
                                     "Software", "Sporting Goods", "Toys & Games", "Vehicles & Parts"]
    
    let productConditions = ["OTHER","EXCELLENT", "NEW", "GOOD", "FAIR", "POOR", "USED", "REFURBISHED"]
    
    

    func clearAllLogFiles(){
        
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles)
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch  {
            NSLog("Failed to delete the file %@", error.localizedDescription)
        }

    }

        
    func removeItem(_ relativeFilePath: String) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let absoluteFilePath = documentsDirectory.appendingPathComponent(relativeFilePath)
        try? FileManager.default.removeItem(at: absoluteFilePath)
    }
    
    func setLogFile(_ fileName: String?) {
        if fileName == nil {
            logFileName = nil
            return
        }
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).map(\.path)[0]
        let pathForLog = "\(documentsDirectory)/\(fileName ?? "app").log"
        self.removeItem(pathForLog)
        if (logFileName == nil) {
            logFileName = pathForLog
            prevCommandLogFileName = logFileName
        } else {
            prevCommandLogFileName = logFileName
            logFileName = pathForLog
        }
        let cstr = (pathForLog as NSString).utf8String
        freopen(cstr, "a+", stderr)

    }
}


extension Dictionary {
    var jsonStringRepresentation: String? {
        guard let theJSONData = try? JSONSerialization.data(withJSONObject: self,
                                                            options: [.prettyPrinted]) else {
            return nil
        }

        return String(data: theJSONData, encoding: .ascii)
    }
}
