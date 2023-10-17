//
//  WebviewVC.swift
//  SaaS_SDK_TestBed_MacOS
//
//  Created by apple on 21/07/22.
//

import Cocoa
import WebKit

class WebviewVC: NSViewController {

    var webView: WKWebView!

    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView (frame: CGRect(x:0, y:0, width:800, height:600), configuration:webConfiguration)
        webView.uiDelegate = self
        view = webView;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        webView.navigationDelegate = self
        if let deeplinkurl: String = UserDefaults.standard.string(forKey: "link"){
            webView.load(URLRequest(url: URL(string: deeplinkurl)!))
        }

    }
    
}

extension WebviewVC: WKUIDelegate, WKNavigationDelegate{
    func webViewDidClose(_ webView: WKWebView) {
        NSLog(#function)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        NSLog(#function)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog(#function)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        NSLog(#function)
    }
}
