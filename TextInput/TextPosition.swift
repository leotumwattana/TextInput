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
