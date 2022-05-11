//
//  CheckboxView.swift
//  TextInput
//
//  Created by Leo Tumwattana on 10/5/2022.
//

import UIKit

final class CheckboxView: UIView {
    
    // =============
    // MARK: - Enums
    // =============
    
    enum State {
        case checked
        case unchecked
        case mixed
        case cancelled
    }
    
    // ==================
    // MARK: - Properties
    // ==================
    
    private(set) lazy var shapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        return shapeLayer
    }()
    
    var cornerRadius: CGFloat = 6 {
        didSet {
            shapeLayer.cornerRadius = cornerRadius
        }
    }
    
    var state: State = .unchecked {
        didSet {
            previousState = oldValue
            setNeedsLayout()
        }
    }
    
    var previousState: State = .unchecked
    
    let tap = UITapGestureRecognizer()
    let longPress = UILongPressGestureRecognizer()
    
    // ============
    // MARK: - Init
    // ============
    
    init() {
        super.init(frame: .zero)
        
        layer.addSublayer(shapeLayer)
        shapeLayer.allowsEdgeAntialiasing = true
        shapeLayer.isOpaque = true
        shapeLayer.lineWidth = 3
        shapeLayer.borderWidth = 1.5
        shapeLayer.cornerRadius = cornerRadius
        shapeLayer.cornerCurve = .continuous
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .round
        
        set(state: state, animated: false)
        
        // Setup tap gesture
        tap.addTarget(self, action: #selector(tapped(_:)))
        addGestureRecognizer(tap)
        
        // Setup longPress gesture
        longPress.addTarget(self, action: #selector(longPressed(_:)))
        addGestureRecognizer(longPress)
        
        // Allow longPress to take precedent over tap.
        tap.shouldRequireFailure(of: longPress)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // ==============
    // MARK: - Layout
    // ==============
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = bounds
        shapeLayer.path = path(for: state)
    }
    
    // ======================
    // MARK: - Event Handlers
    // ======================
    
    @objc func tapped(_ tap: UITapGestureRecognizer) {
        switch state {
        case .checked:
            set(state: .unchecked, animated: true)
        case .unchecked:
            set(state: .checked, animated: true)
        case .mixed:
            set(state: .checked, animated: true)
        case .cancelled:
            set(state: .unchecked, animated: true)
        }
    }
    
    @objc func longPressed(_ longPress: UILongPressGestureRecognizer) {
        guard longPress.state == .began else { return }
        switch state {
        case .checked:
            set(state: .cancelled, animated: true)
        case .unchecked:
            set(state: .cancelled, animated: true)
        case .mixed:
            set(state: .cancelled, animated: true)
        case .cancelled:
            set(state: .unchecked, animated: true)
        }
    }
    
    private func set(state: State, animated: Bool) {
        self.state = state
        
        if animated {
            update(state: state)
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            update(state: state)
            CATransaction.commit()
        }
    }
    
    private func update(state: State) {
        shapeLayer.path = path(for: state)
        shapeLayer.strokeEnd = strokeEnd(for: state)
        shapeLayer.borderWidth = borderWidth(for: state)
        shapeLayer.borderColor = borderColor(for: state).cgColor
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.backgroundColor = backgroundColor(for: state).cgColor
    }
    
//    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        let result = super.hitTest(point, with: event)
//        print("*** \(#function): lolo: \(result) point: \(point)")
//        print("*** \(#function): gestureRecognizers: \(gestureRecognizers.map { $0 })")
//        return result
//    }
    
    // =============
    // MARK: - Paths
    // =============
    
    private func path(for state: State) -> CGPath {
        switch state {
        case .checked:
            return checkedPath(for: bounds)
        case .unchecked:
            switch previousState {
            case .checked, .unchecked:
                return checkedPath(for: bounds)
            case .mixed:
                return dashPath(for: bounds)
            case .cancelled:
                return crossPath(for: bounds)
            }
        case .cancelled:
            return crossPath(for: bounds)
        case .mixed:
            return dashPath(for: bounds)
        }
    }
    
    // ===============
    // MARK: - Helpers
    // ===============
    
    private func strokeEnd(for state: State) -> CGFloat {
        switch state {
        case .unchecked:
            return 0
        case .checked, .mixed, .cancelled:
            return 1
        }
    }
    
    private func backgroundColor(for state: State) -> UIColor {
        switch state {
        case .unchecked:
            return .clear
        case .checked, .cancelled, .mixed:
            return .systemBlue
        }
    }
    
    private func borderColor(for state: State) -> UIColor {
        switch state {
        case .unchecked:
            return .systemGray
        case .checked, .cancelled, .mixed:
            return .systemBlue
        }
    }
    
    private func borderWidth(for state: State) -> CGFloat {
        switch state {
        case .unchecked:
            return 3
        case .checked, .cancelled, .mixed:
            return 0
        }
    }
    
    private func checkedPath(for bounds: CGRect) -> CGPath {
        // TODO: Make values not hard coded
        let inset: CGFloat = 5
        let path = UIBezierPath()
        path.move(to: CGPoint(x: bounds.minX + inset, y: bounds.height * 0.55))
        path.addLine(to: CGPoint(x: bounds.width * 0.47, y: bounds.maxY - inset))
        path.addLine(to: CGPoint(x: bounds.maxX - inset, y: bounds.minY + inset))
        return path.cgPath
    }
    
    private func crossPath(for bounds: CGRect) -> CGPath {
        let inset: CGFloat = 4
        let path = UIBezierPath()
        let width = bounds.width
        path.move(to: CGPoint(x: inset, y: inset))
        path.addLine(to: CGPoint(x: width - inset, y: width - inset))
        path.move(to: CGPoint(x: inset, y: width - inset))
        path.addLine(to: CGPoint(x: width - inset, y: inset))
        return path.cgPath
    }
    
    func dashPath(for bounds: CGRect) -> CGPath {
        let path = UIBezierPath()
        let inset: CGFloat = 4
        let y = bounds.height / 2
        let start = CGPoint(x: inset, y: y)
        let end = CGPoint(x: bounds.width - inset, y: y)
        path.move(to: start)
        path.addLine(to: end)
        return path.cgPath
    }
}
