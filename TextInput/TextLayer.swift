//
//  TextLayer.swift
//  TextInput
//
//  Created by Leo Tumwattana on 5/5/2022.
//

import UIKit

class TextLayer: CALayer {
    override class func defaultAction(forKey event: String) -> CAAction? {
        // Suppress default animations.
        return NSNull()
    }
}
