//
//  TextInputView.swift
//  TextInput
//
//  Created by Ziqiao Chen on 9/10/20.
//

import UIKit

class TextInputView: UIView {

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

    // MARK: TextKit stack
    //
    let textStorage = NSTextStorage()
    let layoutManager = NSLayoutManager()
    let textContainer: NSTextContainer
    
    // MARK: initializer
    //
    override init(frame: CGRect) {
        textStorage.addLayoutManager(layoutManager)
        textContainer = NSTextContainer(size: frame.size)
        layoutManager.addTextContainer(textContainer)
        markedTextStyle = [NSAttributedString.Key.backgroundColor: UIColor.lightGray]

        // Test data
        let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)]
        let string = NSAttributedString(string: "1234567890", attributes: attributes)
        textStorage.append(string)
        //End
        
        super.init(frame: frame)
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
        textContainer.size = frame.size
    }

    // MARK: Drawing the text
    //
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        print("\(#function)")

        let glyphRange = layoutManager.glyphRange(for: textContainer)
        layoutManager.drawBackground(forGlyphRange: glyphRange, at: .zero)
        layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: .zero)
    }
}
