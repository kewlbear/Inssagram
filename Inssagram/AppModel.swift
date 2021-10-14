//
//  AppModel.swift
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

import Foundation
import InstagramPrivateAPI
import SwiftUI
import NodeBridge
import NodeDecoder
import node_api

let scheme = "inssagram"

let server = "www.instagram.com"

class AppModel: ObservableObject {
    @Published var posts: [Post] = []
    
    @Published var filtered: [Post] = []
    
    var postCount: Int { posts.count }
    
    @Published var expandedPosts = Set<String>()
    
    @AppStorage("hiddenHashtags") var hiddenHashtags: String? {
        didSet { updateHiddenHashtagSet() }
    }
    
    @Published var hiddenHashtagSet = Set<String>()
    
    var hiddenHashtagsRevision = 0
    
    @Published var error: String?
    
    @Published var user: User?
    
    @Published var isLoggingIn = false
    
    var isCalling = false
    
    init() {
        guard !unitTesting else { return }
        
        Addon.handler = { env, value in
            self.isCalling = false
            
            print(#function, Date())
            do {
//                print(Value(env: env, value: value).description)
                let info = try NodeDecoder(env: env).decode(CallBackInfo.self, from: value)
                DispatchQueue.main.async {
                    if info.type == "login" {
                        self.isLoggingIn = false
                    }
                    
                    guard info.error == nil else {
                        self.error = info.error?.text
                        return
                    }
                    
                    switch info.type {
                    case "login":
                        self.user = info.login
                        
                        self.callJS(dict: ["type": "timeline"])
                    case "timeline", "loadNext":
                        self.posts += info.timeline ?? info.loadNext ?? []
                    default:
                        fatalError()
                    }
                }
            } catch {
                var result: napi_value?
                napi_get_and_clear_last_exception(env, &result)
                print(Value(env: env, value: value))
                print(error)
            }
        }
        
        updateHiddenHashtagSet()
        
        $posts.combineLatest($hiddenHashtagSet)
            .map { (posts, hashtags) in
                posts.filter { post in
                    guard let caption = post.caption?.text else { return true }
                    let tags = Set(caption.hashTagRanges().map { range in
                        String(caption[range].dropFirst())
                    })
                    return tags.intersection(hashtags).isEmpty
                }
            }.assign(to: &$filtered)
    }
    
    func updateHiddenHashtagSet() {
        hiddenHashtagsRevision += 1
        
        hiddenHashtagSet = Set(hiddenHashtags?.components(separatedBy: "#") ?? [])
    }
    
    func logIn(username: String, password: String) {
        print(#function, Date())
        DispatchQueue.main.async {
            self.isLoggingIn = true
        }
        
        callJS(dict: [
            "type": "login",
            "username": username,
            "password": password,
        ])
    }
    
    func loadNext() {
        print(#function, Date())
        callJS(dict: ["type": "loadNext"])
    }
    
    func callJS(dict: [String: String]) {
        guard !isCalling else {
            print("nested callJS")
            return
        }
        isCalling = true
        
        Addon.callJS(dict: dict)
    }
}

protocol Media {
    var aspectRatio: CGFloat { get }
    
    var type: MediaType? { get }
    
    var url: URL { get }
}

extension Post: Media {
    var aspectRatio: CGFloat {
        CGFloat(original_width!) / CGFloat(original_height!)
    }
    
    var type: MediaType? {
        mediaType
    }
    
    var url: URL {
        URL(string: video_versions?.first?.url ?? image_versions2!.candidates[0].url)!
    }
}
            
extension CarouselMedia: Media {
    var aspectRatio: CGFloat {
        CGFloat(original_width) / CGFloat(original_height)
    }
    
    var type: MediaType? {
        mediaType
    }
    
    var url: URL {
        URL(string: video_versions?.first?.url ?? image_versions2!.candidates[0].url)!
    }
}
