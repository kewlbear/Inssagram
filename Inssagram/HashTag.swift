//
//  HashTag.swift
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

extension String {
    func hashTagRanges() -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        let text = self
        var remain = text.startIndex..<text.endIndex
        let delimiters = CharacterSet(charactersIn: "#").union(.whitespacesAndNewlines)
        while let range = text.range(of: "#", range: remain) {
            let endIndex = text.rangeOfCharacter(from: delimiters, range: range.upperBound..<text.endIndex)?.lowerBound
            ?? text.endIndex
            ranges.append(range.lowerBound..<endIndex)
            guard endIndex < text.endIndex else { break }
            remain = endIndex..<text.endIndex
        }
        return ranges
    }
}
