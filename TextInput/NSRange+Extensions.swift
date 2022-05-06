//
//  NSRange+Extensions.swift
//  TextInput
//
//  Created by Leo Tumwattana on 6/5/2022.
//

import Foundation

extension NSRange {
    func offset(_ delta: Int) -> Self {
        NSRange(location: location + delta, length: length)
    }
}
