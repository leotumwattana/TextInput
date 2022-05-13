//
//  UITextLayoutDirection+Extensions.swift
//  TextInput
//
//  Created by Leo Tumwattana on 13/5/2022.
//

import UIKit

extension UITextLayoutDirection: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .right:
            return "right"
        case .left:
            return "left"
        case .up:
            return "up"
        case .down:
            return "down"
        @unknown default:
            return "Unknown"
        }
    }
}
