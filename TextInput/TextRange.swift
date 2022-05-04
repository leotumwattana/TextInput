//
//  TextRange.swift
//  TextInput
//
//  Created by Ziqiao Chen on 9/10/20.
//

import UIKit

// To match Swift.Range, TextRange is defined as:
// A half-open interval from a lower bound up to, but not including, an upper bound.
//
class TextRange: UITextRange {
    private let startPosition: TextPosition
    private let endPosition: TextPosition
    
    init(start: TextPosition, end: TextPosition) {
        startPosition = start
        endPosition = end
    }
   
    override var start: TextPosition {
        return startPosition
    }

    override var end: TextPosition {
        return endPosition
    }
    
    override var isEmpty: Bool {
        startPosition.value >= endPosition.value
    }
    
    override var description: String {
        return "[\(startPosition.value), \(endPosition.value))"
    }
    
    func range(in text: String) -> Range<String.Index>? {
        assert(start <= end, "\(#function): TextRange.start must be <= TextRange.end.")
        assert(text.count == (text as NSString).length) //DEBUG

        let startIndex = text.index(text.startIndex, offsetBy: start.value, limitedBy: text.endIndex)
        let endIndex = text.index(text.startIndex, offsetBy: end.value, limitedBy: text.endIndex)
        if let startIndex = startIndex, let endIndex = endIndex {
            return startIndex..<endIndex
        } else {
            return nil
        }
    }
    
    func nsRange(in text: String) -> NSRange? {
        if let range = range(in: text) {
            return NSRange(range, in: text)
        } else {
            return nil
        }
    }
}
