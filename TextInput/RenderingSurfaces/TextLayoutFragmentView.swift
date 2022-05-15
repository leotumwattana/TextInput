//
//  TextLayoutFragmentView.swift
//  TextInput
//
//  Created by Leo Tumwattana on 10/5/2022.
//

import UIKit

final class TextLayoutFragmentView: UIView, RenderingSurface {
    
    // ==================
    // MARK: - Properties
    // ==================
    
    var shouldRemove: Bool = false
    
    var layoutFragment: NSTextLayoutFragment
    
    var isChecked: Bool = false
    
    private(set) lazy var checkboxView: CheckboxView = {
        let view = CheckboxView()
        return view
    }()
    
    // ============
    // MARK: - Init
    // ============
    
    init(layoutFragment: NSTextLayoutFragment) {
        self.layoutFragment = layoutFragment
        super.init(frame: .zero)
        contentScaleFactor = 2
        backgroundColor = .clear
        updateGeometry()
        addSubview(checkboxView)
        setNeedsDisplay()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // ============
    // MARK: - Draw
    // ============
    
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        backgroundColor = .clear
        ctx.clear(rect)
        layoutFragment.draw(at: .zero, in: ctx)
    }
    
    // ==============
    // MARK: - Layout
    // ==============
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutCheckbox()
        
    }
    
    private func layoutCheckbox() {
        guard let firstBounds = layoutFragment
            .textLineFragments
            .first?
            .typographicBounds
        else { return }
        
        let dimension: CGFloat = 20
        checkboxView.frame = CGRect(
            x: 0,
            y: firstBounds.midY - (dimension / 2),
            width: dimension,
            height: dimension
        )
    }
    
    func updateGeometry() {
        bounds = layoutFragment.renderingSurfaceBounds
        layer.anchorPoint = CGPoint(
            x: -bounds.origin.x / bounds.size.width,
            y: -bounds.origin.y / bounds.size.height
        )
        layer.position = layoutFragment.layoutFragmentFrame.origin
    }
    
    // ===============
    // MARK: - HitTest
    // ===============
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if checkboxView.frame.insetBy(dx: -8, dy: -8).contains(point) {
            return checkboxView
        }
        return nil
    }
}
