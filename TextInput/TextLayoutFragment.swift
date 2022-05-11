//
//  TextLayoutFragment.swift
//  TextInput
//
//  Created by Leo Tumwattana on 7/5/2022.
//

import UIKit

final class TextLayoutFragment: NSTextLayoutFragment {
    
    // ==================
    // MARK: - Properties
    // ==================
    
    override var topMargin: CGFloat { 8 }
    override var bottomMargin: CGFloat { 8 }
    override var leadingPadding: CGFloat { 20 }
    
    // ===============
    // MARK: - Drawing
    // ===============
    
    override func draw(at point: CGPoint, in context: CGContext) {
        super.draw(at: point, in: context)
    }
}
