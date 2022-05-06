//
//  TextInputView+TextViewportLayoutControllerDelegate.swift
//  TextInput
//
//  Created by Leo Tumwattana on 5/5/2022.
//

import UIKit

extension TextInputView: NSTextViewportLayoutControllerDelegate {
    
    /// The amount of overscroll to add to the bottom of the text view.
    var overscrollBottom: CGFloat { 80 }
    
    func viewportBounds(
        for textViewportLayoutController: NSTextViewportLayoutController
    ) -> CGRect {
        let visibleRect = CGRect(origin: contentOffset, size: visibleSize)
        
        // We're adding an additional 100 pts above and below the text view
        return visibleRect.insetBy(dx: 0, dy: -100)
    }
    
    func textViewportLayoutController(
        _ textViewportLayoutController: NSTextViewportLayoutController,
        configureRenderingSurfaceFor textLayoutFragment: NSTextLayoutFragment
    ) {
        if let fragmentLayer = fragmentLayerMap.object(forKey: textLayoutFragment) as? TextLayoutFragmentLayer {
            let oldFrame = fragmentLayer.frame
            fragmentLayer.updateGeometry()
            if oldFrame != fragmentLayer.frame {
                fragmentLayer.setNeedsDisplay()
            }
            contentLayer.addSublayer(fragmentLayer)
        } else {
            let fragmentLayer = TextLayoutFragmentLayer(layoutFragment: textLayoutFragment)
            contentLayer.addSublayer(fragmentLayer)
            fragmentLayerMap.setObject(fragmentLayer, forKey: textLayoutFragment)
        }
    }
    
    func textViewportLayoutControllerWillLayout(
        _ textViewportLayoutController: NSTextViewportLayoutController
    ) {
        contentLayer.sublayers = nil
        CATransaction.begin()
    }
    
    func textViewportLayoutControllerDidLayout(
        _ textViewportLayoutController: NSTextViewportLayoutController
    ) {
        CATransaction.commit()
        updateContentSizeIfNeeded()
        adjustViewportOffsetIfNeeded()
    }
    
    func updateContentSizeIfNeeded() {
        let currentHeight = bounds.height
        var height: CGFloat = 0
        
        textLayoutManager.enumerateTextLayoutFragments(
            from: textLayoutManager.documentRange.endLocation,
            options: [.reverse, .ensuresLayout]
        ) {  layoutFragment in
            height = layoutFragment.layoutFragmentFrame.maxY
            return false
        }
        
        height += overscrollBottom
        
        if abs(currentHeight - height) > 1e-10 {
            contentSize = CGSize(width: bounds.width, height: height)
        }
    }
    
    private func adjustViewportOffsetIfNeeded() {
        let viewportLayoutController = textLayoutManager.textViewportLayoutController
        let contentOffset = bounds.minY
        let order = viewportLayoutController.viewportRange!.location
            .compare(textLayoutManager.documentRange.location)
        
        if contentOffset < bounds.height && order == .orderedDescending {
            // Nearing top, see if we need to adjust and make room above
            adjustViewportOffset()
        } else if order == .orderedSame {
            // At top, see if we need to adjust and reduce space above.
            adjustViewportOffset()
        }
    }
    
    private func adjustViewportOffset() {
        let viewportLayoutController = textLayoutManager.textViewportLayoutController
        var layoutYPoint: CGFloat = 0
        textLayoutManager.enumerateTextLayoutFragments(
            from: viewportLayoutController.viewportRange!.location,
            options: [.reverse, .ensuresLayout]
        ) { layoutFragment in
            layoutYPoint = layoutFragment.layoutFragmentFrame.origin.y
            return true
        }
        
        if layoutYPoint != 0 {
            let adjustmentDelta = bounds.minY - layoutYPoint
            viewportLayoutController.adjustViewport(byVerticalOffset: adjustmentDelta)
            let point = CGPoint(
                x: contentOffset.x,
                y: contentOffset.y + adjustmentDelta
            )
            setContentOffset(point, animated: true)
        }
    }
}
