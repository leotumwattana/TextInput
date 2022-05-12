//
//  TextInputView+EditingActions.swift
//  TextInput
//
//  Created by Leo Tumwattana on 12/5/2022.
//

import UIKit

extension TextInputView {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        print("*** \(#function): action: \(action)")
        
        let hasNonEmptySelectedTextRange = !(selectedTextRange?.isEmpty ?? true)
        
        switch action {
        case #selector(cut(_:)):
            return hasNonEmptySelectedTextRange
        case #selector(copy(_:)):
            return hasNonEmptySelectedTextRange
        case #selector(paste(_:)):
            if let string = UIPasteboard.general.string,
               !string.isEmpty
            {
                return true
            }
            return false
        case #selector(delete(_:)):
            return hasNonEmptySelectedTextRange
        case #selector(select(_:)):
            return true
        case #selector(selectAll(_:)):
            return selectedTextRange != nil
        default:
            return super.canPerformAction(action, withSender: sender)
        }
    }
    
    override func cut(_ sender: Any?) {
        print("*** \(#function): should cut")
        if let selectedTextRange = selectedTextRange,
           !selectedTextRange.isEmpty
        {
            let text = text(in: selectedTextRange)
            UIPasteboard.general.string = text
            replace(selectedTextRange, withText: "")
        }
    }
    
    override func copy(_ sender: Any?) {
        print("*** \(#function): should copy")
        if let selectedTextRange = selectedTextRange,
           !selectedTextRange.isEmpty
        {
            let text = text(in: selectedTextRange)
            UIPasteboard.general.string = text
        }
    }
    
    override func paste(_ sender: Any?) {
        print("*** \(#function): should paste")
        let pasteboard = UIPasteboard.general
        if let string = pasteboard.string {
            insertText(string)
        }
    }
    
    override func delete(_ sender: Any?) {
        print("*** \(#function): should delete")
        if let selectedTextRange = selectedTextRange,
           !selectedTextRange.isEmpty
        {
            replace(selectedTextRange, withText: "")
        }
    }
    
    override func select(_ sender: Any?) {
        print("*** \(#function): should select")
        // TODO
    }
    
    override func selectAll(_ sender: Any?) {
        selectedTextRange = textRange(from: beginningOfDocument, to: endOfDocument)
    }
    
}
