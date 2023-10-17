//  CommonMethod.swift
//  DeepLinkDemo
//  Created by Rakesh kumar on 4/18/22.


import Foundation
import Branch
import SystemConfiguration


class CommonMethod {
    
    static let sharedInstance = CommonMethod()
    var branchUniversalObject: BranchUniversalObject? = BranchUniversalObject()
    var linkProperties: BranchLinkProperties? = BranchLinkProperties()
    var contentMetaData : BranchContentMetadata? = BranchContentMetadata()
    var branchEvent : BranchEvent = BranchEvent.standardEvent(.purchase)

    var branchData = [String: AnyObject]()

    func navigatetoContent(onCompletion:@escaping (NSDictionary?) -> Void) -> Void {
        guard let data = branchData as? [String: AnyObject] else { return }
        onCompletion(data as NSDictionary)
    }
    
    func resetBranchUniversalObject(){
        self.branchUniversalObject = nil
    }
    
    func resetBranchLinkProperties(){
        self.linkProperties = nil
    }

    func resetBranchContentMetadata(){
        self.contentMetaData = nil
    }

    func isInternetAvailable() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
         }
        }

       var flags = SCNetworkReachabilityFlags()

       if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
          return false
       }
       let isReachable = flags.contains(.reachable)
       let needsConnection = flags.contains(.connectionRequired)
       return (isReachable && !needsConnection)
    }
}
