//
//  TextPosition.swift
//  TextInput
//
//  Created by Ziqiao Chen on 9/10/20.
//

import UIKit

class TextPosition: UITextPosition, Comparable {
    let value: Int
    
    init(value: Int) {
        self.value = value
    }
    
    init(position: TextPosition, offset: Int){
        value = position.value + offset
    }
    
    override var description: String {
        return "\(value)"
    }

    static func <(lhs: TextPosition, rhs: TextPosition) -> Bool {
        return lhs.value < rhs.value
    }
}

/*
 Conform TextPosition to NSTextLocation so we can translate between
 UITextInput and NSTextLocation (which TextKit2 uses).
 */
extension TextPosition: NSTextLocation {
    func compare(_ location: NSTextLocation) -> ComparisonResult {
        guard let to = location as? TextPosition else { fatalError() }
        let from = self
        if from.value < to.value {
            return .orderedAscending
        } else if from.value > to.value {
            return .orderedDescending
        }
        return .orderedSame
    }
}
