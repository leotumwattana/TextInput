//
//  TextInputView+TextLayoutManagerDelegate.swift
//  TextInput
//
//  Created by Leo Tumwattana on 5/5/2022.
//

import UIKit

extension TextInputView: NSTextLayoutManagerDelegate {
    
    func textLayoutManager(
        _ textLayoutManager: NSTextLayoutManager,
        textLayoutFragmentFor location: NSTextLocation,
        in textElement: NSTextElement
    ) -> NSTextLayoutFragment {
        NSTextLayoutFragment(
            textElement: textElement,
            range: textElement.elementRange
        )
    }
}
