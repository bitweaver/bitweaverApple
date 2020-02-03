//
//  BitweaverWebViewController.swift
//  PrestoPhoto
//
//  Created by Caleb Mitcler on 2/3/20.
//  Copyright © 2020 PrestoPhoto. All rights reserved.
//

import Foundation
import Cocoa
import WebKit

class BitweaverWebViewController: BWViewController, WKUIDelegate, WKNavigationDelegate {

    var webView: WKWebView  = WKWebView()

    var defaultUrl: URL?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func loadView() {
        super.loadView()
        webView.frame = self.view.bounds
        webView.autoresizingMask = [.width, .height]
        webView.allowsBackForwardNavigationGestures = true
        webView.uiDelegate = self
        webView.navigationDelegate = self

        self.view.addSubview( webView )
    }

    override func viewWillAppear() {
        super.viewWillAppear()
    }

    func loadUrl( url: URL ) {
        var urlRequest = URLRequest(url: url)
        if #available(OSX 10.13, *) {
        } else {
            let cookies = HTTPCookie.requestHeaderFields(with: BitweaverUser.active.cookieArray)

            var headers = urlRequest.allHTTPHeaderFields ?? [:]
            headers.merge( cookies, uniquingKeysWith: { (current, _) in current })

            urlRequest.allHTTPHeaderFields = headers
        }

        webView.loadHTMLString("<html><body><p>Loading page...</p></body></html>", baseURL: nil)
        webView.load(urlRequest)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            //            guard let urlPath =  navigationAction.request.url?.pathComponents else { decisionHandler(.allow); return }
            //            if (urlPath.count) > 1 && urlPath[1] == "help" {
            guard let targetHost = navigationAction.request.url?.host else { decisionHandler(.allow); return }
            if targetHost != PrestoDefaults.uriHost && targetHost != "support.photobooks.pro" {
                if NSWorkspace.shared.open( navigationAction.request.url! ) {
                    decisionHandler(.cancel)
                } else {
                    decisionHandler(.allow)
                }
            } else {
                decisionHandler(.allow)
            }
        } else {
            decisionHandler(.allow)
        }
    }
}
