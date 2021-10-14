//
//  InssagramApp.swift
//  Inssagram
//
//  Copyright (c) 2021 Changbeom Ahn
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import SwiftUI
import nodejs_ios
import NodeBridge

@main
struct InssagramApp: App {
    @StateObject var instagram = AppModel()
    
    @State var showLogin = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .sheet(isPresented: $showLogin) {
                    LoginView()
                }
                .environmentObject(instagram)
                .onAppear {
                    guard !unitTesting else { return }
        
                    Addon.ready = login
                }
        }
    }
    
    let nodeQueue = DispatchQueue(label: "nodejs")
    
    init() {
        print(#function, Date())
        let bundle = unitTesting ? Bundle(for: TimelineViewController.self) : Bundle.main
        let srcPath = bundle.path(forResource: "nodejs-project/main.js", ofType: "")
        nodeQueue.async {
            NodeRunner.startEngine(arguments: [
                "node",
                srcPath!,
            ])
        }
    }
    
    func login() {
        print(#function, Date())
        let query: [CFString: Any] = [
            kSecClass: kSecClassInternetPassword,
            kSecAttrServer: server,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnAttributes: true,
            kSecReturnData: true,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else {
            showLogin = true
            return
        }
        guard status == errSecSuccess else { fatalError() }
        
        guard let item = item as? [CFString: Any],
              let data = item[kSecValueData] as? Data,
              let password = String(data: data, encoding: .utf8),
              let username = item[kSecAttrAccount] as? String
        else {
            fatalError()
        }
        instagram.logIn(username: username, password: password)
    }
}

var unitTesting : Bool {
    return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
}
