//
//  TextLayoutFragmentLayer.swift
//  TextInput
//
//  Created by Leo Tumwattana on 5/5/2022.
//

import UIKit

class TextLayoutFragmentLayer: CALayer {
    
    var layoutFragment: NSTextLayoutFragment
    
    init(layoutFragment: NSTextLayoutFragment) {
        self.layoutFragment = layoutFragment
        super.init()
        contentsScale = 2
        updateGeometry()
        setNeedsDisplay()
    }
    
    override init(layer: Any) {
        let fragmentLayer = layer as! TextLayoutFragmentLayer
        layoutFragment = fragmentLayer.layoutFragment
        super.init(layer: layer)
        updateGeometry()
        setNeedsDisplay()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override class func defaultAction(forKey event: String) -> CAAction? {
        // Suppress default opacity animations.
        return NSNull()
    }
    
    override func draw(in ctx: CGContext) {
        layoutFragment.draw(at: .zero, in: ctx)
    }
    
    func updateGeometry() {
        bounds = layoutFragment.renderingSurfaceBounds
        // The (0, 0) point in layer space should be the anchor point.
        anchorPoint = CGPoint(
            x: -bounds.origin.x / bounds.size.width,
            y: -bounds.origin.y / bounds.size.height
        )
        
        position = layoutFragment.layoutFragmentFrame.origin
    }
}
