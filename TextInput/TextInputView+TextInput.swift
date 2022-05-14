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
        guard let textStorage = textContentStorage.textStorage,
            let textRange = range as? TextRange,
            let indexRange = textRange.range(in: textStorage.string) else {
            return nil
        }
        let string = String(textStorage.string[indexRange])
        print("\(#function): range = \(range), string = \(string)")
        return string
    }
    
    func replace(_ range: UITextRange, withText text: String) {
        print("\(#function): range = \(range), with text = \(text)")
        guard let textStorage = textContentStorage.textStorage,
              let textRange = range as? TextRange,
              let nsRange = textRange.nsRange(in: textStorage.string) else {
            fatalError("\(#function): Failed to convert \(range) to a valid NSRange.")
        }

        // Replace the characters in text storage and update the selectedTextRange.
        // Notify inputDelegate before and after doing the change.
        // Note that TextRange is a half-open range without including the upper bound.
        //
        inputDelegate?.textWillChange(self)
        textContentStorage.performEditingTransaction {
            textStorage.replaceCharacters(in: nsRange, with: text)
        }
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

        if let textStorage = textContentStorage.textStorage,
           let rangeToReplace = rangeToReplace as? TextRange,
           let nsRange = rangeToReplace.nsRange(in: textStorage.string)
        {
            textContentStorage.performEditingTransaction {
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
        if let textStorage = textContentStorage.textStorage,
           let nsRange = markedTextRange.nsRange(in: textStorage.string)
        {
            inputDelegate?.textWillChange(self)
            textContentStorage.performEditingTransaction {
                markedTextStyle?.keys.forEach { key in
                    textStorage.removeAttribute(key, range: nsRange)
                }
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
        return TextPosition(value: textContentStorage.textStorage?.string.count ?? 0)
    }
    
    func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        print("\(#function): from = \(fromPosition), to = \(toPosition)")
        guard let start = fromPosition as? TextPosition,
              let end = toPosition as? TextPosition
        else { return nil }
        
        return start <= end ? TextRange(start: start, end: end) : TextRange(start: end, end: start)
    }
    
    func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        print("\(#function): from = \(position), offset = \(offset)")
        guard let textStorage = textContentStorage.textStorage
        else { fatalError() }
        
        guard let position = position as? TextPosition
        else { return nil }
        
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
        print("\(#function): from = \(position), in = \(direction), offset = \(offset)")
        guard let position = position as? TextPosition
        else { return nil }
        
        switch direction { // This sample only supports left-to-right text direction.
        case .right:
            let newPosition = TextPosition(position: position, offset: offset)
            return newPosition > endOfDocument as! TextPosition ? endOfDocument : newPosition
        case .left:
            let newPosition = TextPosition(position: position, offset: -offset)
            return newPosition < beginningOfDocument as! TextPosition ? beginningOfDocument : newPosition
        case .down, .up:
            var navigationDirection: NSTextSelectionNavigation.Direction
            if direction == .down {
                navigationDirection = offset >= 0 ? .down : .up
            } else {
                navigationDirection = offset >= 0 ? .up : .down
            }
            
            let nav = textLayoutManager.textSelectionNavigation
            
            let textLocation = textContentStorage.location(textContentStorage.documentRange.location, offsetBy: position.value)!
            var textSelection = NSTextSelection(textLocation, affinity: .upstream)
            
            (0..<abs(offset)).forEach { _ in
                if let newLocation = nav.destinationSelection(
                    for: textSelection,
                    direction: navigationDirection,
                    destination: .character,
                    extending: false,
                    confined: false
                )?.textRanges.first?.location {
                    textSelection = NSTextSelection(newLocation, affinity: .upstream)
                }
            }
            
            guard let destinationLocation = textSelection.textRanges.first?.location else { return nil }
            let index = textContentStorage.offset(from: textContentStorage.documentRange.location, to: destinationLocation)
            let newPosition = TextPosition(value: index)
            
            if newPosition < beginningOfDocument as! TextPosition {
                return beginningOfDocument as! TextPosition
            } else if newPosition > endOfDocument as! TextPosition {
                return endOfDocument as! TextPosition
            } else {
                return newPosition
            }
            
        @unknown default:
            fatalError()
        }
    }
    
    // MARK: Evaluating Text Positions
    //
    func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        print("\(#function): position = \(position), to = \(other)")
        guard let position = position as? TextPosition, let other = other as? TextPosition else {
            /*
             Note: Seems this gets triggered when the caret is at the end of the
             document and we use the arrow up or down key to try to move the caret.
             The property other will come bask as <uninitialized>.
             */
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
        
        guard let textStorage = textContentStorage.textStorage
        else { fatalError() }
        
        guard let textRange = range as? TextRange else {
            fatalError("\(#function): The type of `range` isn't TextRange.")
        }
        
        guard let nsRange = textRange.nsRange(in: textStorage.string)
        else{ return .zero }
        
        guard let nsTextRange = NSTextRange(nsRange, in: textContentStorage)
        else { return .zero }
        
        var rect = CGRect.zero
        textLayoutManager.enumerateTextSegments(
            in: nsTextRange,
            type: .selection
        ) { _, textSegmentFrame, baselinePosition, textContainer in
            rect = convert(textSegmentFrame, to: nil)
            return false
        }
        
        return rect
    }
    
    var documentRange: NSTextRange {
        textContentStorage.documentRange
    }
    
    func caretRect(for position: UITextPosition) -> CGRect {
        print("\(#function): position = \(position)")
        
        let caretWidth: CGFloat = 2
        
        let loc = offset(from: beginningOfDocument, to: position)
        
        var selectionFrame = CGRect(x: 0, y: 0, width: 3, height: 30)
        
        let nsRange = NSRange(location: loc, length: 0)
        
        guard let nsTextRange = NSTextRange(nsRange, in: textContentStorage)
        else { return .zero }
        
        textLayoutManager.enumerateTextSegments(
            in: nsTextRange,
            type: .selection
        ) { segmentRange, textSegmentFrame, baselinePosition, textContainer in
                
            selectionFrame = textSegmentFrame
            if segmentRange == documentRange {
                let font = UIFont.preferredFont(forTextStyle: .body)
                let lineHeightMultiple = max(NSParagraphStyle.default.lineHeightMultiple, 1)
                let lineHeight = font.lineHeight * lineHeightMultiple
                selectionFrame = CGRect(
                    origin: selectionFrame.origin,
                    size: CGSize(
                        width: caretWidth,
                        height: lineHeight
                    )
                )
            }
            
            return false
        }
        
        return CGRect(
            x: selectionFrame.minX,
            y: selectionFrame.minY,
            width: caretWidth,
            height: selectionFrame.height
        )
    }
    
    // MARK: Geometry Methods
    //
    func closestPosition(to point: CGPoint) -> UITextPosition? {
        guard let textStorage = textContentStorage.textStorage else { return nil }
        
        let nav = textLayoutManager.textSelectionNavigation
        
        guard let textLayoutFragment = textLayoutManager.textLayoutFragment(for: point)
        else { return nil }

        let selections = nav.textSelections(
            interactingAt: point,
            inContainerAt: textLayoutFragment.rangeInElement.location,
            anchors: [],
            modifiers: .visual,
            selecting: true,
            bounds: .zero
        )
        
        guard let selection = selections.first,
              let location = selection.textRanges.first?.location
        else { return nil }
        
        let beginningLocation = textLayoutManager.documentRange.location
        
        var index = textContentStorage.offset(
            from: beginningLocation,
            to: location
        )
        
        let minIndex = textContentStorage.offset(
            from: beginningLocation,
            to: textLayoutFragment.rangeInElement.location
        )
        
        let maxIndex = textContentStorage.offset(
            from: beginningLocation,
            to: textLayoutFragment.rangeInElement.endLocation
        )
        
        if index > maxIndex || index < minIndex {
            return nil
        }
        
        
        /*
         Ugly workaround:
         Seems like when we tap behind a paragraph, the newline character is
         taken into account and hence we return a position after the newline
         character, which then moves our caret to the beginning of the next
         paragraph. However, this is not the case when dragging the caret
         around, nor when we use the software keyboard's space bar to move the
         caret.
         
         So, here we're checking to see if we have to adjust for the newline
         character when we are tapping to adjust for it.
         
         In order to see if we are tapping as oppose to dragging the caret,
         we check to see if `UITextMultiTapRecognizer` is active.
         
         TODO: Check with DTS to see if there is a better solution to this.
         */
            
        let isTextMultiTapActive = !(gestureRecognizers ?? [])
            .filter { $0.state == .began }
            .filter {
                NSStringFromClass(type(of: $0)).nsString.hasPrefix("UITextMultiTapRecognizer")
            }
            .isEmpty
        
        if isTextMultiTapActive && index < textStorage.length {
            // Find the character at index
            let charRange = NSRange(location: index, length: 1)
            let char = textStorage.string.nsString.substring(with: charRange)
            
            // If character is a newline, then offset the index by -1 to ignore
            // the newline character
            if char == "\n" {
                index -= 1
            }
        }
        
        return TextPosition(value: index)
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
        
        guard let textStorage = textContentStorage.textStorage
        else { fatalError() }
        
        guard let range = range as? TextRange else { fatalError() }
        
        guard let nsRange = range.nsRange(in: textStorage.string)
        else { return [] }
        
        guard let textRange = NSTextRange(nsRange, in: textContentStorage)
        else { return [] }
        
        var rects = [TextSelectionRect]()
        
        textLayoutManager.enumerateTextSegments(
            in: textRange,
            type: .selection
        ) { textRange, textSegmentFrame, baselineOffset, textContainer in
            let rect = textSegmentFrame
            let selectionRect = TextSelectionRect(rect: rect)
            rects.append(selectionRect)
            return true
        }
        
        rects.first?.rectContainsStart = true
        rects.last?.rectContainsEnd = true
        
        return rects
    }
}

// =======================
// MARK: - Floating Cursor
// =======================

extension TextInputView {
    func beginFloatingCursor(at point: CGPoint) {
        guard let position = closestPosition(to: point) else { return }
        let caretRect = caretRect(for: position)
        floatingCursorView.frame = caretRect
        
        floatingCursorView.layer.shadowOffset = CGSize(width: 0, height: caretRect.height / 2)
        addSubview(floatingCursorView)
        
        _caretRectForFloatingCursor = caretRect
        
        let anim = UIViewPropertyAnimator(duration: 0.2, dampingRatio: 1) {
            self.floatingCursorView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }
        anim.addCompletion { _ in
            UIViewPropertyAnimator(duration: 0.2, dampingRatio: 1) {
                self.floatingCursorView.transform = .identity
            }.startAnimation()
        }
        anim.startAnimation()
    }
    
    func updateFloatingCursor(at point: CGPoint) {
        let frame = floatingCursorView.frame
        let origin = CGPoint(
            x: point.x - frame.width / 2,
            y: point.y - frame.height / 2
        )
        floatingCursorView.frame.origin = origin
        
        if let position = closestPosition(to: point) {
            let caretRect = caretRect(for: position)
            _caretRectForFloatingCursor = caretRect
        }
    }
    
    func endFloatingCursor() {
        if let caretRect = _caretRectForFloatingCursor {
            let anim = UIViewPropertyAnimator(duration: 0.2, dampingRatio: 1) {
                self.floatingCursorView.frame = caretRect
            }
            anim.addCompletion { _ in
                self.floatingCursorView.removeFromSuperview()
                self.floatingCursorView.transform = .identity
            }
            anim.startAnimation()
            
        } else {
            floatingCursorView.removeFromSuperview()
            floatingCursorView.transform = .identity
        }
        _caretRectForFloatingCursor = nil
    }
}
