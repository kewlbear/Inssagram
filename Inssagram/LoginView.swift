//
//  LoginView.swift
//  inSJagram
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

import Foundation
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var instagram: AppModel
    
    @Environment(\.presentationMode) var presentationMode
    
    @State var username = ""
        
    @State var password = ""
    
    @State var showError = false
    
    @State var sentUsername = ""
    
    var body: some View {
        Form {
            Section {
                TextField("username", text: $username)
            }
            
            Section {
                SecureField("password", text: $password)
            }
            
            Button {
                sentUsername = username
                
                instagram.logIn(username: username, password: password)
            } label: {
                if instagram.isLoggingIn {
                    ProgressView()
                } else {
                    Text("Log In")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .onReceive(instagram.$user) { user in
            print(user ?? "no user")
            guard user?.username == sentUsername else { return }
            
            saveCredentials()
            
            presentationMode.wrappedValue.dismiss()
        }
        .alert(item: $instagram.error) { error in
            Alert(title: Text("Error"), message: Text(error), dismissButton: nil)
        }
        .disabled(instagram.isLoggingIn)
    }
    
    func saveCredentials() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassInternetPassword,
            kSecAttrAccount: username,
            kSecAttrServer: server,
            kSecValueData: password.data(using: .utf8)!,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            let query: [CFString: Any] = [
                kSecClass: kSecClassInternetPassword,
                kSecAttrAccount: username,
                kSecAttrServer: server,
            ]
            let attributes: [CFString: Any] = [
                kSecValueData: password.data(using: .utf8)!,
            ]
            let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            guard status == errSecSuccess else { fatalError() }
            return
        }
        
        guard status == errSecSuccess else { fatalError() }
    }
}

extension String: Identifiable {
    public var id: String { self }
}

//struct LoginView_Preview: PreviewProvider {
//    static var previews: some View {
//        LoginView()
//    }
//}
