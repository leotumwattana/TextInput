//
//  RenderingSurface.swift
//  TextInput
//
//  Created by Leo Tumwattana on 11/5/2022.
//

import UIKit

protocol RenderingSurface {
    var shouldRemove: Bool { get set }
    func remove()
}

extension RenderingSurface where Self: CALayer {
    func remove() {
        removeFromSuperlayer()
    }
}

extension RenderingSurface where Self: UIView {
    func remove() {
        removeFromSuperview()
    }
}
