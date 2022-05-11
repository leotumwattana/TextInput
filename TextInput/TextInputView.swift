//
//  TextInputView.swift
//  TextInput
//
//  Created by Ziqiao Chen on 9/10/20.
//

import UIKit

class TextInputView: UIScrollView {

    // MARK: UITextInput properties
    //
    var inputDelegate: UITextInputDelegate?
    
    var selectedTextRange: UITextRange? {
        willSet(newSelectedTextRange) {
            print("\(#function): current = \(String(describing: selectedTextRange))")
            print("\(#function): new = \(String(describing: newSelectedTextRange))")
            inputDelegate?.selectionWillChange(self)
        }
        didSet {
            inputDelegate?.selectionDidChange(self)
        }
    }
    
    var markedTextRange: UITextRange?
    var markedTextStyle: [NSAttributedString.Key : Any]?
    lazy var tokenizer: UITextInputTokenizer = {
        return UITextInputStringTokenizer(textInput: self)
    }()

    // MARK: TextKit2 stack
    //
    let textContentStorage = NSTextContentStorage()
    let textLayoutManager = NSTextLayoutManager()
    let textContainer = NSTextContainer(size: .zero)
    
    private(set) var contentLayer: CALayer = TextLayer()
    var fragmentRenderingSurfaceMap: NSMapTable<NSTextLayoutFragment, AnyObject>
    
    // MARK: Floating Cursor
    //
    let floatingCursorView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 1
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 3
        view.isUserInteractionEnabled = false
        return view
    }()
    
    internal var _caretRectForFloatingCursor: CGRect?
    
    // MARK: initializer
    //
    override init(frame: CGRect) {
        markedTextStyle = [NSAttributedString.Key.backgroundColor: UIColor.lightGray]

        // Test data
        let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)]
        let string = NSAttributedString(string: "1234567890", attributes: attributes)
        
        fragmentRenderingSurfaceMap = .weakToWeakObjects()
        super.init(frame: frame)
        
        textContentStorage.performEditingTransaction {
            textContentStorage.textStorage?.insert(string, at: 0)
        }
        
        layer.addSublayer(contentLayer)
        
        textContentStorage.delegate = self
        textContentStorage.textStorage?.delegate = self
        textContentStorage.addTextLayoutManager(textLayoutManager)
        
        textLayoutManager.delegate = self
        textLayoutManager.textViewportLayoutController.delegate = self
        
        textContainer.widthTracksTextView = true
        textLayoutManager.textContainer = textContainer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Overridables
    //
    override var canBecomeFirstResponder: Bool {
        return true
    }

    override var canResignFirstResponder: Bool {
        return true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateTextContainerSize()
        textLayoutManager
            .textViewportLayoutController
            .layoutViewport()
        updateContentSizeIfNeeded()
    }

    private func updateTextContainerSize() {
        guard let textContainer = textLayoutManager.textContainer,
              textContainer.size.width != bounds.width
        else { return }
        textContainer.size = CGSize(width: bounds.size.width, height: 0)
        layer.setNeedsLayout()
    }
}
