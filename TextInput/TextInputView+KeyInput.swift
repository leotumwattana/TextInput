//
//  TextInputView+KeyInput.swift
//  TextInput
//
//  Created by Ziqiao Chen on 9/11/20.
//

import UIKit

extension TextInputView: UIKeyInput {
    
    private var typingAttributes: [NSAttributedString.Key : Any] {
        let font = UIFont.boldSystemFont(ofSize: 24)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        
        let attributes = [NSAttributedString.Key.font: font,
                          NSAttributedString.Key.foregroundColor: UIColor.label,
                          NSAttributedString.Key.paragraphStyle: paragraphStyle]
        return attributes
    }
    
    var hasText: Bool {
        return textContentStorage.textStorage?.string.isEmpty ?? true
    }
    
    func insertText(_ text: String) {
        print("\(#function)")
        guard let textStorage = textContentStorage.textStorage,
            let rangeToReplace = (markedTextRange ?? selectedTextRange) as? TextRange,
            let nsRangeToReplace = rangeToReplace.nsRange(in: textStorage.string)
        else { return }
        
        let attributedText = NSAttributedString(string: text, attributes: typingAttributes)
        inputDelegate?.textWillChange(self)
        textContentStorage.performEditingTransaction {
            textStorage.replaceCharacters(in: nsRangeToReplace, with: attributedText)
        }
        markedTextRange = nil
        let newCursorPosition = TextPosition(position: rangeToReplace.start, offset: text.count)
        selectedTextRange = TextRange(start: newCursorPosition, end: newCursorPosition)
        inputDelegate?.textDidChange(self)
        setNeedsDisplay()
    }
    
    func deleteBackward() {
        print("\(#function)")
        guard let textStorage = textContentStorage.textStorage,
            textStorage.string.count > 0 else { return }

        guard let rangeToReplace = (markedTextRange ?? selectedTextRange) as? TextRange,
            let nsRangeToRepalce = rangeToReplace.nsRange(in: textStorage.string) else {
            return
        }
        inputDelegate?.textWillChange(self)
        textContentStorage.performEditingTransaction {
            textStorage.deleteCharacters(in: nsRangeToRepalce)
        }
        markedTextRange = nil //?? Support the case of deleting a character of the marked text?
        selectedTextRange = TextRange(start: rangeToReplace.start, end: rangeToReplace.start)
        inputDelegate?.textDidChange(self)
        setNeedsDisplay()
    }
}
