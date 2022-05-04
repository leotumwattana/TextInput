//
//  TextInputView+TextInput.swift
//  TextInput
//
//  Created by Ziqiao Chen on 9/11/20.
//

import UIKit

extension TextInputView: UITextInput {
    
    // MARK: Replacing and Returning Text
    //
    func text(in range: UITextRange) -> String? {
        guard let textRange = range as? TextRange,
            let indexRange = textRange.range(in: textStorage.string) else {
            return nil
        }
        let string = String(textStorage.string[indexRange])
        print("\(#function): range = \(range), string = \(string)")
        return string
    }
    
    func replace(_ range: UITextRange, withText text: String) {
        print("\(#function): range = \(range), with text = \(text)")
        guard let textRange = range as? TextRange,
              let nsRange = textRange.nsRange(in: textStorage.string) else {
            fatalError("\(#function): Failed to convert \(range) to a valid NSRange.")
        }

        // Replace the characters in text storage and update the selectedTextRange.
        // Notify inputDelegate before and after doing the change.
        // Note that TextRange is a half-open range without including the upper bound.
        //
        inputDelegate?.textWillChange(self)
        textStorage.replaceCharacters(in: nsRange, with: text)
        inputDelegate?.textDidChange(self)

        let newEnd = TextPosition(position: textRange.start, offset: text.count)
        selectedTextRange = TextRange(start: textRange.start, end: newEnd)
    }
        
    // MARK: Working with Marked and Selected Text
    // It seems like UITextInteraction doesn't support marked text cursor – Once markedTextRange
    // has a value, the cursor view disappears. 
    //
    func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        print("\(#function): markedText = \(String(describing: markedText)), selectedRange = \(selectedRange)")
        // If markedText is nil, use "" to clear the existing marked and selected text.
        // Clear the existing marked text, or the selected text if no marked text exists.
        //
        let rangeToReplace = markedTextRange ?? selectedTextRange

        if let rangeToReplace = rangeToReplace as? TextRange,
            let nsRange = rangeToReplace.nsRange(in: textStorage.string) {
            inputDelegate?.textWillChange(self)
            let newMarkedText = markedText ?? ""
            textStorage.replaceCharacters(in: nsRange, with: newMarkedText)

            let newEnd = TextPosition(position: rangeToReplace.start, offset: newMarkedText.count)
            markedTextRange = TextRange(start: rangeToReplace.start, end: newEnd)
            
            if let nsRange = (markedTextRange as! TextRange).nsRange(in: textStorage.string),
               let markTextStyle = self.markedTextStyle {
                textStorage.addAttributes(markTextStyle, range: nsRange)
            }
            inputDelegate?.textDidChange(self)
        }

        // Now that the marked text or selected text is replaced, update selectedTextRange
        // with the selectedRange in the marked text.
        //
        if let markedText = markedText, let markedTextSelectedRange = Range(selectedRange, in: markedText),
            let rangeToReplace = rangeToReplace as? TextRange {
            let offset = markedText.distance(from: markedText.startIndex,
                                             to: markedTextSelectedRange.lowerBound)
            let length = markedText.distance(from: markedTextSelectedRange.lowerBound,
                                             to: markedTextSelectedRange.upperBound)
            let newStart = TextPosition(position: rangeToReplace.start, offset: offset)
            let newEnd = TextPosition(position: newStart, offset: length)
            selectedTextRange = TextRange(start: newStart, end: newEnd)
        }
        
        setNeedsDisplay()
        print("\(#function): markedTextRange = \(String(describing: markedTextRange)))")
        print("\(#function): selectedTextRange = \(String(describing: selectedTextRange))")
    }
    
    func unmarkText() {
        print("\(#function) markedTextRange = \(String(describing: markedTextRange))")
        guard let markedTextRange = self.markedTextRange as? TextRange else {
            return
        }
        if let nsRange = markedTextRange.nsRange(in: textStorage.string) {
            inputDelegate?.textWillChange(self)
            markedTextStyle?.keys.forEach { key in
                textStorage.removeAttribute(key, range: nsRange)
            }
            inputDelegate?.textDidChange(self)
        }
        // Set insertion point to the end of the previously marked text,
        // then clear markedTextRange,
        //
        selectedTextRange = TextRange(start: markedTextRange.end, end: markedTextRange.end)
        self.markedTextRange = nil
        setNeedsDisplay()

        // BUG: UITextInteraction doesn't show the cursor after clearing markedTextRange,
        // so replace the existing UITextInteraction object with a new one.
        // This is most likely a bug.
        //
        guard let interaction = interactions.first else { return }
        removeInteraction(interaction)
        let newInteraction = UITextInteraction(for: .editable)
        newInteraction.textInput = self
        addInteraction(newInteraction)
    }
    
    // MARK: Computing Text Ranges and Text Positions
    //
    var beginningOfDocument: UITextPosition {
        return TextPosition(value: 0)
    }
    
    var endOfDocument: UITextPosition {
        return TextPosition(value: textStorage.string.count)
    }
    
    func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        print("\(#function): from = \(fromPosition), to = \(toPosition)")
        guard let start = fromPosition as? TextPosition,let end = toPosition as? TextPosition else {
            fatalError("\(#function): The type of `fromPosition` or `toPosition` isn't TextPosition.")
        }
        return start <= end ? TextRange(start: start, end: end) : TextRange(start: end, end: start)
    }
    
    func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        print("\(#function): from = \(position), offset = \(offset)")
        guard let position = position as? TextPosition else {
            fatalError("\(#function): The type of `position` isn't TextPosition.")
        }
        let newPosition = TextPosition(position: position, offset: offset)
        if newPosition.value >= textStorage.string.count {
            return endOfDocument
        } else if newPosition.value < 0 {
            return beginningOfDocument
        } else {
            return newPosition
        }
    }
    
    func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
        print("\(#function): from = \(position),in = \(direction), offset = \(offset)")
        guard let position = position as? TextPosition else {
            return nil
        }
        switch direction { // This sample only supports left-to-right text direction.
        case .right:
            let newPosition = TextPosition(position: position, offset: offset)
            return newPosition > endOfDocument as! TextPosition ? endOfDocument : newPosition
        case .left:
            let newPosition = TextPosition(position: position, offset: -offset)
            return newPosition < beginningOfDocument as! TextPosition ? beginningOfDocument : newPosition
        default:
            return nil
        }
    }
    
    // MARK: Evaluating Text Positions
    //
    func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        print("\(#function): position = \(position), to = \(other)")
        guard let position = position as? TextPosition, let other = other as? TextPosition else {
            fatalError("\(#function): The type of `position` or `other` isn't TextPosition.")
        }
        if position < other {
            return .orderedAscending
        } else if position > other {
            return .orderedDescending
        }
        return .orderedSame
    }
    
    func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
        print("\(#function): from = \(from), to = \(toPosition)")
        
        // See from and toPosition can be <uninitialized> for macCatalyst.
        // Return 0 in that case.
        //
        guard let from = from as? TextPosition, let toPosition = toPosition as? TextPosition else {
            print("\(#function): The type of `from` or `toPosition` isn't TextPosition.")
            return 0
        }
        return toPosition.value - from.value
    }
    
    // MARK: Text Layout, writing direction and position related methods
    // Note that this sample only supports left-to-right text direction.
    //
    func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
        print("\(#function): within range = \(range)")
        guard let range = range as? TextRange else {
            fatalError("\(#function): The type of `range` isn't TextRange.")
        }
        switch direction {
        case .up, .left:
            return range.start
        case .down, .right:
            return range.end
        @unknown default:
            fatalError("\(#function): Direction `\(direction)` is unknown.")
        }
    }
    
    func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? {
        print("\(#function): byExtending position = \(position)")
        guard let position = position as? TextPosition else {
            fatalError("\(#function): The type of `position` isn't TextPosition.")
        }
        switch direction {
        case .up, .left:
            var newStart = TextPosition(position: position, offset: -1)
            let beginning = beginningOfDocument as! TextPosition
            newStart = newStart <  beginning ? beginning : newStart
            return TextRange(start: newStart, end: position)
        case .down, .right:
            var newEnd = TextPosition(position: position, offset: 1)
            let ending = endOfDocument as! TextPosition
            newEnd = newEnd > ending ? ending : newEnd
            return TextRange(start: position, end: newEnd)
        @unknown default:
            fatalError("\(#function): Direction `\(direction)` is unknown.")
        }
    }
    
    func baseWritingDirection(for position: UITextPosition, in direction: UITextStorageDirection) -> NSWritingDirection {
        return .leftToRight;
    }
    
    func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {
    }
    
    // MARK: Geometry Methods
    //
    func firstRect(for range: UITextRange) -> CGRect {
        print("\(#function): range = \(range)")
        guard let textRange = range as? TextRange else {
            fatalError("\(#function): The type of `range` isn't TextRange.")
        }
        guard let nsRange = textRange.nsRange(in: textStorage.string) else {
            print("! \(#function): TextRange.nsRange return nil for \(textRange).")
            return .zero
        }
        let glyphRange = layoutManager.glyphRange(forCharacterRange: nsRange, actualCharacterRange: nil)
        let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        return boundingRect
    }
    
    func caretRect(for position: UITextPosition) -> CGRect {
        print("\(#function): position = \(position)")
        guard let cursorPosition = position as? TextPosition else {
            fatalError("\(#function): The type of `position` isn't TextPosition.")
        }
        // If textRange.nsRange returns nil, then `position` is out of bound.
        // In that case, the caret position should be after the last character.
        //
        let textRange = TextRange(start: cursorPosition, end: cursorPosition)
        var charRange = textRange.nsRange(in: textStorage.string)
        if charRange == nil {
            if textStorage.string.isEmpty { // No text yet, return default cusor rectangle.
                return CGRect(x: 0, y: 0, width: 1, height: 20)
            }
            charRange = NSRange(location: textStorage.string.count - 1, length: 1)
        }
        let glyphRange = layoutManager.glyphRange(forCharacterRange: charRange!, actualCharacterRange: nil)
        var boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        if charRange == nil {
            print("! \(#function): TextRange.nsRange return nil for \(textRange).")
            let newX = boundingRect.origin.x + boundingRect.size.width
            boundingRect.origin = CGPoint(x: newX, y: boundingRect.origin.y)
        }
        boundingRect.size.width = 1
        print("\(#function): boundingRect = \(boundingRect)")
        return boundingRect
    }
    
    // MARK: Geometry Methods
    //
    func closestPosition(to point: CGPoint) -> UITextPosition? {
        var fraction = CGFloat()
        var charIndex = layoutManager.characterIndex(for: point, in: textContainer,
                                                     fractionOfDistanceBetweenInsertionPoints: &fraction)
        // Using NSString because String.count is different from NSString.length
        // in that Swift string uses Extended Grapheme Clusters.
        //
        // charIndex == textStorage length: Allow the cursor to be at the position
        // after the last character.
        //
        if fraction > 0.5 && charIndex < (textStorage.string as NSString).length {
            charIndex += 1
        }
        print("\(#function): point = \(point), charIndex = \(charIndex), fraction = \(fraction)")
        return TextPosition(value: charIndex)
    }
    
    func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
        print("\(#function): point = \(point), within range = \(range)")
        guard let textRange = range as? TextRange,
            let closestPosition = closestPosition(to: point) as? TextPosition else {
            return nil
        }
        
        if closestPosition < textRange.start {
            return textRange.start
        } else if closestPosition >= textRange.end {
            return textRange.end
        } else {
            return closestPosition
        }
    }
    
    func characterRange(at point: CGPoint) -> UITextRange? {
        print("\(#function): point = \(point)")
        guard let start = closestPosition(to: point) as? TextPosition else {
            return nil
        }
        var end = TextPosition(position: start, offset: 1)
        if let endOfDocument = endOfDocument as? TextPosition, endOfDocument < end {
            end = endOfDocument
        }
        return TextRange(start: start, end: end)
    }
    
    func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        print("\(#function): range = \(range)")
        guard let range = range as? TextRange, let nsRange = range.nsRange(in: textStorage.string) else {
            return []
        }
        var resultRects = [UITextSelectionRect]()
        let glyphRange = layoutManager.glyphRange(forCharacterRange: nsRange, actualCharacterRange: nil)
        layoutManager.enumerateEnclosingRects(forGlyphRange: glyphRange, withinSelectedGlyphRange: glyphRange,
                                              in: textContainer) { rect, _ in
            let selectionRect = TextSelectionRect(rect: rect)
            if selectionRect.rect.size.width == 0 {
                selectionRect.selectionRect.size = CGSize(width: 1, height: selectionRect.rect.size.height)
            }
            resultRects.append(selectionRect)
        }
        if resultRects.count > 0 {
            (resultRects[0] as! TextSelectionRect).rectContainsStart = true
            (resultRects[resultRects.count - 1] as! TextSelectionRect).rectContainsEnd = true
        }
        return resultRects
    }
}
