//
//  TextInputView+TextInteractionDelegate.swift
//  TextInput
//
//  Created by Leo Tumwattana on 16/5/2022.
//

import UIKit

extension TextInputView: UITextInteractionDelegate {
    func interactionShouldBegin(_ interaction: UITextInteraction, at point: CGPoint) -> Bool {
        return true
    }
    
    func interactionWillBegin(_ interaction: UITextInteraction) {
        print("*** \(#function): \(interaction)")
    }
    
    func interactionDidEnd(_ interaction: UITextInteraction) {
        print("*** \(#function): \(interaction)")
    }
}
